import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/extensions/authorizedDio.dart';
import 'package:vocafusion/models/core/access_token_model.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';

// ignore: constant_identifier_names
const _BaseURL = kReleaseMode
    ? "https://vocafusion-auth.pni20156789.workers.dev"
    : "http://192.168.0.105:8787";
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
  Future<User?> loginWithGoogle({
    String? nativeLanguage,
  }) async {
    final _googleSignIn = GoogleSignIn(scopes: []);
    try {
      final authUser = await _googleSignIn.signIn();
      final googleAccessToken = (await authUser?.authentication)?.accessToken;

      final response = await http.post("/loginWithGoogle", data: {
        "accessToken": googleAccessToken,
        nativeLanguage: nativeLanguage,
      });

      final accessToken = AccessTokenModel(
        expires: DateTime.fromMillisecondsSinceEpoch(
            response.data["expires"] * 1000),
        refreshToken: response.data["refreshToken"],
        token: response.data["token"],
      );

      _saveAccessToken(accessToken);
      currentUser.value = User.fromAccessToken(accessToken);

      return currentUser.value;
    } catch (error) {
      print(error);
    }
  }
}
