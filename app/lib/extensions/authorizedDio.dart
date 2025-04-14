import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class AuthorizedDio {
  static const baseUrl = kReleaseMode
      ? 'https://vocafusion-1020195160641.us-central1.run.app/'
      : "http://192.168.0.105:3000/";
  static final defaultHttp = Dio(BaseOptions(baseUrl: baseUrl));

  final Dio rawHttp;
  final completerhttp = Completer<Dio>();

  Future<Dio> get http => completerhttp.future;

  AuthorizedDio({required this.rawHttp});
}
