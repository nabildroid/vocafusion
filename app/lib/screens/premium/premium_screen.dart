import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocafusion/cubits/premium_cubit.dart';
import 'package:vocafusion/models/modeling.dart'; // Ensure PricingPlan is imported if needed
import 'package:vocafusion/repositories/feature_flag_repository.dart';
import 'package:vocafusion/screens/premium/stripe_checkout_screen.dart';
//import for GooglePlayProductDetails
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
//import for SkuDetailsWrapper
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:vocafusion/utils/utils.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch offers when the screen initializes
    // Initialize external payment if needed
    // context.read<PremiumCubit>().initExternalPayment();
  }

  void checkout() async {
    final cubit = context.read<PremiumCubit>();
    cubit.purchase();

    if (cubit.state.paymentGatway == PaymentGatway.stripe) {
      // Example: Navigate to checkout
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        // Pass the selected ID or related product details if needed
        final selected = cubit.state.selectedPackage!;

        return StripeCheckoutSreen(
          checkoutWebviewKey: selected.id,
        );
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 0, 99, 8),
              const Color.fromARGB(255, 19, 31, 20),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            _buildHeader(context),
            // Use the new standalone widget
            SubscriptionOptionsWidget(),
            _buildFeaturesSection(context),
          ],
        ),
      ),
      floatingActionButton: _buildTrialButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'VocaFusion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT\'S INCLUDED',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildFeatureItem(
            icon: Icons.text_fields, // Example icon
            label: 'Multiple Word Contexts',
          ),
          _buildFeatureItem(
            icon: Icons.alt_route, // Example icon
            label: 'Interactive Story Paths',
            isNew: true,
          ),
          _buildFeatureItem(
            icon: Icons.quiz, // Example icon
            label: 'Unlimited Daily Quizzes',
          ),
          _buildFeatureItem(
            icon: Icons.widgets, // Example icon
            label: 'Home Screen Widget',
          ),
          _buildFeatureItem(
            icon: Icons.trending_up,
            label: 'Track Progress',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    bool isNew = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrialButton(BuildContext context) {
    return Builder(builder: (context) {
      final package = context.watch<PremiumCubit>().state.selectedPackage;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                if (package != null) {
                  checkout();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard),
                  SizedBox(width: 8),
                  Text(
                    package == null
                        ? "Loading"
                        : package.freeTrialDays > 0
                            ? "Redeem ${package.freeTrialDays} days Free Trial"
                            : 'Start ${package.period} Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // TODO: Update this text dynamically based on the selected plan
            Text(
              package == null
                  ? "Loading"
                  : '${package.freeTrialDays > 0 ? "${package.freeTrialDays} day free trial, then" : ""} ${package.price} / ${package.period}. Cancel anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// New Standalone Widget for Subscription Options
class SubscriptionOptionsWidget extends StatelessWidget {
  const SubscriptionOptionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PremiumCubit>().state;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(children: [
        const Text(
          'Experience VocaFusion with unlimited access to all features.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        if (state.paymentGatway == PaymentGatway.google)
          buildGoogleOptions(context),
        if (state.paymentGatway == PaymentGatway.stripe)
          buildStipeOptions(context),
      ]),
    );
  }

  Widget buildGoogleOptions(BuildContext context) {
    final cubit = context.read<PremiumCubit>();
    final products =
        List<GooglePlayProductDetails>.from(cubit.state.products ?? []);

    final packaging = GooglePayUtils.getPackagesFromProductDetails(products);

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: packaging
          .map(
            (e) => SubscriptionOption(
              title: e.period + "ly",
              price: e.price,
              period: " / " + e.period,
              isSelected: cubit.state.selectedPackage?.id == e.id,
              onTap: () {
                cubit.setSelecedPackage(e);
              },
              bestValue: e.period == "Year",
              isLoading: false,
            ),
          )
          .toList(),
    );
  }

  Widget buildStipeOptions(BuildContext context) {
    final cubit = context.read<PremiumCubit>();
    final state = cubit.state;

    return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: state.pricing
                ?.map(
                  (e) => SubscriptionOption(
                    title: e.periodInDays > 30 ? 'Yearly' : 'Monthly',
                    price: '\$${e.usdPrice}',
                    period: e.periodInDays > 30
                        ? ' / ${e.periodInDays ~/ 30} months'
                        : ' / ${e.periodInDays} days',
                    isSelected: state.selectedPackage?.id == e.offerId,
                    onTap: () {
                      cubit.selectStripeOffer(e.offerId);
                    },
                    bestValue: e.periodInDays > 30,
                    isLoading: false,
                  ),
                )
                .toList() ??
            []);
  }

  // Helper method moved inside the new widget
}

class SubscriptionOption extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final bool isSelected;
  final VoidCallback onTap;
  final bool bestValue;
  final bool isLoading;
  const SubscriptionOption({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.onTap,
    required this.bestValue,
    required this.isLoading,
  });

  @override
  State<SubscriptionOption> createState() => _SubscriptionOptionState();
}

class _SubscriptionOptionState extends State<SubscriptionOption> {
  @override
  void initState() {
    super.initState();
    if (widget.bestValue) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isLoading ? Colors.black12 : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: widget.isSelected
              ? Border.all(color: Colors.white38, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                color: widget.isSelected ? Colors.white : Colors.transparent,
              ),
              child: widget.isSelected && !widget.isLoading
                  ? const Icon(Icons.check, color: Colors.black, size: 18)
                  : widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white54),
                        )
                      : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isLoading ? Colors.white54 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.price}${widget.period}',
                  style: TextStyle(
                    color: widget.isLoading ? Colors.white38 : Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (widget.bestValue && !widget.isLoading)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
