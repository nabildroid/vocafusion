import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/models/core/access_token_model.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';
import 'package:vocafusion/services/firebase_service.dart';
import 'package:rxdart/rxdart.dart';

class UserRepository {
  final PreferenceRepository _prefs = locator.get();

  Future<User?> getUser({bool live = false}) async {
    final user = await _prefs.getUser();
    if (user.isEmpty) {
      return null;
    }
    return User.fromJson(jsonDecode(user));
  }

  @override
  String get logIdentifier => "[Auth Repository]";
}
