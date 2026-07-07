import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/subscription_plan.dart';
import 'billing_config.dart';

/// Builds [SubscriptionPlan]s from Play Store subscription product queries.
class SubscriptionCatalog {
  SubscriptionCatalog._();

  static List<SubscriptionPlan> fromProductDetails(
    Iterable<ProductDetails> productDetails,
  ) {
    final googleProducts =
        productDetails.whereType<GooglePlayProductDetails>().toList();

    if (googleProducts.isEmpty) {
      return const [];
    }

    final bestByBasePlan = <String, GooglePlayProductDetails>{};

    for (final candidate in googleProducts) {
      final index = candidate.subscriptionIndex;
      final offers = candidate.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) {
        continue;
      }

      final offer = offers[index];
      final basePlanId = offer.basePlanId;
      final existing = bestByBasePlan[basePlanId];

      // Prefer the standard base-plan offer over promotional offers.
      if (existing == null || offer.offerId == null) {
        bestByBasePlan[basePlanId] = candidate;
      }
    }

    if (bestByBasePlan.isEmpty) {
      return const [];
    }

    final orderedBasePlanIds = <String>[
      for (final id in BillingConfig.basePlanIds)
        if (bestByBasePlan.containsKey(id)) id,
      for (final id in bestByBasePlan.keys)
        if (!BillingConfig.basePlanIds.contains(id)) id,
    ];

    final plans = <SubscriptionPlan>[];
    for (final basePlanId in orderedBasePlanIds) {
      final candidate = bestByBasePlan[basePlanId];
      if (candidate != null) {
        plans.add(_planFromGoogleCandidate(candidate, basePlanId));
      }
    }

    return plans;
  }

  /// Base plan IDs returned by Play (for error messages / debugging).
  static List<String> discoveredBasePlanIds(
    Iterable<ProductDetails> productDetails,
  ) {
    final ids = <String>{};
    for (final candidate
        in productDetails.whereType<GooglePlayProductDetails>()) {
      final offers = candidate.productDetails.subscriptionOfferDetails;
      if (offers == null) {
        continue;
      }
      for (final offer in offers) {
        ids.add(offer.basePlanId);
      }
    }
    return ids.toList()..sort();
  }

  static SubscriptionPlan _planFromGoogleCandidate(
    GooglePlayProductDetails picked,
    String basePlanId,
  ) {
    String? offerToken = picked.offerToken;
    String durationLabel = _defaultDurationLabel(basePlanId);
    String? offerLabel;
    String? billingPeriodIso;

    final index = picked.subscriptionIndex;
    final offers = picked.productDetails.subscriptionOfferDetails;
    if (index != null && offers != null && index < offers.length) {
      final offer = offers[index];
      if (offer.pricingPhases.isNotEmpty) {
        final period = _recurringBillingPeriod(offer);
        if (period.isNotEmpty) {
          billingPeriodIso = period;
          durationLabel = formatBillingPeriod(period);
        }
        offerLabel = describeOffer(offer);
      }
    }

    return SubscriptionPlan(
      productId: BillingConfig.subscriptionProductId,
      basePlanId: basePlanId,
      title: _titleForBasePlan(basePlanId),
      durationLabel: durationLabel,
      price: picked.price,
      offerLabel: offerLabel,
      offerToken: offerToken,
      billingPeriodIso: billingPeriodIso,
      productDetails: picked,
    );
  }

  static String _titleForBasePlan(String basePlanId) {
    switch (basePlanId) {
      case BillingConfig.monthlyBasePlanId:
        return 'Monthly';
      case BillingConfig.yearlyBasePlanId:
        return 'Yearly';
      default:
        return basePlanId;
    }
  }

  static String _defaultDurationLabel(String basePlanId) {
    if (BillingConfig.isYearlyBasePlan(basePlanId)) {
      return 'Yearly';
    }
    return 'Monthly';
  }

  static String _recurringBillingPeriod(SubscriptionOfferDetailsWrapper offer) {
    if (offer.pricingPhases.isEmpty) {
      return '';
    }
    for (final phase in offer.pricingPhases) {
      if (phase.recurrenceMode == RecurrenceMode.infiniteRecurring ||
          phase.recurrenceMode == RecurrenceMode.finiteRecurring ||
          phase.recurrenceMode == RecurrenceMode.nonRecurring) {
        return phase.billingPeriod;
      }
    }
    return offer.pricingPhases.last.billingPeriod;
  }

  /// ISO 8601 billing period → readable duration (e.g. P1M → Monthly).
  static String formatBillingPeriod(String isoPeriod) {
    final match = RegExp(r'P(\d+)([DWMY])').firstMatch(isoPeriod);
    if (match == null) {
      return isoPeriod;
    }
    final count = int.parse(match.group(1)!);
    final unit = match.group(2)!;
    switch (unit) {
      case 'D':
        return count == 1 ? 'Daily' : 'Every $count days';
      case 'W':
        return count == 1 ? 'Weekly' : 'Every $count weeks';
      case 'M':
        return count == 1 ? 'Monthly' : 'Every $count months';
      case 'Y':
        return count == 1 ? 'Yearly' : 'Every $count years';
      default:
        return isoPeriod;
    }
  }

  /// Human-readable intro trial / promotional offer label for Play offers.
  static String? describeOffer(SubscriptionOfferDetailsWrapper offer) {
    if (offer.pricingPhases.length > 1) {
      final intro = offer.pricingPhases.first;
      final recurring = offer.pricingPhases.last;
      if (intro.priceAmountMicros == 0) {
        final trial = formatBillingPeriod(intro.billingPeriod);
        return 'Free $trial trial · then ${recurring.formattedPrice}';
      }
      return '${intro.formattedPrice} intro · then ${recurring.formattedPrice}';
    }
    if (offer.offerId != null) {
      return 'Special offer';
    }
    return null;
  }
}

/// Placeholder price strings shown before Play returns localized prices.
class PremiumFallbackPrices {
  PremiumFallbackPrices._();

  static const String monthly = r'$—/mo';
  static const String yearly = r'$—/yr';
}
