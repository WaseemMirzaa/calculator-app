import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The decorative golden-ratio diagram: an "AB" dimension line above two
/// hatched blocks split 61.8% / 38.2% (1/φ and 1 − 1/φ), exactly as the HTML
/// `.diagram-container` renders it.
class DiagramWidget extends StatelessWidget {
  const DiagramWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold10),
      ),
      child: Column(
        children: [
          // --- Dimension line with centered AB label ---
          SizedBox(
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 16),
                  painter: _DimensionLinePainter(),
                ),
                // The label sits on the line with a panel-coloured chip that
                // "cuts" the line behind it (CSS background-color: --bg-panel).
                Container(
                  color: AppColors.bgPanel,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'AB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldBright,
                      letterSpacing: 1,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // --- The two hatched blocks ---
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const SizedBox(
              height: 38,
              child: Row(
                children: [
                  // Block A — 61.8%, gold 45° hatch.
                  Expanded(
                    flex: 618,
                    child: _HatchBlock(
                      base: AppColors.gold05,
                      stripe: AppColors.gold15,
                      positiveSlope: true,
                      border: Border(
                        top: BorderSide(color: AppColors.gold40),
                        left: BorderSide(color: AppColors.gold40),
                        bottom: BorderSide(color: AppColors.gold40),
                        right: BorderSide(color: AppColors.gold60),
                      ),
                      label: 'A',
                      labelColor: AppColors.textLight,
                    ),
                  ),
                  // Block B — 38.2%, muted -45° hatch (no left border).
                  Expanded(
                    flex: 382,
                    child: _HatchBlock(
                      base: AppColors.muted05,
                      stripe: AppColors.muted15,
                      positiveSlope: false,
                      border: Border(
                        top: BorderSide(color: AppColors.muted30),
                        right: BorderSide(color: AppColors.muted30),
                        bottom: BorderSide(color: AppColors.muted30),
                      ),
                      label: 'B',
                      labelColor: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HatchBlock extends StatelessWidget {
  const _HatchBlock({
    required this.base,
    required this.stripe,
    required this.positiveSlope,
    required this.border,
    required this.label,
    required this.labelColor,
  });

  final Color base;
  final Color stripe;
  final bool positiveSlope;
  final Border border;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: border),
      child: CustomPaint(
        painter: _StripePainter(
          base: base,
          stripe: stripe,
          positiveSlope: positiveSlope,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the full-width gold dimension line (60% opacity) with a solid tick at
/// each end, reproducing `.diagram-line` and its `::before` / `::after`.
class _DimensionLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cy = size.height / 2;

    final linePaint = Paint()
      ..color = AppColors.gold60
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);

    final tickPaint = Paint()
      ..color = AppColors.goldPrimary
      ..strokeWidth = 1;
    // Ticks are 9px tall, sitting from 4px above to 5px below the line
    // (CSS `::before/::after { top: -4px; height: 9px; }`).
    canvas.drawLine(Offset(0.5, cy - 4), Offset(0.5, cy + 5), tickPaint);
    canvas.drawLine(
      Offset(size.width - 0.5, cy - 4),
      Offset(size.width - 0.5, cy + 5),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Approximates a CSS `repeating-linear-gradient(±45deg, …)`: fills with [base]
/// then draws 4px-wide diagonal [stripe] bands on an 8px pitch.
class _StripePainter extends CustomPainter {
  _StripePainter({
    required this.base,
    required this.stripe,
    required this.positiveSlope,
  });

  final Color base;
  final Color stripe;
  final bool positiveSlope;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);

    canvas.drawRect(rect, Paint()..color = base);

    final stripePaint = Paint()
      ..color = stripe
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double pitch = 8; // 4px band + 4px gap
    final double h = size.height;
    // Sweep diagonal lines across the whole rect (offset by ±h to cover edges).
    for (double d = -h; d < size.width + h; d += pitch) {
      if (positiveSlope) {
        canvas.drawLine(Offset(d, 0), Offset(d + h, h), stripePaint);
      } else {
        canvas.drawLine(Offset(d, h), Offset(d + h, 0), stripePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) =>
      base != oldDelegate.base ||
      stripe != oldDelegate.stripe ||
      positiveSlope != oldDelegate.positiveSlope;
}
