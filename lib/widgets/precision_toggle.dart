import 'package:flutter/material.dart';

import '../controllers/calculator_controller.dart';
import '../models/precision.dart';
import '../theme/app_theme.dart';

/// The `1/16 · 1/32 · 1/64 · MM` segmented control.
///
/// In the free tier every option except `1/16` is locked: tapping it fires
/// [onLocked] (which opens the upsell) instead of changing precision.
class PrecisionToggle extends StatelessWidget {
  const PrecisionToggle({
    super.key,
    required this.controller,
    required this.isPremium,
    required this.onLocked,
  });

  final CalculatorController controller;
  final bool isPremium;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.black25,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white05),
      ),
      child: Row(
        children: [
          for (final p in Precision.values)
            Expanded(
              child: _ToggleButton(
                label: p.label,
                isActive: controller.precision == p,
                isLocked: !isPremium && !p.isFreeTier,
                onTap: () {
                  if (!isPremium && !p.isFreeTier) {
                    onLocked();
                  } else {
                    controller.setPrecision(p);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isActive
        ? AppColors.actionTextOnGold
        : (isLocked ? AppColors.lockedToggleText : AppColors.textMuted);

    final Widget content = Text(
      isLocked ? '$label \u{1F512}' : label, // 🔒
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: content,
        ),
      ),
    );
  }
}
