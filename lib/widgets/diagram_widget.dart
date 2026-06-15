import 'package:flutter/material.dart';

import '../models/precision.dart';
import '../theme/app_theme.dart';

/// The decorative golden-ratio diagram: an "AB" dimension line above two
/// hatched blocks split 61.8% / 38.2% (1/φ and 1 − 1/φ).
///
/// The dimension line now doubles as a **ruler whose graduations change with
/// the selected precision** — 16 / 32 / 64 subdivisions for the fraction tabs,
/// and a metric scale for MM — with a small metallic precision badge.
class DiagramWidget extends StatelessWidget {
  const DiagramWidget({super.key, required this.precision});

  final Precision precision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold10),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // --- Dimension line / ruler with centered AB label ---
              SizedBox(
                height: 24,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RulerPainter(precision),
                      ),
                    ),
                    // The label sits on the line with a panel-coloured chip
                    // that "cuts" the line behind it.
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
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
          // --- Precision badge (reflects the active tab) ---
          Positioned(
            top: 0,
            right: 0,
            child: _PrecisionBadge(precision: precision),
          ),
        ],
      ),
    );
  }
}

class _PrecisionBadge extends StatelessWidget {
  const _PrecisionBadge({required this.precision});

  final Precision precision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold25),
      ),
      child: ShaderMask(
        shaderCallback: (rect) => AppGradients.goldMetallic.createShader(rect),
        blendMode: BlendMode.srcIn,
        child: Text(
          precision.isMm ? 'MM' : precision.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.0,
          ),
        ),
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

/// Draws the dimension line plus graduation ticks whose density reflects the
/// active [Precision]: 16 / 32 / 64 subdivisions, or a metric scale for MM.
class _RulerPainter extends CustomPainter {
  _RulerPainter(this.precision);

  final Precision precision;

  static const double _lineY = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;

    // Main dimension line.
    canvas.drawLine(
      const Offset(0, _lineY),
      Offset(w, _lineY),
      Paint()
        ..color = AppColors.gold60
        ..strokeWidth = 1,
    );

    // Decide subdivisions + which ones are "major"/"medium".
    final int divisions;
    final int majorStep;
    final int medStep;
    if (precision.isMm) {
      divisions = 20; // metric feel
      majorStep = 5; // taller tick every 5
      medStep = 0;
    } else {
      final int d = precision.denominator!; // 16 / 32 / 64
      divisions = d;
      majorStep = d ~/ 4; // quarter points
      medStep = d ~/ 8; // eighth points
    }

    final Paint majorPaint = Paint()
      ..color = AppColors.goldPrimary
      ..strokeWidth = 1;
    final Paint minorPaint = Paint()
      ..color = AppColors.gold60
      ..strokeWidth = 1;

    for (int i = 0; i <= divisions; i++) {
      final double x = (i / divisions) * w;
      final double dx = x.clamp(0.5, w - 0.5);

      final bool isExtent = i == 0 || i == divisions;
      double height;
      Paint paint;
      if (isExtent) {
        height = 11;
        paint = majorPaint;
      } else if (i % majorStep == 0) {
        height = 8;
        paint = majorPaint;
      } else if (medStep > 0 && i % medStep == 0) {
        height = 6;
        paint = minorPaint;
      } else {
        height = 4;
        paint = minorPaint;
      }

      canvas.drawLine(
        Offset(dx, _lineY),
        Offset(dx, _lineY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.precision != precision;
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
