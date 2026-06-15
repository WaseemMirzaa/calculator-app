import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/calculator_card.dart';
import '../widgets/upsell_modal.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';
import 'upgrade_screen.dart';

/// The home screen. A single adaptive layout serves both tiers — the only
/// difference is whether the premium controls are locked — so upgrading
/// unlocks the calculator live, without a rebuild of a different screen.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

enum _MenuAction { upgrade, restore, privacy, terms, resetFree }

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorController _controller = CalculatorController();

  bool _showUpsell = false;
  bool _purchasing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openUpsell() => setState(() => _showUpsell = true);
  void _closeUpsell() => setState(() => _showUpsell = false);

  Future<void> _purchaseFromModal() async {
    final premium = AppScope.of(context);
    setState(() => _purchasing = true);
    await premium.purchase();
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      _showUpsell = false;
    });
    _toast('Premium unlocked — enjoy Pro Precision!');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.bgKey),
      );
  }

  Future<void> _onMenu(_MenuAction action) async {
    final premium = AppScope.of(context);
    switch (action) {
      case _MenuAction.upgrade:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const UpgradeScreen()),
        );
        break;
      case _MenuAction.restore:
        final restored = await premium.restore();
        if (!mounted) return;
        _toast(restored
            ? 'Purchase restored.'
            : 'No previous purchase found on this device.');
        break;
      case _MenuAction.privacy:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
        );
        break;
      case _MenuAction.terms:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TermsScreen()),
        );
        break;
      case _MenuAction.resetFree:
        await premium.resetToFree();
        if (!mounted) return;
        _toast('Switched back to the free tier.');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Depends on AppScope → rebuilds when the premium flag flips.
    final premium = AppScope.of(context);
    final bool isPremium = premium.isPremium;

    return DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: _TierBadge(isPremium: isPremium),
            actions: [
              PopupMenuButton<_MenuAction>(
                icon: const Icon(Icons.more_vert, color: AppColors.goldPrimary),
                color: AppColors.bgPanel,
                onSelected: _onMenu,
                itemBuilder: (context) => [
                  if (!isPremium)
                    const PopupMenuItem(
                      value: _MenuAction.upgrade,
                      child: _MenuTile(
                          Icons.workspace_premium, 'Upgrade to Premium'),
                    )
                  else
                    const PopupMenuItem(
                      enabled: false,
                      child: _MenuTile(Icons.check_circle, 'Premium Active'),
                    ),
                  const PopupMenuItem(
                    value: _MenuAction.restore,
                    child: _MenuTile(Icons.restore, 'Restore Purchase'),
                  ),
                  const PopupMenuItem(
                    value: _MenuAction.privacy,
                    child:
                        _MenuTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
                  ),
                  const PopupMenuItem(
                    value: _MenuAction.terms,
                    child: _MenuTile(
                        Icons.description_outlined, 'Terms of Service'),
                  ),
                  // Debug-only: lets a tester flip back to the free layout.
                  if (kDebugMode && isPremium)
                    const PopupMenuItem(
                      value: _MenuAction.resetFree,
                      child: _MenuTile(
                          Icons.bug_report_outlined, 'Switch to Free (debug)'),
                    ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: CalculatorCard(
                        controller: _controller,
                        isPremium: isPremium,
                        onLocked: _openUpsell,
                      ),
                    ),
                  ),
                ),
              ),
              // Cover the whole screen so the upsell reads like the HTML overlay.
              if (_showUpsell)
                UpsellModal(
                  busy: _purchasing,
                  onUpgrade: _purchaseFromModal,
                  onClose: _closeUpsell,
                ),
            ],
          ),
        ));
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.isPremium});
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final Color color = isPremium ? AppColors.goldPrimary : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.lock_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'PRO' : 'FREE',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.goldBright),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textLight)),
      ],
    );
  }
}
