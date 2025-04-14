import 'dart:async';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/cubits/auth_cubit.dart';
import 'package:vocafusion/models/modeling.dart';
import 'package:vocafusion/repositories/feature_flag_repository.dart';
import 'package:vocafusion/repositories/payment_repository.dart';
import 'package:vocafusion/repositories/user_repository.dart';
import 'package:vocafusion/utils/utils.dart';

class SelectedPremiumPackageOption {
  final String id;
  final PaymentGatway gateway;
  final int freeTrialDays;
  final String price;
  final String period;

  SelectedPremiumPackageOption({
    required this.id,
    required this.gateway,
    required this.freeTrialDays,
    required this.price,
    required this.period,
  });
}

class PremiumState extends Equatable {
  final SelectedPremiumPackageOption? selectedPackage;

  final bool loadingWebviews;
  final bool loadingPircing;

  final List<PricingPlan>? pricing;
  final List<ProductDetails>? products;

  final PaymentGatway paymentGatway;

  PremiumState({
    this.selectedPackage,
    this.loadingWebviews = false,
    this.loadingPircing = false,
    this.paymentGatway = PaymentGatway.google,
    this.pricing,
    this.products,
  });

  PremiumState copyWith({
    SelectedPremiumPackageOption? selectedPackage,
    bool? loadingWebviews,
    PaymentGatway? paymentGatway,
    bool? loadingPircing,
    List<PricingPlan>? pircing,
    List<ProductDetails>? products,
  }) {
    return PremiumState(
      selectedPackage: selectedPackage ?? this.selectedPackage,
      loadingWebviews: loadingWebviews ?? this.loadingWebviews,
      paymentGatway: paymentGatway ?? this.paymentGatway,
      loadingPircing: loadingPircing ?? this.loadingPircing,
      pricing: pircing ?? this.pricing,
      products: products ?? this.products,
    );
  }

  @override
  List<Object?> get props => [
        selectedPackage,
        loadingWebviews,
        paymentGatway,
        loadingPircing,
        pricing,
        products
      ];
}

class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit() : super(PremiumState());

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  void setSelecedPackage(SelectedPremiumPackageOption package) {
    emit(state.copyWith(selectedPackage: package));
  }

  void selectStripeOffer(String id) {
    final selected = state.pricing!.firstWhere(
        (element) => element.offerId == id || element.basePlanId == id);

    emit(state.copyWith(
      selectedPackage: SelectedPremiumPackageOption(
        id: selected.offerId,
        freeTrialDays: selected.freeTrailDuration,
        gateway: PaymentGatway.stripe,
        price: "\$${selected.usdPrice}",
        period: selected.periodInDays > 30 ? "Year" : "Month",
      ),
    ));

    initExternalPayment();
  }

  void purchase() async {
    final package = state.selectedPackage;
    if (package == null) return;

    if (package.gateway == PaymentGatway.google) {
      final product = state.products!.where(
          (e) => (e as GooglePlayProductDetails).offerToken == package.id);

      if (product.isEmpty) return;

      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product.first,
        ),
      );
    } else {}
  }

  void init() {
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
    purchaseUpdated.listen(
      (purchaseDetailsList) {},
      onDone: () {},
      onError: (error) {},
    );
  }

  bool isExternalCheckoutInited = false;
  initExternalPayment({bool force = false}) async {
    if (isExternalCheckoutInited && !force) return;
    isExternalCheckoutInited = true;

    emit(state.copyWith(loadingWebviews: true));
    final repo = locator.get<PaymentRepository>();

    final gatwayEntries = await Future.wait(state.pricing!.map((p) async {
      final key = p.offerId.isEmpty ? p.basePlanId : p.offerId;
      return MapEntry(key, await repo.getCheckoutLink(key));
    }));

    createHeadlessWebviews(gatwayEntries);
  }

  Map<String, HeadlessInAppWebView> headless = {};
  createHeadlessWebviews(List<MapEntry<String, String>> entries) async {
    int i = entries.length;
    for (var entry in entries) {
      final key = entry.key;
      final url = entry.value;

      if (headless[key] != null) {
        await headless[key]!.dispose();
        headless.remove(key);
      }

      headless[key] = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(),
        onLoadStop: (_, __) {
          i--;
          if (i == 0) {
            emit(state.copyWith(loadingWebviews: false));
          }
        },
      );
      await headless[key]!.run();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();

    for (var v in headless.values) {
      v.dispose();
    }
    return super.close();
  }

  Future<void> loadOffers() async {
    emit(state.copyWith(loadingPircing: true));

    final productsFuture = InAppPurchase.instance
        .queryProductDetails({"me.laknabil.voca.premium"}).catchError((e) =>
            ProductDetailsResponse(
                error: e, productDetails: [], notFoundIDs: []));

    final promises = await waitForTwo(
      locator.get<PaymentRepository>().getPircing(),
      productsFuture,
    );

    emit(state.copyWith(
      loadingPircing: false,
      pircing: promises.key,
      products: promises.value.productDetails,
    ));
  }

  decidePayment(User user) async {
    final repo = locator.get<FeatureFlagRepository>();

    final isGoogleAvialable = await InAppPurchase.instance.isAvailable();

    if (isGoogleAvialable) {
      final paymentGatway = await repo.getPaymentGateway();
      emit(state.copyWith(paymentGatway: paymentGatway));
    } else {
      emit(state.copyWith(paymentGatway: PaymentGatway.stripe));
    }
  }
}

extension PremiumCubitExtention on PremiumCubit {
  static final _listeners = CompositeSubscription();

  sync(BuildContext context) async {
    final userStream = context
        .read<AuthCubit>()
        .stream
        .map((e) => e.user)
        .distinct()
        .whereNotNull();

    _listeners.add(userStream.listen((user) {
      if (!user.claims.isTrulyPremium) {
        decidePayment(user);
        loadOffers();
      }
    }));

    init();
  }

  close() {
    _listeners.dispose();
  }
}

String _parseVariantLink(String link) {
  return "https://" + link.replaceAll("_", ".").replaceAll("--", "/");
}
