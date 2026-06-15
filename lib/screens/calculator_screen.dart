import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
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
            iconTheme: const IconThemeData(color: AppColors.goldPrimary),
            title: _TierBadge(isPremium: isPremium),
          ),
          drawer: AppDrawer(
            isPremium: isPremium,
            onUpgrade: () => _onMenu(_MenuAction.upgrade),
            onRestore: () => _onMenu(_MenuAction.restore),
            onPrivacy: () => _onMenu(_MenuAction.privacy),
            onTerms: () => _onMenu(_MenuAction.terms),
            onResetFree: (kDebugMode && isPremium)
                ? () => _onMenu(_MenuAction.resetFree)
                : null,
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
    // PRO: a premium gold-gradient pill with a soft glow + dark text.
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: AppGradients.goldButton,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.goldGlow,
              blurRadius: 12,
              spreadRadius: -2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium,
                size: 15, color: AppColors.actionTextOnGold),
            SizedBox(width: 6),
            Text(
              'PRO',
              style: TextStyle(
                color: AppColors.actionTextOnGold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // FREE: a subtle muted outline pill.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
          SizedBox(width: 6),
          Text(
            'FREE',
            style: TextStyle(
              color: AppColors.textMuted,
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
