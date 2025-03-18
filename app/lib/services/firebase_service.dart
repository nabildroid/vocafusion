import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:vocafusion/firebase_options.dart';
import 'package:rxdart/rxdart.dart';

abstract class FirebaseService {
  static final _appCheckToken = BehaviorSubject.seeded("");
  static Future<String> get appCheckToken =>
      _appCheckToken.stream.firstWhere((token) => token.isNotEmpty);

  static Future<void> init() async {
    if (!Platform.isAndroid) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    unawaited(FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider:
          kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    ));

    FirebaseAppCheck.instance.onTokenChange.listen((data) {
      _appCheckToken.add(data ?? "");
    });
  }
}

// TODO remove this hack and everywhere it's used, do the work, for real!
DateTime quickHackDate(dynamic date) {
  if (date is int) {
    return DateTime.fromMillisecondsSinceEpoch(date);
  }

  if (date is Timestamp) {
    return date.toDate();
  }
  return DateTime.parse(date);
}
