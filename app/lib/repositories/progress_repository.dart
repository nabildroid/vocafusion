import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast_io.dart' hide FieldValue;
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';
import 'package:vocafusion/repositories/user_repository.dart';

class ProgressRepository extends AuthorizedDio {
  final Database _db = locator.get();
  final _spacedRepetition = stringMapStoreFactory.store("spacedRepetitionFSRS");

  final isOnline = BehaviorSubject<bool>.seeded(false);

  // SR sync debouncer
  Timer? _srSyncDebouncer;
  final _pendingSRUpdates = <String, dynamic>{};
  final _syncInProgress = BehaviorSubject<bool>.seeded(false);

  ProgressRepository() : super(rawHttp: AuthorizedDio.defaultHttp) {
    Connectivity().onConnectivityChanged.listen(
          (status) => isOnline.add(!status.contains(ConnectivityResult.none)),
        );
  }
}

typedef SR = MapEntry<String, dynamic>;

extension SpacedRepetitionProgressRepository on ProgressRepository {
  Future<void> updateOnline(SR spacedRepeition) async {
    if (!isOnline.value) return;

    // Add to pending updates
    _pendingSRUpdates[spacedRepeition.key] = spacedRepeition.value;

    // Cancel existing timer if any
    _srSyncDebouncer?.cancel();
    // schedule a sync after 3 minutes
    _srSyncDebouncer = Timer(Duration(minutes: 2), _syncSRCardsNow);
  }

  Future<void> _syncSRCardsNow() async {
    if (_pendingSRUpdates.isEmpty || _syncInProgress.value) return;

    _syncInProgress.add(true);
    try {
      // Upload pending updates to server
      await (await http).post("/progress/sr", data: {
        "cards": _pendingSRUpdates,
      });

      // Clear pending updates after successful upload
      _pendingSRUpdates.clear();
    } catch (e) {
      print("Failed to sync SR cards: $e");
      // Will try again later
    } finally {
      _syncInProgress.add(false);
    }
  }

  Future<void> updateOffline(SR spacedRepeition) async {
    await _spacedRepetition
        .record(spacedRepeition.key)
        .put(_db, spacedRepeition.value);
  }

  Future<void> updateSR(SR spacedRepeition) async {
    await updateOffline(spacedRepeition);

    if (isOnline.value) {
      await updateOnline(spacedRepeition);
    }
  }

  Future<List<SR>> sync(
      {required List<SR> onlineData, DateTime? lastSynced}) async {
    final offline = await offlineData();
    final tobeUploaded = <SR>[];
    final tobeDownloaded = <SR>[];

    // Compare online and offline data
    for (var e in onlineData) {
      final offlineRecord = offline.firstWhere(
          (element) => element.key == e.key,
          orElse: () => MapEntry("", null));

      if (offlineRecord.value == null) {
        // Card exists online but not offline
        tobeDownloaded.add(e);
      } else {
        // Compare lastReview timestamps
        final onlineLastReview =
            DateTime.parse(e.value["lastReview"] ?? "1970-01-01");
        final offlineLastReview =
            DateTime.parse(offlineRecord.value["lastReview"] ?? "1970-01-01");

        if (onlineLastReview.isAfter(offlineLastReview)) {
          tobeDownloaded.add(e);
        } else if (offlineLastReview.isAfter(onlineLastReview)) {
          tobeUploaded.add(offlineRecord);
        }
      }
    }

    // Check for cards that exist offline but not online
    for (var offlineCard in offline) {
      if (!onlineData.any((onlineCard) => onlineCard.key == offlineCard.key)) {
        tobeUploaded.add(offlineCard);
      }
    }

    // Apply downloads to offline storage
    for (var card in tobeDownloaded) {
      await updateOffline(card);
    }

    // Schedule uploads for changed offline data
    if (tobeUploaded.isNotEmpty) {
      for (var card in tobeUploaded) {
        if (lastSynced != null) {
          if (DateTime.parse(card.value["lastReview"]).isBefore(lastSynced)) {
            continue;
          }
        }
        _pendingSRUpdates[card.key] = card.value;
      }

      _syncSRCardsNow();
      _srSyncDebouncer?.cancel();
      _srSyncDebouncer = Timer(Duration(minutes: 2), _syncSRCardsNow);
    }

    // Return merged data, preferring newer versions
    final mergedData = <SR>[];

    // Include all online cards (possibly overridden by newer offline versions)
    for (var onlineCard in onlineData) {
      final newerOfflineVersion = tobeUploaded.firstWhere(
          (offlineCard) => offlineCard.key == onlineCard.key,
          orElse: () => onlineCard);
      mergedData.add(newerOfflineVersion);
    }

    // Add offline-only cards
    for (var offlineCard in offline) {
      if (!mergedData.any((card) => card.key == offlineCard.key)) {
        mergedData.add(offlineCard);
      }
    }

    return mergedData;
  }

  Future<List<SR>> offlineData() async {
    final records = await _spacedRepetition.find(_db);
    return records.map<SR>((e) => MapEntry(e.key, e.value)).toList();
  }

  Future<List<SR>> onlineData() async {
    try {
      final timestamp = DateTime(2010).millisecondsSinceEpoch;

      final response =
          await (await http).get("/progress/sr?lastUpdated=$timestamp");

      final cards = (response.data["cards"] ?? {}) as Map<String, dynamic>;
      final srList =
          cards.entries.map((e) => MapEntry(e.key, e.value)).toList();

      return await sync(onlineData: srList, lastSynced: null);
    } catch (e) {
      print("Error fetching online SR data: $e");
      return [];
    }
  }

  BehaviorSubject<List<SR>> spacedRepetition() {
    final stream = BehaviorSubject<List<SR>>.seeded([]);
    final offline = offlineData();
    offline.then(stream.add);

    if (isOnline.value) {
      onlineData().then(stream.add);
    } else {
      isOnline.firstWhere((e) => e).then((_) {
        onlineData().then(stream.add);
      });
    }

    return stream;
  }

  // Force immediate sync (e.g., when app is closing or session ends)
  Future<void> forceSRSync() async {
    if (_pendingSRUpdates.isNotEmpty) {
      _srSyncDebouncer?.cancel();
      await _syncSRCardsNow();
    }
  }
}
