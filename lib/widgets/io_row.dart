import 'package:flutter/material.dart';

import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';

/// One of the three tappable input/output rows (AB / A / B). Tapping it makes
/// that row the active driver, matching `.row-box` + `setActiveRow`.
class IoRow extends StatelessWidget {
  const IoRow({super.key, required this.row, required this.onTap});

  final RowView row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = row.isActive;

    // Color/weight resolution mirrors the CSS cascade:
    //  .is-placeholder           → gold-bright @50%, weight 500 (wins over all)
    //  :not(.active-input) value → gold-bright, weight 600
    //  .active-input value       → text-light, weight 600
    final Color valueColor = row.isPlaceholder
        ? AppColors.goldBright50
        : (active ? AppColors.textLight : AppColors.goldBright);
    final FontWeight valueWeight =
        row.isPlaceholder ? FontWeight.w500 : FontWeight.w600;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.black25 : AppColors.black15,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.gold40 : AppColors.white03,
          ),
          // Soft gold halo around the row you're driving.
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: AppColors.goldGlowSoft,
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              row.label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: active ? AppColors.goldPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  row.text,
                  style: TextStyle(
                    fontSize: 26,
                    height: 32 / 26, // CSS line-height: 32px
                    fontWeight: valueWeight,
                    color: valueColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              row.decimal,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
