import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/learning/learning_session_cubit.dart';
import 'package:vocafusion/repositories/user_repository.dart';

// import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vocafusion/screens/fav_screen.dart';
import 'package:vocafusion/screens/learning_screen/learning_screen.dart';
import 'package:vocafusion/screens/onboarding_screen.dart';
import 'package:vocafusion/screens/premium/global_premium_listener.dart';

final GoRouter router = GoRouter(
  observers: [
    locator.get<RouteObserver<ModalRoute<dynamic>>>(),
    SentryNavigatorObserver(),
    // if (Platform.isAndroid) PosthogObserver(),
  ],
  redirect: (BuildContext context, GoRouterState state) async {
    final isReady =
        context.read<LearningSessionCubit>().state.currentFlowId.isNotEmpty;

    if (state.fullPath == null) return null;

    if (!isReady) {
      if (state.fullPath!.startsWith("/register") ||
          state.fullPath!.startsWith("/onboarding")) return null;
      return "/onboarding";
    } else {
      if (state.fullPath!.startsWith("/learn") ||
          state.fullPath!.startsWith("/favorites")) return null;
      return "/learn";
    }
  },
  initialLocation: "/learn",
  routes: [
    ShellRoute(
      // navigatorKey: _shellNavigatorKey, // Use if needed for nested navigation
      builder: (context, state, child) {
        // The child here is the widget managed by the GoRouter for the current route
        // Wrap it with the listener
        return GlobalPremiumListenerWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: "/learn",
          builder: (context, state) => LearningScreen(),
          routes: [
            GoRoute(
              path: "favorites",
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                child: FavScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                barrierDismissible: true,
                barrierColor: Colors.black38,
                opaque: false,
                maintainState: true,
              ),
            ),
          ],
        ),
        GoRoute(
          path: "/onboarding",
          builder: (context, state) => const AdsScreen(),
        ),
      ],
    )
  ],
);
