import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/repositories/user_repository.dart';

import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final GoRouter router = GoRouter(
  observers: [
    locator.get<RouteObserver<ModalRoute<dynamic>>>(),
    SentryNavigatorObserver(),
    if (Platform.isAndroid) PosthogObserver(),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final user = await locator.get<UserRepository>().currentUser.first.timeout(
          const Duration(milliseconds: 200), // todo, 200 is a random number
          onTimeout: () => null,
        );

    if (state.fullPath == null) return null;

    if (user == null) {
      if (state.fullPath!.startsWith("/onboarding")) return null;
      if (state.fullPath!.startsWith("/login")) return null;
      if (state.fullPath!.startsWith("/register")) return null;
      return "/onboarding";
    }
  },
  initialLocation: "/onboarding",
  routes: [],
);
