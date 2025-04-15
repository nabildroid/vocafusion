import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vocafusion/cubits/premium_cubit.dart';

Map<String, InAppWebViewKeepAlive> alives = {};

class StripeCheckoutSreen extends StatelessWidget {
  final String checkoutWebviewKey;
  StripeCheckoutSreen({
    super.key,
    required this.checkoutWebviewKey,
  });

  bool isCommitedPop = false;

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

    return SafeArea(
      child: Scaffold(
        body: InAppWebView(
          keepAlive: alives[checkoutWebviewKey],
          headlessWebView:
              context.read<PremiumCubit>().headlessStripes[checkoutWebviewKey],
          onLoadStop: (controller, url) async {
            if (url != null &&
                !url.toString().contains("stripe") &&
                !url.toString().contains("ngrok")) {
              if (isCommitedPop) return;
              isCommitedPop = true;
              if (url.toString().contains("success")) {
                await controller.pauseTimers();
                Navigator.of(context).pop(true);
                return;
              } else {
                alives = {};
                Navigator.of(context).pop(false);
              }
            }
          },
        ),
      ),
    );
  }
}
