import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/calculator_controller.dart';
import '../theme/app_theme.dart';

/// The 4×4 keypad. In the free tier the bottom-right `mm` key is locked and
/// opens the upsell; every other key is fully functional in both tiers.
class Keypad extends StatelessWidget {
  const Keypad({
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
    // Logical key rows matching the HTML keypad order.
    final List<List<_KeySpec>> rows = [
      [
        _KeySpec.digit('7'),
        _KeySpec.digit('8'),
        _KeySpec.digit('9'),
        _KeySpec.action('Delete', 'backspace'),
      ],
      [
        _KeySpec.digit('4'),
        _KeySpec.digit('5'),
        _KeySpec.digit('6'),
        _KeySpec.digit('/'),
      ],
      [
        _KeySpec.digit('1'),
        _KeySpec.digit('2'),
        _KeySpec.digit('3'),
        _KeySpec.digit('.'),
      ],
      [
        _KeySpec.digit("'"),
        _KeySpec.digit('0'),
        _KeySpec.digit('"'),
        isPremium
            ? _KeySpec.action('mm', 'mm', color: AppColors.goldBright)
            : _KeySpec.locked('mm'),
      ],
    ];

    // Full-width SPACE bar (lets you type e.g. "10 1/2"); inert in MM mode.
    final spaceSpec = _KeySpec.space();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.black20,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white02),
      ),
      child: Column(
        children: [
          for (int r = 0; r < rows.length; r++) ...[
            Row(
              children: [
                for (int c = 0; c < rows[r].length; c++) ...[
                  Expanded(
                    child: _KeyButton(
                      spec: rows[r][c],
                      onTap: () => _handle(rows[r][c]),
                    ),
                  ),
                  if (c < rows[r].length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            if (r < rows.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _KeyButton(
                  spec: spaceSpec,
                  onTap: () => _handle(spaceSpec),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handle(_KeySpec spec) {
    if (spec.isLocked) {
      onLocked();
      return;
    }
    HapticFeedback.selectionClick();
    controller.pressKey(spec.keyValue!);
  }
}

/// Describes a single key: its caption, the value sent to [CalculatorController]
/// and how it should be styled.
class _KeySpec {
  const _KeySpec({
    required this.label,
    required this.keyValue,
    required this.isAction,
    required this.isLocked,
    this.color,
  });

  factory _KeySpec.digit(String v) =>
      _KeySpec(label: v, keyValue: v, isAction: false, isLocked: false);

  factory _KeySpec.action(String label, String v, {Color? color}) => _KeySpec(
        label: label,
        keyValue: v,
        isAction: true,
        isLocked: false,
        color: color,
      );

  factory _KeySpec.locked(String label) => _KeySpec(
        label: label,
        keyValue: null,
        isAction: true,
        isLocked: true,
        color: AppColors.lockedKeyText,
      );

  factory _KeySpec.space() => const _KeySpec(
        label: 'SPACE',
        keyValue: ' ',
        isAction: false,
        isLocked: false,
      );

  final String label;
  final String? keyValue;
  final bool isAction;
  final bool isLocked;
  final Color? color;

  bool get isSpace => keyValue == ' ';
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({required this.spec, required this.onTap});

  final _KeySpec spec;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;

    // Action keys use the gold caption, smaller uppercased text
    // (CSS `.action-key { text-transform: uppercase; }`).
    final Color textColor = spec.color ??
        (spec.isAction ? AppColors.goldPrimary : AppColors.textLight);
    final String base = spec.isAction ? spec.label.toUpperCase() : spec.label;
    final String caption = spec.isLocked ? '$base \u{1F512}' : base; // 🔒

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: Opacity(
        opacity: spec.isLocked ? 0.6 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _pressed ? AppGradients.keyPressed : AppGradients.key,
            borderRadius: BorderRadius.circular(8),
            // Faint top rim-light for a moulded, tactile key.
            border: Border.all(color: AppColors.white05),
            boxShadow: _pressed
                ? null
                : const [
                    BoxShadow(
                      color: AppColors.black30,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            caption,
            style: TextStyle(
              fontSize: spec.isSpace ? 13 : (spec.isAction ? 16 : 20),
              fontWeight: FontWeight.w600,
              color: spec.isSpace ? AppColors.textMuted : textColor,
              letterSpacing: spec.isSpace ? 4 : (spec.isAction ? 0.5 : 0),
            ),
          ),
        ),
      ),
    );
  }
}
