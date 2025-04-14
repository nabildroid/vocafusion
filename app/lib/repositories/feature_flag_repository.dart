import 'dart:math';

import 'package:dio/dio.dart';
import 'package:vocafusion/config/locator.dart';
import 'package:vocafusion/repositories/preferences_repository.dart';

enum PaymentGatway {
  stripe,
  google,
}

class FeatureFlagRepository {
  final PreferenceRepository _prefs = locator.get();
  final Dio http = Dio();

  Future<Map<String, dynamic>> appSoonflags() async {
    const apiKey = 'phc_yi3x5y6UV0b8ZsUuyzKGMlgDpJwMCo2eSsC9RxbaNEn';
    const url = 'https://eu.i.posthog.com/decide?v=3/';

    final response = await http.post(url, data: {
      'api_key': apiKey,
      'distinct_id': Random().nextInt(100).toString(),
    });

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final featureFlags = data['featureFlags'] as Map<String, dynamic>? ?? {};
      return featureFlags;
    } else {
      // Handle error, e.g., throw an exception or return an empty map
      throw Exception('Failed to load feature flags: ${response.statusCode}');
      // Or return {};
    }
  }

  Future<PaymentGatway> getPaymentGateway() async {
    final featureFlags = await appSoonflags();
    final paymentGateway = featureFlags['voca-purchaseGatway'] as String?;

    if (paymentGateway == 'stripe') {
      return PaymentGatway.stripe;
    } else if (paymentGateway == 'google') {
      return PaymentGatway.google;
    } else {
      return PaymentGatway.google; // Default value
    }
  }
}
