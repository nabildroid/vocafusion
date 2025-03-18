import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/models/core/access_token_model.dart';
import 'package:vocafusion/models/users.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';
import 'package:vocafusion/services/firebase_service.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:rxdart/rxdart.dart';

// ignore: constant_identifier_names
const _BaseURL = "https://montahadi-auth.pni20156789.workers.dev";
// ignore: constant_identifier_names
const _SMSBaseURL = "https://api.montahadi.laknabil.me";
// ignore: constant_identifier_names
const _AUTH_HEADER = "x-auth";
// ignore: constant_identifier_names
const _TOKEN_REFRESH_BUFFER_SECONDS = 60; // 1 minute before expiration
// ignore: constant_identifier_names
const _TOKEN_CHECK_INTERVAL_SECONDS = 30; // Check every 30 seconds

class UserRepository {
  final PreferenceRepository _prefs = locator.get();
  final Dio http = Dio(BaseOptions(baseUrl: _BaseURL));

  final tokenSteam = BehaviorSubject<String?>()..add(null);
  final currentUser = BehaviorSubject<User?>();

  Timer? _tokenRefreshTimer;

  UserRepository() {
    // Initialize token refresh mechanism
    _setupTokenRefreshTimer();
  }

  void _setupTokenRefreshTimer() {
    // Cancel any existing timer
    _tokenRefreshTimer?.cancel();

    // Set up a periodic timer to check token expiration
    _tokenRefreshTimer = Timer.periodic(
        Duration(seconds: _TOKEN_CHECK_INTERVAL_SECONDS),
        (_) => _checkTokenExpiration());
  }

  Future<void> _checkTokenExpiration() async {
    final accessToken = await _prefs.getAccessToken();
    if (accessToken == null) return;

    if (_shouldRefreshToken(accessToken)) {
      print("Token will expire soon, refreshing...");
      try {
        final freshAccessToken = await _refreshToken(accessToken);
        _saveAccessToken(freshAccessToken);
        currentUser.value = User.fromAccessToken(freshAccessToken);
      } catch (e) {
        print("Error refreshing token: $e");
      }
    }
  }

  bool _shouldRefreshToken(AccessTokenModel accessToken) {
    final now = DateTime.now();
    final expiresIn = accessToken.expires.difference(now).inSeconds;
    return expiresIn <= _TOKEN_REFRESH_BUFFER_SECONDS;
  }

  Future<User?> getUser({bool live = false}) async {
    final accessToken = await _prefs.getAccessToken();
    if (accessToken == null) return null;

    if (accessToken.isExpired || _shouldRefreshToken(accessToken) || live) {
      print("going to refresh the access token");

      final promise = _refreshToken(accessToken).then((freshAccessToken) {
        _saveAccessToken(freshAccessToken);
        currentUser.value = User.fromAccessToken(freshAccessToken);
        return currentUser.value;
      });

      if (live) return promise;
      unawaited(promise);
    } else {
      _saveAccessToken(accessToken);
    }

    currentUser.value = User.fromAccessToken(accessToken);
    return currentUser.value;
  }

  Future<AccessTokenModel> _refreshToken(AccessTokenModel accessToken) async {
    final response = await http.post(
      "/refresh",
      data: {"token": accessToken.refreshToken},
    );

    return accessToken.refresh(response.data["newToken"]);
  }

  void _saveAccessToken(AccessTokenModel accessToken) {
    http.interceptors.clear();
    http.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers[_AUTH_HEADER] = accessToken.token;
        handler.next(options);
      },
    ));
    _prefs.setAccessToken(accessToken);

    tokenSteam.add(accessToken.token);
  }

  void subscribeToToken(AuthorizedDio customDio) {
    tokenSteam.listen((token) {
      if (token == null) return;

      customDio.rawHttp.interceptors.clear();
      customDio.rawHttp.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers[_AUTH_HEADER] = tokenSteam.value;
          handler.next(options);
        },
      ));

      if (customDio.completerhttp.isCompleted) return;
      customDio.completerhttp.complete(customDio.rawHttp);
    });
  }

  void dispose() {
    _tokenRefreshTimer?.cancel();
    tokenSteam.close();
    currentUser.close();
  }

  @override
  String get logIdentifier => "[Auth Repository]";
}

extension PhoneUserRepository on UserRepository {
  Future<User?> login({
    required String phone,
    required String otp,
    required String token,
  }) async {
    final reponse = await http.post("/login", data: {
      "phone": phone,
      "otp": int.parse(otp),
      "token": token,
    });

    final accessToken = AccessTokenModel(
      expires:
          DateTime.fromMillisecondsSinceEpoch(reponse.data["expires"] * 1000),
      refreshToken: reponse.data["refreshToken"],
      token: reponse.data["token"],
    );

    _saveAccessToken(accessToken);

    currentUser.value = User.fromAccessToken(accessToken);

    await Posthog().identify(userId: currentUser.value!.uid, userProperties: {
      "phone": currentUser.value!.phone,
      "phoneVerified": true,
    });

    await Posthog().reloadFeatureFlags();

    return currentUser.value;
  }

  Future<AccessTokenModel> register({
    required String phone,
    required String otp,
    required String token,
    required bool isParent,
    required String grade,
  }) async {
    final reponse = await http.post("/create", data: {
      "phone": phone,
      "otp": int.parse(otp),
      "token": token,
      "userType": isParent ? "parent" : "child",
      "grade": grade,
    });

    final accessToken = AccessTokenModel(
      expires:
          DateTime.fromMillisecondsSinceEpoch(reponse.data["expires"] * 1000),
      refreshToken: reponse.data["refreshToken"],
      token: reponse.data["token"],
    );

    _saveAccessToken(accessToken);
    currentUser.value = User.fromAccessToken(accessToken);

    await Posthog().identify(userId: currentUser.value!.uid, userProperties: {
      "phone": currentUser.value!.phone,
      "phoneVerified": currentUser.value!.phoneVerified,
    });

    await Posthog().reloadFeatureFlags();

    return accessToken;
  }

  Future<String> sendOTP(
    String phone, {
    String? reason,
  }) async {
    final extra = await FirebaseService.appCheckToken.timeout(
        const Duration(seconds: 5),
        onTimeout: () => "zzzzzzzzzzzzzzzzzzzzzzz");

    final response = await http.post(_SMSBaseURL,
        data: {
          "phone": phone,
          "reason": reason,
        },
        options: Options(headers: {
          "gtm": extra,
        }));

    final token = response.data?["token"];
    if (token == null) {
      throw Exception("Failed to send OTP");
    }

    return token as String;
  }
}
