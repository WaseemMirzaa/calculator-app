import 'package:flutter/material.dart';

import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';
import 'diagram_widget.dart';
import 'io_row.dart';
import 'keypad.dart';
import 'precision_toggle.dart';

/// The calculator "card" — the panel that contains the header, diagram,
/// precision toggle, the three I/O rows and the keypad, laid out in the exact
/// order and 16px rhythm of the source `.calculator-container`.
class CalculatorCard extends StatelessWidget {
  const CalculatorCard({
    super.key,
    required this.controller,
    required this.isPremium,
    required this.onLocked,
  });

  final CalculatorController controller;
  final bool isPremium;

  /// Invoked when a locked control is tapped in the free tier.
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold15),
        boxShadow: const [
          BoxShadow(
            color: AppColors.black50,
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Header(),
              const SizedBox(height: 16),
              const DiagramWidget(),
              const SizedBox(height: 16),
              PrecisionToggle(
                controller: controller,
                isPremium: isPremium,
                onLocked: onLocked,
              ),
              const SizedBox(height: 16),
              // I/O group (12px internal gap).
              for (int i = 0; i < CalculatorController.rowIds.length; i++) ...[
                IoRow(
                  row: controller.rowView(CalculatorController.rowIds[i]),
                  onTap: () =>
                      controller.setActiveRow(CalculatorController.rowIds[i]),
                ),
                if (i < CalculatorController.rowIds.length - 1)
                  const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              Keypad(
                controller: controller,
                isPremium: isPremium,
                onLocked: onLocked,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'GOLDEN GRAIN CALCULATOR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.goldPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'inch fraction golden ratio tool',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
