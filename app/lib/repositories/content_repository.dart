import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sembast/sembast_io.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/models/modeling.dart';

class ContentRepository extends AuthorizedDio {
  final Database _db = locator.get();
  final _flowStore = stringMapStoreFactory.store("flows");
  final _wordsStore = stringMapStoreFactory.store("words");
  final _quizzesStore = stringMapStoreFactory.store("quizzes");

  final isOnline = BehaviorSubject<bool>.seeded(false);

  final flowsStream = BehaviorSubject<List<WordsFlow>>();
  final wordsStream = BehaviorSubject<List<WordCard>>();
  final quizzesStream = BehaviorSubject<List<Quiz>>();

  ContentRepository() : super(rawHttp: AuthorizedDio.defaultHttp) {
    Connectivity().onConnectivityChanged.listen(
          (status) => isOnline.add(!status.contains(ConnectivityResult.none)),
        );
  }
}

extension QuizzesContentRepository on ContentRepository {
  Future<void> sync({required List<Quiz> onlineData}) async {
    if (onlineData.isEmpty) return;

    final outdated = await _quizzesStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals("flowId", onlineData.first.flowId),
      ),
    );

    await _db.transaction((txn) async {
      for (final quiz in outdated) {
        await _quizzesStore.record(quiz.key).delete(txn);
      }

      for (final quiz in onlineData) {
        await _quizzesStore
            .record(quiz.id)
            .put(txn, quiz.toJson(), merge: true);
      }
    });
  }

  Future<List<Quiz>> offlineData(String flow) async {
    final records = await _quizzesStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals("flowId", flow),
      ),
    );

    return records.map((e) => Quiz.fromJson(e.value)).toList();
  }

  Future<List<Quiz>> onlineData(String flow) async {
    // final response = await (await http).get("material/quizzes/$flow");

    // final data = (response.data as List).map((e) => Quiz.fromJson(e)).toList();
    final data = DummyQuizzes;
    unawaited(sync(onlineData: data));

    return data;
  }

  BehaviorSubject<List<Quiz>> quizzes(String flow) {
    final offline = offlineData(flow);
    bool isOnlineDelivered = false;
    offline.then((val) {
      if (!isOnlineDelivered) quizzesStream.add(val);
    });

    if (isOnline.value) {
      onlineData(flow).then(quizzesStream.add).then((_) {
        isOnlineDelivered = true;
      });
    } else {
      isOnline.firstWhere((e) => e).then((_) {
        onlineData(flow).then(quizzesStream.add);
      });
    }

    return quizzesStream;
  }
}

extension WordsContentRepository on ContentRepository {
  Future<void> sync({required List<WordCard> onlineData}) async {
    if (onlineData.isEmpty) return;

    final outdated = await _wordsStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals("flowId", onlineData.first.flowId),
      ),
    );

    await _db.transaction((txn) async {
      for (final word in outdated) {
        await _wordsStore.record(word.key).delete(txn);
      }

      for (final word in onlineData) {
        await _wordsStore.record(word.id).put(txn, word.toJson());
      }
    });
  }

  Future<List<WordCard>> offlineData(String flow) async {
    final records = await _wordsStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals("flowId", flow),
      ),
    );

    return records.map((e) => WordCard.fromJson(e.value)).toList();
  }

  Future<List<WordCard>> onlineData(String flow) async {
    // final response = await (await http).get("material/WordCardzes/$flow");

    // final data = (response.data as List).map((e) => WordCard.fromJson(e)).toList();
    final data = DummyCards;
    unawaited(sync(onlineData: data));

    return data;
  }

  BehaviorSubject<List<WordCard>> words(String flow) {
    final offline = offlineData(flow);
    bool isOnlineDelivered = false;
    offline.then((val) {
      if (!isOnlineDelivered) wordsStream.add(val);
    });

    if (isOnline.value) {
      onlineData(flow).then(wordsStream.add).then((_) {
        isOnlineDelivered = true;
      });
    } else {
      isOnline.firstWhere((e) => e).then((_) {
        onlineData(flow).then(wordsStream.add);
      });
    }

    return wordsStream;
  }
}

extension FlowContentRepository on ContentRepository {
  Future<void> sync({required List<WordsFlow> onlineData}) async {
    if (onlineData.isEmpty) return;
    await _db.transaction((txn) async {
      for (final flow in onlineData) {
        await _flowStore.record(flow.id).put(txn, flow.toJson());
      }
    });
  }

  Future<List<WordsFlow>> offlineData() async {
    final records = await _flowStore.find(_db);
    return records.map((e) => WordsFlow.fromJson(e.value)).toList();
  }

  Future<List<WordsFlow>> onlineData(FlowFilter filter) async {
    // final response = await (await http).get("grouping/timetables");

    // final data =
    //     (response.data as List).map((e) => WordsFlow.fromJson(e)).toList();
    final data = DummyFlows;
    unawaited(sync(onlineData: data));

    return data;
  }

  BehaviorSubject<List<WordsFlow>> flows(FlowFilter filter) {
    final offline = offlineData();
    bool isOnlineDelivered = false;
    offline.then((val) {
      if (!isOnlineDelivered) flowsStream.add(val);
    });

    try {
      if (isOnline.value) {
        onlineData(filter).then(flowsStream.add).then((_) {
          isOnlineDelivered = true;
        });
      } else {
        isOnline.firstWhere((e) => e).then((_) {
          onlineData(filter).then(flowsStream.add);
        });
      }
    } catch (e) {}

    return flowsStream;
  }
}

class FlowFilter {
  final String targetLanguage;
  final String nativeLanguage;

  FlowFilter({
    required this.targetLanguage,
    required this.nativeLanguage,
  });
}
