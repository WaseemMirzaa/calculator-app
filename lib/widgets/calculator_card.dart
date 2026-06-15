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
        gradient: AppGradients.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold25),
        boxShadow: const [
          // Deep ambient drop shadow for elevation…
          BoxShadow(
            color: AppColors.black50,
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
          // …plus a faint gold halo so the panel feels lit from within.
          BoxShadow(
            color: AppColors.goldGlowSoft,
            blurRadius: 28,
            spreadRadius: -8,
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
              DiagramWidget(precision: controller.precision),
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
    return Column(
      children: [
        // Metallic-gold sheen on the title via a gradient shader.
        ShaderMask(
          shaderCallback: (rect) =>
              AppGradients.goldMetallic.createShader(rect),
          blendMode: BlendMode.srcIn,
          child: const Text(
            'GOLDEN GRAIN CALCULATOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const _HeaderFlourish(),
        const SizedBox(height: 7),
        const Text(
          'inch fraction golden ratio tool',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// A slim gold rule with a center diamond — a refined divider under the title.
class _HeaderFlourish extends StatelessWidget {
  const _HeaderFlourish();

  static const Color _fadedGold = Color(0x00D4AF37); // transparent gold

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_fadedGold, AppColors.goldPrimary],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Transform.rotate(
            angle: 0.7853981633974483, // 45° → diamond
            child: Container(width: 5, height: 5, color: AppColors.goldBright),
          ),
        ),
        Container(
          width: 32,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.goldPrimary, _fadedGold],
            ),
          ),
        ),
      ],
    );
  }
}
