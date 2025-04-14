import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/premium_cubit.dart';
import 'package:vocafusion/repositories/user_repository.dart';

Map<String, InAppWebViewKeepAlive> alives = {};

class StripeCheckoutSreen extends StatelessWidget {
  final String checkoutWebviewKey;
  const StripeCheckoutSreen({
    super.key,
    required this.checkoutWebviewKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select((PremiumCubit s) => s.state.loadingWebviews);

    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (alives[checkoutWebviewKey] == null) {
      alives[checkoutWebviewKey] = InAppWebViewKeepAlive();
    }

    return PopScope(
      onPopInvokedWithResult: (isForced, __) {
        unawaited(locator.get<UserRepository>().getUser(live: true));
      },
      child: SafeArea(
        child: Scaffold(
          body: InAppWebView(
            keepAlive: alives[checkoutWebviewKey],
            headlessWebView:
                context.read<PremiumCubit>().headless[checkoutWebviewKey],
            onWebViewCreated: (controller) {},
            onLoadStop: (controller, url) async {
              if (url != null &&
                  !url.toString().contains("stripe") &&
                  !url.toString().contains("ngrok")) {
                if (url.toString().contains("ngrok")) {}

                context.read<PremiumCubit>().initExternalPayment(force: true);
                alives = {};
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ),
    );
  }
}
