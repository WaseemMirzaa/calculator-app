import 'package:in_app_purchase/in_app_purchase.dart';

/// Store listing for a monthly or yearly Pro Precision base plan.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.productId,
    required this.basePlanId,
    required this.title,
    required this.durationLabel,
    required this.price,
    required this.productDetails,
    this.offerLabel,
    this.offerToken,
    this.billingPeriodIso,
    this.isFromStore = true,
  });

  /// Play subscription product ID (e.g. `goldengrain_premium`).
  final String productId;

  /// Play base plan ID (e.g. `monthly`, `yearly`).
  final String basePlanId;

  final String title;
  final String durationLabel;
  final String price;
  final String? offerLabel;
  final String? offerToken;
  final String? billingPeriodIso;
  final bool isFromStore;
  final ProductDetails productDetails;

  String get subscribeLabel => 'Subscribe — $price';

  String get pricePerDuration {
    if (durationLabel.toLowerCase().contains('year')) {
      return '$price / year';
    }
    if (durationLabel.toLowerCase().contains('month')) {
      return '$price / month';
    }
    return '$price · $durationLabel';
  }
}
