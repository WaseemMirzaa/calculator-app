import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/purchase_result.dart';
import '../models/subscription_plan.dart';
import 'billing_config.dart';
import 'play_subscription_billing.dart';
import 'subscription_catalog.dart';

/// Owns Pro Precision entitlement backed by real Google Play subscriptions.
///
/// On Android, premium is granted only when Play reports an active subscription
/// via [PlaySubscriptionBilling.syncEntitlement] or a verified purchase update.
/// There is no mocked purchase path.
class PremiumService extends ChangeNotifier {
  PremiumService({PlaySubscriptionBilling? playBilling})
      : _playBilling = playBilling ?? PlaySubscriptionBilling();

  static const String _prefsKey = 'gg_is_premium';
  static const String _activeBasePlanKey = 'gg_active_base_plan_id';
  static const String _legacyActiveProductKey = 'gg_active_product_id';

  final PlaySubscriptionBilling _playBilling;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _billingReady = false;
  bool _loadingProducts = false;
  String? _productsError;
  String? _lastBillingError;

  List<SubscriptionPlan> _plans = const [];
  String? _activeBasePlanId;
  String? _pendingBasePlanId;
  GooglePlayPurchaseDetails? _activeGooglePurchase;

  bool _isPremium = false;
  bool get isPremium => _isPremium;
  bool get billingReady => _billingReady;
  bool get loadingProducts => _loadingProducts;
  String? get productsError => _productsError;
  String? get lastBillingError => _lastBillingError;
  List<SubscriptionPlan> get plans => List.unmodifiable(_plans);
  String? get activeBasePlanId => _activeBasePlanId;

  /// Play subscription product ID when the user has an active plan.
  String? get activeProductId =>
      _isPremium ? BillingConfig.subscriptionProductId : null;

  SubscriptionPlan? get activePlan {
    if (_activeBasePlanId == null) {
      return null;
    }
    for (final plan in _plans) {
      if (plan.basePlanId == _activeBasePlanId) {
        return plan;
      }
    }
    return null;
  }

  String get price {
    final monthly = _plans.where(
      (plan) => plan.basePlanId == BillingConfig.monthlyBasePlanId,
    );
    if (monthly.isNotEmpty) {
      return monthly.first.price;
    }
    return PremiumFallbackPrices.monthly;
  }

  Future<void> init() async {
    if (Platform.isAndroid) {
      _billingReady = await _playBilling.isAvailable();
      if (_billingReady) {
        _purchaseSub = _iap.purchaseStream.listen(
          _onPurchaseUpdates,
          onError: (Object error) {
            _lastBillingError = error.toString();
            debugPrint('Purchase stream error: $error');
            notifyListeners();
          },
        );
        await refreshProducts();
        await syncEntitlementFromPlay();
        return;
      }
      _productsError =
          'Google Play Billing is not available on this device. '
          'Use a physical device with the Play Store app, sign in with your '
          'license-tester account, and install from the Play closed-testing link.';
      debugPrint('Google Play Billing unavailable — using offline cache.');
    }

    // Tests, iOS stub, or offline: fall back to cached prefs only.
    await _loadFromPrefs();
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    if (!Platform.isAndroid) {
      return;
    }
    if (!_billingReady) {
      _productsError ??=
          'Google Play Billing is not available on this device.';
      notifyListeners();
      return;
    }

    _loadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final result = await _playBilling.queryPlans();
      if (result.isSuccess) {
        _plans = result.plans;
        _productsError = null;
      } else {
        _productsError = result.errorMessage;
      }
    } catch (error, stack) {
      debugPrint('refreshProducts failed: $error\n$stack');
      _productsError = 'Could not load subscription plans: $error';
    } finally {
      _loadingProducts = false;
      notifyListeners();
    }
  }

  Future<PurchaseResult> purchase() {
    final monthly = _plans.where(
      (plan) => plan.basePlanId == BillingConfig.defaultBasePlanId,
    );
    if (monthly.isEmpty) {
      if (_plans.isEmpty) {
        return Future.value(
          const PurchaseResult.failed('Subscription plans are not loaded yet.'),
        );
      }
      return purchasePlan(_plans.first);
    }
    return purchasePlan(monthly.first);
  }

  Future<PurchaseResult> purchasePlan(SubscriptionPlan plan) async {
    _lastBillingError = null;
    if (!Platform.isAndroid || !_billingReady) {
      return const PurchaseResult.failed(
        'Google Play Billing is required to subscribe.',
      );
    }

    final isPlanChange = _isPremium &&
        _activeBasePlanId != null &&
        _activeBasePlanId != plan.basePlanId;

    if (isPlanChange) {
      await _ensureActivePurchaseLoaded();
      if (_activeGooglePurchase == null) {
        return const PurchaseResult.failed(
          'Could not load your current subscription from Google Play. '
          'Tap Restore purchases, then try again.',
        );
      }
    }

    _pendingBasePlanId = plan.basePlanId;
    final result = await _playBilling.purchase(
      plan,
      changeSubscriptionParam: _buildChangeParam(plan),
    );
    if (result case PurchaseFailed(:final message)) {
      _pendingBasePlanId = null;
      _lastBillingError = message;
      notifyListeners();
    }
    return result;
  }

  Future<void> _ensureActivePurchaseLoaded() async {
    if (_activeGooglePurchase != null) {
      return;
    }
    await syncEntitlementFromPlay();
  }

  /// Infers monthly vs yearly from Play purchase flags when prefs are missing.
  String? _inferBasePlanIdFromPurchase(GooglePlayPurchaseDetails purchase) {
    if (purchase.billingClientPurchase.isAutoRenewing) {
      return BillingConfig.monthlyBasePlanId;
    }
    return BillingConfig.yearlyBasePlanId;
  }

  ChangeSubscriptionParam? _buildChangeParam(SubscriptionPlan plan) {
    if (_activeGooglePurchase == null ||
        _activeBasePlanId == null ||
        _activeBasePlanId == plan.basePlanId) {
      return null;
    }
    return ChangeSubscriptionParam(
      oldPurchaseDetails: _activeGooglePurchase!,
      replacementMode: BillingConfig.replacementModeForPlanChange(
        currentBasePlanId: _activeBasePlanId,
        targetBasePlanId: plan.basePlanId,
      ),
    );
  }

  Future<bool> restore() async {
    _lastBillingError = null;
    if (Platform.isAndroid && _billingReady) {
      await syncEntitlementFromPlay();
      return _isPremium;
    }
    await _loadFromPrefs();
    notifyListeners();
    return _isPremium;
  }

  /// Re-checks Google Play for an active subscription (authoritative on Android).
  Future<void> syncEntitlementFromPlay() async {
    if (!Platform.isAndroid || !_billingReady) {
      return;
    }

    final result = await _playBilling.syncEntitlement();
    if (result.errorMessage != null) {
      _lastBillingError = result.errorMessage;
    }

    if (result.isActive && result.productId != null) {
      _activeGooglePurchase = result.purchase;
      final purchase = result.purchase;
      final basePlanId = _activeBasePlanId ??
          _pendingBasePlanId ??
          (purchase != null ? _inferBasePlanIdFromPurchase(purchase) : null);
      await _setPremium(true, basePlanId: basePlanId);
      return;
    }

    await _setPremium(false);
  }

  Future<bool> openSubscriptionManagement({String? productId}) async {
    if (!Platform.isAndroid) {
      return false;
    }
    final sku = productId ?? BillingConfig.subscriptionProductId;
    final url = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=${BillingConfig.androidPackageName}&sku=$sku',
    );
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Debug-only: clears local entitlement (does not cancel Play subscription).
  Future<void> resetToFree() => _setPremium(false);

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_prefsKey) ?? false;
      _activeBasePlanId = prefs.getString(_activeBasePlanKey);
      _activeBasePlanId ??= _migrateLegacyBasePlanId(
        prefs.getString(_legacyActiveProductKey),
      );
    } catch (_) {
      _isPremium = false;
      _activeBasePlanId = null;
    }
  }

  String? _migrateLegacyBasePlanId(String? legacyProductId) {
    switch (legacyProductId) {
      case 'goldengrain_monthly':
        return BillingConfig.monthlyBasePlanId;
      case 'goldengrain_yearly':
        return BillingConfig.yearlyBasePlanId;
      default:
        return null;
    }
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (!BillingConfig.isSubscriptionProduct(purchase.productID)) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _pendingBasePlanId = null;
          _lastBillingError =
              purchase.error?.message ?? 'Subscription purchase failed.';
          debugPrint('Purchase error: ${purchase.error}');
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase is GooglePlayPurchaseDetails) {
            _activeGooglePurchase = purchase;
          }
          final basePlanId = _pendingBasePlanId ??
              _activeBasePlanId ??
              (purchase is GooglePlayPurchaseDetails
                  ? _inferBasePlanIdFromPurchase(purchase)
                  : null);
          _pendingBasePlanId = null;
          unawaited(_setPremium(true, basePlanId: basePlanId));
          break;
        case PurchaseStatus.canceled:
          _pendingBasePlanId = null;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  Future<void> _setPremium(bool value, {String? basePlanId}) async {
    _isPremium = value;
    if (value && basePlanId != null) {
      _activeBasePlanId = basePlanId;
    }
    if (!value) {
      _activeBasePlanId = null;
      _activeGooglePurchase = null;
      _pendingBasePlanId = null;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
      if (value && basePlanId != null) {
        await prefs.setString(_activeBasePlanKey, basePlanId);
      } else if (!value) {
        await prefs.remove(_activeBasePlanKey);
        await prefs.remove(_legacyActiveProductKey);
      }
    } catch (_) {
      // ignore persistence failures
    }
    notifyListeners();
  }
}
