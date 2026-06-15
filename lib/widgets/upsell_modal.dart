import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../theme/app_theme.dart';

/// Full-card overlay shown when a free-tier user taps a locked control.
/// Mirrors `.modal-overlay` / `.modal-content` from the free HTML, including
/// the exact heading, body copy, feature list and button labels.
class UpsellModal extends StatelessWidget {
  const UpsellModal({
    super.key,
    required this.onUpgrade,
    required this.onClose,
    this.busy = false,
  });

  /// Called when "Upgrade Now" is tapped (runs the purchase flow).
  final VoidCallback onUpgrade;

  /// Called when "Keep Free Version" is tapped.
  final VoidCallback onClose;

  /// When true the upgrade button shows a spinner and inputs are disabled.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        // CSS overlay: rgba(20,38,28,0.95) with the card's 16px radius.
        color: AppColors.modalScrim,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldPrimary, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.black50,
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Unlock Pro Precision',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.goldBright,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textLight,
                    ),
                    children: [
                      TextSpan(
                        text: 'Upgrade to the premium package for a one-time '
                            'payment of ',
                      ),
                      TextSpan(
                        text: PremiumService.price,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' to access expert framing & millwork layouts:',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bullet('1/32" Tighter Precision Toggle'),
                      _Bullet('1/64" Extreme Precision Toggle'),
                      _Bullet('Full Millimeter (MM) Conversion Engine'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.actionTextOnGold,
                      disabledBackgroundColor: AppColors.gold40,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: busy ? null : onClose,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Keep Free Version',
                    style: TextStyle(
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '• $text',
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}
