import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/premium_service.dart';
import '../theme/app_theme.dart';

/// Full-screen upgrade / purchase experience reachable from the menu and from
/// the in-calculator upsell. Reflects the current entitlement live.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _busy = false;

  Future<void> _buy(PremiumService premium) async {
    setState(() => _busy = true);
    await premium.purchase();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('Premium unlocked — enjoy Pro Precision!');
  }

  Future<void> _restore(PremiumService premium) async {
    setState(() => _busy = true);
    final restored = await premium.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(restored
        ? 'Purchase restored.'
        : 'No previous purchase found on this device.');
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

  @override
  Widget build(BuildContext context) {
    final premium = AppScope.of(context);
    final bool isPremium = premium.isPremium;

    return DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.goldPrimary,
            title: const Text(
              'Pro Precision',
              style: TextStyle(
                color: AppColors.goldPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPremium
                            ? AppColors.gold40
                            : AppColors.goldPrimary,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black50,
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          isPremium ? Icons.workspace_premium : Icons.lock_open,
                          color: AppColors.goldBright,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPremium
                              ? 'Pro Precision Active'
                              : 'Unlock Pro Precision',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.goldBright,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPremium
                              ? 'Thank you for your support. All precision modes and '
                                  'the millimeter engine are unlocked on this device.'
                              : 'Upgrade for a one-time payment of '
                                  '${PremiumService.price} to access expert framing '
                                  '& millwork layouts:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _FeatureRow('1/32" Tighter Precision Toggle'),
                        const _FeatureRow('1/64" Extreme Precision Toggle'),
                        const _FeatureRow(
                            'Full Millimeter (MM) Conversion Engine'),
                        const _FeatureRow(
                            'One-time purchase — no subscription'),
                        const SizedBox(height: 24),
                        if (!isPremium) ...[
                          DecoratedBox(
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
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _busy ? null : () => _buy(premium),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: AppColors.actionTextOnGold,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.actionTextOnGold,
                                        ),
                                      )
                                    : const Text(
                                        'Upgrade Now - ${PremiumService.price}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy ? null : () => _restore(premium),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                            ),
                            child: const Text('Restore Purchase'),
                          ),
                        ] else
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bgKey,
                                foregroundColor: AppColors.goldBright,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Back to Calculator',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.goldPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
