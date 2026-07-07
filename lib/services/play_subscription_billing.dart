import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/purchase_result.dart';
import '../models/subscription_plan.dart';
import 'billing_config.dart';
import 'subscription_catalog.dart';

/// Android Google Play Billing operations for subscription products.
///
/// Uses [InAppPurchase] + [GooglePlayPurchaseParam] with offer tokens required
/// by Play Billing Library 5+ — no mocked purchases.
class PlaySubscriptionBilling {
  PlaySubscriptionBilling({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Queries Play Console subscription products and parses plans/offers.
  Future<PlayProductQueryResult> queryPlans() async {
    if (!Platform.isAndroid) {
      return PlayProductQueryResult.unavailable(
        'Google Play Billing is only supported on Android.',
      );
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return PlayProductQueryResult.unavailable(
        'Google Play Billing is not available on this device.',
      );
    }

    ProductDetailsResponse? response;
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
      try {
        response =
            await _iap.queryProductDetails(BillingConfig.subscriptionIds);
        if (response.productDetails.isNotEmpty) {
          break;
        }
      } catch (error, stack) {
        lastError = error;
        debugPrint('Play query attempt ${attempt + 1} failed: $error\n$stack');
      }
    }

    if (response == null) {
      return PlayProductQueryResult.error(
        'Google Play product query failed: ${lastError ?? "unknown error"}',
      );
    }

    if (response.error != null) {
      return PlayProductQueryResult.error(response.error!.message);
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
        'Play Console subscription IDs not found: ${response.notFoundIDs}',
      );
    }

    debugPrint(
      'Play queryProductDetails: '
      'found=${response.productDetails.length}, '
      'notFound=${response.notFoundIDs}, '
      'error=${response.error?.message}',
    );

    if (response.productDetails.isEmpty) {
      final notFound = response.notFoundIDs.isEmpty
          ? BillingConfig.subscriptionProductId
          : response.notFoundIDs.join(', ');
      return PlayProductQueryResult.error(
        'No subscription plans returned from Google Play for: $notFound. '
        'Confirm ${BillingConfig.subscriptionProductId} with base plans '
        '${BillingConfig.monthlyBasePlanId} and ${BillingConfig.yearlyBasePlanId} '
        'are active in Play Console for ${BillingConfig.androidPackageName}, '
        'then install the app from the Play closed-testing link (not a sideloaded APK).',
      );
    }

    final plans =
        SubscriptionCatalog.fromProductDetails(response.productDetails);
    if (plans.isEmpty) {
      final discovered = SubscriptionCatalog.discoveredBasePlanIds(
        response.productDetails,
      );
      return PlayProductQueryResult.error(
        'Subscription product loaded but no matching base plans were found. '
        'Expected ${BillingConfig.monthlyBasePlanId} and '
        '${BillingConfig.yearlyBasePlanId}; Play returned: '
        '${discovered.isEmpty ? "none" : discovered.join(", ")}.',
      );
    }

    return PlayProductQueryResult.success(plans);
  }

  /// Launches the native Google Play purchase sheet for [plan].
  Future<PurchaseResult> purchase(
    SubscriptionPlan plan, {
    ChangeSubscriptionParam? changeSubscriptionParam,
  }) async {
    if (!Platform.isAndroid) {
      return const PurchaseResult.failed(
        'Subscriptions are only available on Android.',
      );
    }

    if (!plan.isFromStore) {
      return const PurchaseResult.failed(
        'Wait for Google Play prices to load, then try again.',
      );
    }

    final product = plan.productDetails;
    if (product is! GooglePlayProductDetails) {
      return const PurchaseResult.failed(
        'Expected Google Play product details.',
      );
    }

    final offerToken = plan.offerToken;
    if (offerToken == null || offerToken.isEmpty) {
      return const PurchaseResult.failed(
        'Missing subscription offer token from Google Play.',
      );
    }

    try {
      final launched = await _iap.buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: offerToken,
          changeSubscriptionParam: changeSubscriptionParam,
        ),
      );
      if (!launched) {
        return const PurchaseResult.failed(
          'Google Play did not open the purchase screen.',
        );
      }
      return const PurchaseResult.launched();
    } catch (error, stack) {
      debugPrint('Play purchase launch failed: $error\n$stack');
      return PurchaseResult.failed('Purchase failed: $error');
    }
  }

  /// Restores purchases and returns the active subscription from Play, if any.
  Future<PlayEntitlementSyncResult> syncEntitlement() async {
    if (!Platform.isAndroid) {
      return const PlayEntitlementSyncResult.inactive();
    }

    final available = await _iap.isAvailable();
    if (!available) {
      return const PlayEntitlementSyncResult.inactive();
    }

    await _iap.restorePurchases();

    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();

    if (response.error != null) {
      return PlayEntitlementSyncResult.error(response.error!.message);
    }

    for (final purchase in response.pastPurchases) {
      if (!BillingConfig.isSubscriptionProduct(purchase.productID)) {
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        return PlayEntitlementSyncResult.active(
          productId: purchase.productID,
          purchase: purchase as GooglePlayPurchaseDetails,
        );
      }
    }

    return const PlayEntitlementSyncResult.inactive();
  }
}

/// Parsed subscription plans from a Play product query.
class PlayProductQueryResult {
  const PlayProductQueryResult._({
    required this.plans,
    required this.errorMessage,
  });

  factory PlayProductQueryResult.success(List<SubscriptionPlan> plans) {
    return PlayProductQueryResult._(plans: plans, errorMessage: null);
  }

  factory PlayProductQueryResult.error(String message) {
    return PlayProductQueryResult._(plans: const [], errorMessage: message);
  }

  factory PlayProductQueryResult.unavailable(String message) {
    return PlayProductQueryResult._(plans: const [], errorMessage: message);
  }

  final List<SubscriptionPlan> plans;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null && plans.isNotEmpty;
}

/// Active subscription state returned from Play [queryPastPurchases].
class PlayEntitlementSyncResult {
  const PlayEntitlementSyncResult._({
    required this.isActive,
    required this.productId,
    required this.purchase,
    required this.errorMessage,
  });

  const factory PlayEntitlementSyncResult.active({
    required String productId,
    required GooglePlayPurchaseDetails? purchase,
  }) = PlayEntitlementActive;

  const factory PlayEntitlementSyncResult.inactive() = PlayEntitlementInactive;

  factory PlayEntitlementSyncResult.error(String message) {
    return PlayEntitlementSyncResult._(
      isActive: false,
      productId: null,
      purchase: null,
      errorMessage: message,
    );
  }

  final bool isActive;
  final String? productId;
  final GooglePlayPurchaseDetails? purchase;
  final String? errorMessage;
}

final class PlayEntitlementActive extends PlayEntitlementSyncResult {
  const PlayEntitlementActive({
    required String productId,
    required GooglePlayPurchaseDetails? purchase,
  }) : super._(
          isActive: true,
          productId: productId,
          purchase: purchase,
          errorMessage: null,
        );
}

final class PlayEntitlementInactive extends PlayEntitlementSyncResult {
  const PlayEntitlementInactive()
      : super._(
          isActive: false,
          productId: null,
          purchase: null,
          errorMessage: null,
        );
}
