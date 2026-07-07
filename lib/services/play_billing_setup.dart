import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// ignore: implementation_imports
import 'package:in_app_purchase_android/src/billing_client_wrappers/pending_purchases_params_wrapper.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

/// Configures the shared Play Billing client before product queries.
///
/// The default [BillingClientManager] disables prepaid plans. Our yearly base
/// plan is prepaid in Play Console, so we reconnect with prepaid support
/// enabled before querying or purchasing.
Future<void> configurePlayBilling() async {
  if (!Platform.isAndroid) {
    return;
  }

  try {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      debugPrint('Play Billing not available during setup.');
      return;
    }

    final platform = InAppPurchasePlatform.instance;
    if (platform is! InAppPurchaseAndroidPlatform) {
      debugPrint('Expected InAppPurchaseAndroidPlatform.');
      return;
    }

    // ignore: invalid_use_of_visible_for_testing_member
    await platform.billingClientManager.reconnectWithPendingPurchasesParams(
      const PendingPurchasesParamsWrapper(enablePrepaidPlans: true),
    );
    debugPrint('Play Billing configured with prepaid plan support.');
  } catch (error, stack) {
    debugPrint('Play Billing setup failed: $error\n$stack');
  }
}
