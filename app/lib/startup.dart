import 'dart:async';

import 'package:vocafusion/extensions/authorizedDio.dart';

void prefetchDNS() {
  final promises = [
    AuthorizedDio.defaultHttp.get("/"),
  ];

  Future.wait(promises).ignore();
}
