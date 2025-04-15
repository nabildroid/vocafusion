import 'dart:async';
import 'dart:math';
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

  final bool checkingNewPruchase;
  final bool isNewPurchased;

  PremiumState({
    this.selectedPackage,
    this.loadingWebviews = false,
    this.loadingPircing = false,
    this.paymentGatway = PaymentGatway.google,
    this.pricing,
    this.products,
    this.checkingNewPruchase = false,
    this.isNewPurchased = false,
  });

  PremiumState copyWith({
    SelectedPremiumPackageOption? selectedPackage,
    bool? loadingWebviews,
    PaymentGatway? paymentGatway,
    bool? loadingPircing,
    List<PricingPlan>? pircing,
    List<ProductDetails>? products,
    bool? checkingNewPruchase,
    bool? isNewPurchased,
  }) {
    return PremiumState(
      selectedPackage: selectedPackage ?? this.selectedPackage,
      loadingWebviews: loadingWebviews ?? this.loadingWebviews,
      paymentGatway: paymentGatway ?? this.paymentGatway,
      loadingPircing: loadingPircing ?? this.loadingPircing,
      pricing: pircing ?? this.pricing,
      products: products ?? this.products,
      checkingNewPruchase: checkingNewPruchase ?? this.checkingNewPruchase,
      isNewPurchased: isNewPurchased ?? this.isNewPurchased,
    );
  }

  @override
  List<Object?> get props => [
        selectedPackage,
        loadingWebviews,
        paymentGatway,
        loadingPircing,
        pricing,
        products,
        checkingNewPruchase,
        isNewPurchased,
      ];
}

class PremiumCubit extends Cubit<PremiumState> {
  PremiumCubit() : super(PremiumState());

  StreamSubscription? _inAppPurchaseSub;

  void setSelecedPackage(SelectedPremiumPackageOption package) {
    emit(state.copyWith(selectedPackage: package));
  }

  void selectStripeOffer(String id) {
    final selected = state.pricing!.firstWhere(
        (element) => element.offerId == id || element.basePlanId == id);

    setSelecedPackage(SelectedPremiumPackageOption(
      id: selected.offerId,
      freeTrialDays: selected.freeTrailDuration,
      gateway: PaymentGatway.stripe,
      price: "\$${selected.usdPrice}",
      period: selected.periodInDays > 30 ? "Year" : "Month",
    ));

    initStripePayment();
  }

  void handleStripeSuccess() async {
    final userRepo = locator.get<UserRepository>();

    userRepo.currentUser.value = userRepo.currentUser.value!.makeItPro();
    emit(state.copyWith(isNewPurchased: true));

    await userRepo.getUser(live: true);
  }

  void purchaseFromGoogle() async {
    final package = state.selectedPackage;
    if (package == null) return;
    if (package.gateway != PaymentGatway.google) return;

    final product = state.products!
        .where((e) => (e as GooglePlayProductDetails).offerToken == package.id);

    if (product.isEmpty) return;

    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product.first,
      ),
    );
  }

  Stream<List<PurchaseDetails>> getPurchaseStream() {
    return InAppPurchase.instance.purchaseStream.where((purchaseDetailsList) {
      if (purchaseDetailsList.isEmpty) return false;
      final purchaseDetails = purchaseDetailsList.first;

      return purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored ||
          purchaseDetails.pendingCompletePurchase;
    });
  }

  void init(User user) async {
    _inAppPurchaseSub?.cancel();
    final userRepo = locator.get<UserRepository>();

    _inAppPurchaseSub = getPurchaseStream().listen((purchaseDetailsList) async {
      final purchaseDetails = purchaseDetailsList.first;

      emit(state.copyWith(checkingNewPruchase: true));
      await locator.get<PaymentRepository>().verifyGooglePayment(
          purchaseDetails.verificationData.serverVerificationData);
      userRepo.currentUser.value = user.makeItPro();

      emit(state.copyWith(checkingNewPruchase: false, isNewPurchased: true));

      await InAppPurchase.instance.completePurchase(purchaseDetails);
      await userRepo.getUser(live: true);
    });
  }

  bool isStripeCheckoutInited = false;
  initStripePayment({bool force = false}) async {
    if (isStripeCheckoutInited && !force) return;
    isStripeCheckoutInited = true;

    emit(state.copyWith(loadingWebviews: true));
    final repo = locator.get<PaymentRepository>();

    final gatwayEntries = await Future.wait(state.pricing!.map((p) async {
      final key = p.offerId.isEmpty ? p.basePlanId : p.offerId;
      return MapEntry(key, await repo.getStripeLink(key));
    }));

    await createHeadlessStripeWebviews(gatwayEntries);
  }

  Map<String, HeadlessInAppWebView> headlessStripes = {};
  Future<void> createHeadlessStripeWebviews(
      List<MapEntry<String, String>> entries) async {
    int i = entries.length;
    for (var entry in entries) {
      final key = entry.key;
      final url = entry.value;

      if (headlessStripes[key] != null) {
        await headlessStripes[key]!.dispose();
        headlessStripes.remove(key);
      }

      headlessStripes[key] = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(),
        onLoadStart: (_, __) {
          // sometime trying multiple time for debug perpos block the experience
          if (kDebugMode && --i == 0) {
            emit(state.copyWith(loadingWebviews: false));
          }
        },
        onLoadStop: (_, __) {
          if (kReleaseMode && --i == 0) {
            emit(state.copyWith(loadingWebviews: false));
          }
        },
      );
      Future.delayed(Duration(milliseconds: 100));
      await headlessStripes[key]!.run();
    }
  }

  @override
  Future<void> close() {
    _inAppPurchaseSub?.cancel();

    for (var v in headlessStripes.values) {
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
      init(user);
      if (!user.claims.isTrulyPremium) {
        decidePayment(user);
        loadOffers();
      }
    }));
  }

  close() {
    _listeners.dispose();
  }
}
