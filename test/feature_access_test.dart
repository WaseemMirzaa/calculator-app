import 'package:flutter_test/flutter_test.dart';
import 'package:golden_grain_calculator/models/app_feature.dart';
import 'package:golden_grain_calculator/models/precision.dart';
import 'package:golden_grain_calculator/services/subscription_catalog.dart';

void main() {
  test('free tier unlocks only 1/16 precision', () {
    expect(
      FeatureAccess.isPrecisionUnlocked(Precision.p16, isPremium: false),
      isTrue,
    );
    expect(
      FeatureAccess.isPrecisionUnlocked(Precision.p32, isPremium: false),
      isFalse,
    );
    expect(
      FeatureAccess.isUnlocked(
        AppFeature.millimeterConversion,
        isPremium: false,
      ),
      isFalse,
    );
  });

  test('premium unlocks every gated feature', () {
    for (final item in FeatureAccess.catalog) {
      expect(item.isUnlocked(isPremium: true), isTrue);
    }
  });

  test('billing period labels are human readable', () {
    expect(SubscriptionCatalog.formatBillingPeriod('P1M'), 'Monthly');
    expect(SubscriptionCatalog.formatBillingPeriod('P1Y'), 'Yearly');
  });
}
