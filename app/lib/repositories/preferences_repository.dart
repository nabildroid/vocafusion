import 'dart:async';
import 'dart:ffi';

import 'package:vocafusion/models/core/access_token_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [PreferenceRepository] is for storing user preferences.
class PreferenceRepository {
  PreferenceRepository({
    Future<SharedPreferences>? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  Future<bool?> firstTime({bool? val}) async {
    if (val == null) {
      return (await getBool("isFirstTime")) ?? true;
    } else {
      setBool('isFirstTime', val);
      return null;
    }
  }

  Future<AccessTokenModel?> getAccessToken() async {
    final data = await getString("accessToken");
    if (data == null) return null;

    return AccessTokenModel.fromJson(data);
  }

  Future<void> setAccessToken(AccessTokenModel accessToken) async {
    await setString(
      "accessToken",
      accessToken.toJson(),
    );
  }

  Future<bool?> isRoadmapGoalsNeedUpload({bool? val}) async {
    if (val == null) {
      return (await getBool("isRoadmapGoalsNeedUpload")) ?? false;
    } else {
      setBool('isRoadmapGoalsNeedUpload', val);
      return null;
    }
  }

  Future<DateTime> lastFetchedGoals() async {
    final data = await getInt("lastFetchedGoals");
    unawaited(
        setInt("lastFetchedGoals", DateTime.now().millisecondsSinceEpoch));

    if (data == null) {
      return DateTime.parse("2024-02-01");
    } else {
      return DateTime.fromMillisecondsSinceEpoch(data);
    }
  }

  Future<DateTime> lastFetchedRecords() async {
    final data = await getInt("lastFetchedrecords");
    unawaited(
        setInt("lastFetchedrecords", DateTime.now().millisecondsSinceEpoch));

    if (data == null) {
      return DateTime.parse("2024-02-01");
    } else {
      return DateTime.fromMillisecondsSinceEpoch(data);
    }
  }

  Future<DateTime?> lastFetchedSR() async {
    final data = await getInt("lastFetchedSR");
    unawaited(setInt("lastFetchedSR", DateTime.now().millisecondsSinceEpoch));

    if (data == null) {
      return null;
    } else {
      return DateTime.fromMillisecondsSinceEpoch(data);
    }
  }

  @override
  String get logIdentifier => '[PreferenceRepository]';
}

extension on PreferenceRepository {
  static const globalPrefix = "18";

  Future<bool?> getBool(String key) async {
    final prefs = await _prefs;
    return prefs.getBool("$globalPrefix$key");
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _prefs;
    return prefs.getDouble("$globalPrefix$key");
  }

  Future<int?> getInt(String key) async {
    final prefs = await _prefs;
    return prefs.getInt("$globalPrefix$key");
  }

  Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString("$globalPrefix$key");
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList("$globalPrefix$key");
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    prefs.setBool("$globalPrefix$key", value);
  }

  Future<void> setDouble(String key, double value) async {
    final prefs = await _prefs;
    prefs.setDouble("$globalPrefix$key", value);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _prefs;
    prefs.setInt("$globalPrefix$key", value);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    prefs.setString("$globalPrefix$key", value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _prefs;
    prefs.setStringList("$globalPrefix$key", value);
  }

  Future<void> remove(String key) async {
    final prefs = await _prefs;
    prefs.remove("$globalPrefix$key");
  }
}
