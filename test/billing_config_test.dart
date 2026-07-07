import 'package:flutter_test/flutter_test.dart';
import 'package:golden_grain_calculator/services/billing_config.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

void main() {
  test('monthly to yearly upgrade uses chargeFullPrice for prepaid target', () {
    expect(
      BillingConfig.replacementModeForPlanChange(
        currentBasePlanId: BillingConfig.monthlyBasePlanId,
        targetBasePlanId: BillingConfig.yearlyBasePlanId,
      ),
      ReplacementMode.chargeFullPrice,
    );
  });

  test('yearly to monthly switch uses chargeFullPrice', () {
    expect(
      BillingConfig.replacementModeForPlanChange(
        currentBasePlanId: BillingConfig.yearlyBasePlanId,
        targetBasePlanId: BillingConfig.monthlyBasePlanId,
      ),
      ReplacementMode.chargeFullPrice,
    );
  });
}
