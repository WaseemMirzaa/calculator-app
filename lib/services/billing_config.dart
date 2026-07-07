/// Google Play subscription identifiers for Pro Precision.
///
/// Play Console setup:
/// - Subscription product ID: `goldengrain_premium`
/// - Base plans: `monthly` (auto-renewing), `yearly` (prepaid)
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class BillingConfig {
  BillingConfig._();

  static const String androidPackageName = 'com.app.goldengraincalculator';

  /// Play Console subscription product ID.
  static const String subscriptionProductId = 'goldengrain_premium';

  /// Base plan IDs configured under the subscription in Play Console.
  static const String monthlyBasePlanId = 'monthly';
  static const String yearlyBasePlanId = 'yearly';

  /// Default base plan for compact upsell entry points.
  static const String defaultBasePlanId = monthlyBasePlanId;

  /// Product IDs passed to [InAppPurchase.queryProductDetails].
  static const Set<String> subscriptionIds = {subscriptionProductId};

  /// Base plans we surface in the subscription UI (in display order).
  static const List<String> basePlanIds = [
    monthlyBasePlanId,
    yearlyBasePlanId,
  ];

  static bool isSubscriptionProduct(String productId) =>
      productId == subscriptionProductId;

  static bool isYearlyBasePlan(String basePlanId) =>
      basePlanId == yearlyBasePlanId;

  static bool isMonthlyBasePlan(String basePlanId) =>
      basePlanId == monthlyBasePlanId;

  /// Play replacement mode for switching base plans on [subscriptionProductId].
  ///
  /// Google Play requires [ReplacementMode.chargeFullPrice] when the target is
  /// a prepaid base plan (our yearly plan). [withTimeProration] fails for that
  /// upgrade path.
  static ReplacementMode replacementModeForPlanChange({
    required String? currentBasePlanId,
    required String targetBasePlanId,
  }) {
    if (isYearlyBasePlan(targetBasePlanId)) {
      return ReplacementMode.chargeFullPrice;
    }
    if (currentBasePlanId != null && isYearlyBasePlan(currentBasePlanId)) {
      return ReplacementMode.chargeFullPrice;
    }
    return ReplacementMode.chargeFullPrice;
  }
}
