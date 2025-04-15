import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/repositories/user_repository.dart';

class PricingPlan {
  final String basePlanId;
  final String packageName;
  final String productId;
  final String offerId;
  final int freeTrailDuration;
  final int periodInDays;
  final double usdPrice;
  final bool isSubscription;

  PricingPlan({
    required this.basePlanId,
    required this.packageName,
    required this.productId,
    required this.offerId,
    required this.freeTrailDuration,
    required this.periodInDays,
    required this.usdPrice,
    required this.isSubscription,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      basePlanId: json['basePlanId'] as String,
      packageName: json['packageName'] as String,
      productId: json['productId'] as String,
      offerId: json['offerId'] as String,
      freeTrailDuration: json['freeTrailDuration'] as int,
      periodInDays: json['periodInDays'] as int,
      usdPrice: (json['usdPrice'] as num).toDouble(),
      isSubscription: json['isSubscription'] as bool,
    );
  }
}

class PaymentRepository {
  final repo = locator.get<UserRepository>();

  Future<List<PricingPlan>> getPircing() async {
    final reponse = await repo.http.get("/payment/pricing");

    if (reponse.statusCode != 200) {
      throw Exception("Error getting pricing");
    }

    final List<dynamic> data = reponse.data['offers'] as List<dynamic>;
    final List<PricingPlan> pricingPlans = data
        .map((e) => PricingPlan.fromJson(e as Map<String, dynamic>))
        .toList();
    return pricingPlans;
  }

  Future<String> getStripeLink(String productId) async {
    final link =
        "${repo.http.options.baseUrl}/payment/${repo.currentUser.value!.uid}/$productId";
    return link;
  }

  Future<void> verifyGooglePayment(String googleToken) async {
    final clientId = repo.currentUser.value!.uid;
    final response = await repo.http.post(
      "/payment/purchase/google-play/verify/$clientId",
      data: {
        "serverToken": googleToken,
      },
    );

    print(response);
  }
}
