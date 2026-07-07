import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/app_feature.dart';
import '../models/purchase_result.dart';
import '../models/subscription_plan.dart';
import '../services/billing_config.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

/// Google Play–compliant subscription paywall and management screen.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _selectedBasePlanId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final premium = AppScope.of(context);
    final isPremium = premium.isPremium;
    final plans = premium.plans;
    _selectedBasePlanId ??=
        premium.activeBasePlanId ?? BillingConfig.defaultBasePlanId;

    final SubscriptionPlan? selectedPlan = plans.isEmpty
        ? null
        : plans.firstWhere(
            (plan) => plan.basePlanId == _selectedBasePlanId,
            orElse: () => plans.first,
          );

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.scaffold),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.goldPrimary,
          title: Text(
            isPremium ? 'Your Subscription' : 'Pro Precision',
            style: const TextStyle(
              color: AppColors.goldPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.goldPrimary,
            onRefresh: premium.refreshProducts,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(isPremium: isPremium),
                      const SizedBox(height: 12),
                      if (premium.loadingProducts)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                          ),
                        ),
                      if (premium.productsError != null) ...[
                        Text(
                          premium.productsError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.lockColor,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: premium.refreshProducts,
                          child: const Text('Retry loading plans'),
                        ),
                      ],
                      if (premium.lastBillingError != null)
                        Text(
                          premium.lastBillingError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.lockColor,
                            fontSize: 12,
                          ),
                        ),
                      if (!isPremium) ...[
                        const _SectionTitle('Choose a plan'),
                        const SizedBox(height: 6),
                        if (plans.isEmpty && !premium.loadingProducts)
                          Text(
                            premium.productsError ??
                                'Loading prices from Google Play…',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: premium.productsError != null
                                  ? AppColors.lockColor
                                  : AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        for (final plan in plans)
                          _PlanTile(
                            plan: plan,
                            selected: plan.basePlanId == _selectedBasePlanId,
                            compact: true,
                            onTap: () => setState(
                              () => _selectedBasePlanId = plan.basePlanId,
                            ),
                          ),
                        if (selectedPlan != null) ...[
                          const SizedBox(height: 8),
                          _SubscribeButton(
                            busy: _busy,
                            label: selectedPlan.subscribeLabel,
                            onPressed: (premium.loadingProducts ||
                                    !selectedPlan.isFromStore)
                                ? null
                                : () => _subscribe(premium, selectedPlan),
                          ),
                        ],
                        const SizedBox(height: 14),
                      ] else ...[
                        if (premium.activePlan != null)
                          _ActivePlanCard(
                            plan: premium.activePlan!,
                            compact: true,
                          ),
                        ..._upgradeSection(premium, plans),
                        const SizedBox(height: 14),
                      ],
                      const _SectionTitle('What you get'),
                      const SizedBox(height: 6),
                      _FeatureComparison(isPremium: isPremium, compact: true),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy ? null : () => _restore(premium),
                        child: const Text('Restore purchases'),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _openManageSubscriptions(premium),
                        child: Text(
                          isPremium
                              ? 'Manage or cancel subscription'
                              : 'Manage subscriptions in Google Play',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const _LegalDisclosure(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TermsScreen(),
                              ),
                            ),
                            child: const Text('Terms of Service'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const PrivacyScreen(),
                              ),
                            ),
                            child: const Text('Privacy Policy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _upgradeSection(
    PremiumService premium,
    List<SubscriptionPlan> plans,
  ) {
    if (premium.activeBasePlanId == BillingConfig.yearlyBasePlanId) {
      return const [];
    }
    final yearly = plans.where(
      (plan) => plan.basePlanId == BillingConfig.yearlyBasePlanId,
    );
    if (yearly.isEmpty) {
      return const [];
    }
    final plan = yearly.first;
    return [
      const SizedBox(height: 8),
      const _SectionTitle('Upgrade plan'),
      const SizedBox(height: 6),
      _PlanTile(
        plan: plan,
        selected: true,
        compact: true,
        onTap: () {},
      ),
      const SizedBox(height: 8),
      _SubscribeButton(
        busy: _busy,
        label: 'Switch to yearly — ${plan.price}',
        onPressed: () => _subscribe(premium, plan),
      ),
    ];
  }

  Future<void> _subscribe(PremiumService premium, SubscriptionPlan plan) async {
    setState(() => _busy = true);
    final result = await premium.purchasePlan(plan);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case PurchaseLaunched():
        if (premium.isPremium) {
          _toast('Pro Precision is active — thank you!');
        }
      case PurchaseFailed(:final message):
        _toast(message);
    }
  }

  Future<void> _restore(PremiumService premium) async {
    setState(() => _busy = true);
    final restored = await premium.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(restored
        ? 'Subscription restored.'
        : 'No active subscription found on this account.');
  }

  Future<void> _openManageSubscriptions(PremiumService premium) async {
    final opened = await premium.openSubscriptionManagement();
    if (!mounted) return;
    if (!opened) {
      _toast('Could not open subscription settings.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.bgKey,
        ),
      );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold40, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium,
              color: AppColors.goldBright,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pro Precision Active',
                    style: const TextStyle(
                      color: AppColors.goldBright,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'All precision modes unlocked',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldPrimary, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_open, color: AppColors.goldBright, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Unlock tighter fractions and full metric conversion.',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.goldPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FeatureComparison extends StatelessWidget {
  const _FeatureComparison({
    required this.isPremium,
    this.compact = false,
  });

  final bool isPremium;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold25),
      ),
      child: Column(
        children: [
          for (final item in FeatureAccess.catalog)
            _FeatureRow(
              title: item.title,
              subtitle: compact ? null : item.subtitle,
              unlocked: item.isUnlocked(isPremium: isPremium),
              compact: compact,
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final bool unlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 8),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            color: unlocked ? AppColors.goldPrimary : AppColors.textMuted,
            size: compact ? 16 : 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: subtitle == null
                ? Text(
                    title,
                    style: TextStyle(
                      color:
                          unlocked ? AppColors.textLight : AppColors.textMuted,
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: unlocked
                              ? AppColors.textLight
                              : AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!compact)
            Text(
              unlocked ? 'Unlocked' : 'Locked',
              style: TextStyle(
                color: unlocked ? AppColors.goldBright : AppColors.lockColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isYearly = BillingConfig.isYearlyBasePlan(plan.basePlanId);
    final padding = compact ? 10.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold10 : AppColors.black20,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.goldPrimary : AppColors.gold25,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppColors.goldPrimary,
                size: compact ? 20 : 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.title,
                          style: TextStyle(
                            color: AppColors.goldBright,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isYearly) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold25,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Best value',
                              style: TextStyle(
                                color: AppColors.goldBright,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.pricePerDuration} · ${plan.durationLabel}',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (plan.offerLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plan.offerLabel!,
                        style: const TextStyle(
                          color: AppColors.goldBright,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({required this.plan, this.compact = false});

  final SubscriptionPlan plan;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.goldButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? 'Current plan' : 'CURRENT PLAN',
                  style: TextStyle(
                    color: AppColors.actionTextOnGold,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: compact ? 0.5 : 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${plan.title} · ${plan.pricePerDuration}',
                  style: TextStyle(
                    color: AppColors.actionTextOnGold,
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.goldButton,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.goldGlow,
            blurRadius: 18,
            spreadRadius: -2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: AppColors.actionTextOnGold,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: busy
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.actionTextOnGold,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _LegalDisclosure extends StatelessWidget {
  const _LegalDisclosure();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Payment is charged to your Google Play account at confirmation. '
      'Subscriptions automatically renew unless canceled at least 24 hours '
      'before the end of the current period. Manage or cancel anytime in '
      'Google Play → Payments & subscriptions.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        height: 1.45,
      ),
    );
  }
}
