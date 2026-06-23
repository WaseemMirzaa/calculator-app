import 'package:flutter/foundation.dart';

import '../logic/grain_calculator.dart';
import '../models/precision.dart';

/// Immutable view-model for a single input/output row, consumed by the UI.
class RowView {
  const RowView({
    required this.id,
    required this.label,
    required this.text,
    required this.isPlaceholder,
    required this.decimal,
    required this.isActive,
  });

  final String id; // 'ab' | 'a' | 'b'
  final String label;
  final String text; // big fraction / typed value
  final bool isPlaceholder; // dimmed gold-bright styling
  final String decimal; // small "x.xxxx\"" subtext
  final bool isActive; // is this the active driver row
}

/// Holds all mutable calculator state and reproduces, line for line, the
/// behaviour of the HTML `<script>`: the three input buffers, the active
/// driver, the pure-placeholder flag and the precision mode.
///
/// The same controller powers both tiers — the free tier simply never calls
/// [setPrecision] with a locked value or presses the `mm` key (the UI gates
/// those and shows the upsell instead).
class CalculatorController extends ChangeNotifier {
  CalculatorController({Precision initialPrecision = Precision.p16})
      : _precision = initialPrecision {
    _recompute();
  }

  // Row identifiers in display order.
  static const List<String> rowIds = ['ab', 'a', 'b'];

  static const Map<String, String> _labels = {
    'ab': 'Combined Layout (A + B)',
    'a': 'Large Segment (A)',
    'b': 'Small Segment (B)',
  };

  // Default values shown before the user types anything (the HTML placeholders).
  static const Map<String, String> _placeholders = {
    'ab': '10 1/2',
    'a': '6 1/2"',
    'b': '4"',
  };

  // --- Mutable state (mirrors the JS globals) ---
  final Map<String, String> _userInputs = {'ab': '', 'a': '', 'b': ''};
  String _activeDriver = 'ab';
  Precision _precision;
  bool _isPurePlaceholder = true;

  // --- Derived render state, refreshed by _recompute() ---
  final Map<String, String> _displayText = {'ab': '', 'a': '', 'b': ''};
  final Map<String, bool> _isPlaceholder = {'ab': true, 'a': true, 'b': true};
  final Map<String, String> _decimal = {'ab': '', 'a': '', 'b': ''};

  // --- Public getters ---
  Precision get precision => _precision;
  String get activeDriver => _activeDriver;

  RowView rowView(String id) => RowView(
        id: id,
        label: _labels[id]!,
        text: _displayText[id]!,
        isPlaceholder: _isPlaceholder[id]!,
        decimal: _decimal[id]!,
        isActive: _activeDriver == id,
      );

  // ---------------------------------------------------------------------------
  // Key handling — faithful port of the premium `pressKey`. Note the source
  // sets the active display once here and then immediately overwrites it inside
  // processCalculation/updateRowField; we therefore only mutate the buffer and
  // recompute, which yields the exact same visible result.
  // ---------------------------------------------------------------------------
  void pressKey(String key) {
    // In MM mode the fraction/feet/inch/space keys are inert (a raw mm number
    // has no use for them) — consistent with the source's key gating.
    if (_precision.isMm &&
        (key == '/' || key == "'" || key == '"' || key == ' ')) {
      return;
    }

    _isPurePlaceholder = false;

    final String currentText = _userInputs[_activeDriver]!;

    if (key == 'backspace') {
      _userInputs[_activeDriver] = currentText.isEmpty
          ? ''
          : currentText.substring(0, currentText.length - 1);
    } else if (key == 'mm') {
      // Quick "interpret what I typed as millimetres" conversion. Only active
      // when the current precision is a fraction mode.
      if (!_precision.isMm) {
        final double mmVal = GrainCalculator.parseFloatOr(currentText, 0);
        final double convertedInches = mmVal / GrainCalculator.mmPerInch;
        _userInputs[_activeDriver] =
            GrainCalculator.formatToFraction(convertedInches, _precision)
                .replaceAll('"', '');
      }
    } else {
      _userInputs[_activeDriver] = currentText + key;
    }

    _recompute();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // setActiveRow — switch the driver and clear all buffers (matches the source,
  // which deliberately does NOT reset the pure-placeholder flag).
  // ---------------------------------------------------------------------------
  void setActiveRow(String source) {
    _activeDriver = source;
    _userInputs['ab'] = '';
    _userInputs['a'] = '';
    _userInputs['b'] = '';
    _isPurePlaceholder = false;
    _recompute();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // setPrecision — change the denominator/MM mode, converting the active buffer
  // between fraction and millimetre representations as the source does.
  // ---------------------------------------------------------------------------
  void setPrecision(Precision next) {
    final Precision old = _precision;
    _precision = next;

    final String active = _userInputs[_activeDriver]!;
    if (active.isNotEmpty) {
      if (old.isMm && !next.isMm) {
        final double parsedMM = GrainCalculator.parseFloatOr(active, 0);
        final double convertedInches = parsedMM / GrainCalculator.mmPerInch;
        _userInputs[_activeDriver] =
            GrainCalculator.formatToFraction(convertedInches, next)
                .replaceAll('"', '');
      } else if (!old.isMm && next.isMm) {
        final double parsedInches = GrainCalculator.parseToDecimal(active);
        _userInputs[_activeDriver] =
            ((parsedInches * GrainCalculator.mmPerInch) + 0.5)
                .floor()
                .toString();
      }
    }

    _recompute();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // _recompute — port of processCalculation() + updateRowField() for all rows.
  // ---------------------------------------------------------------------------
  void _recompute() {
    final String activeString = _userInputs[_activeDriver]!;
    double decimalInches;

    if (_precision.isMm) {
      final double rawMM = GrainCalculator.parseFloatOr(activeString, 0);
      final double calculatedInches = rawMM / GrainCalculator.mmPerInch;
      if (activeString.isEmpty && _isPurePlaceholder) {
        decimalInches =
            GrainCalculator.parseToDecimal(_placeholders[_activeDriver]!);
      } else {
        decimalInches = calculatedInches;
      }
    } else {
      if (activeString.isEmpty) {
        decimalInches = _isPurePlaceholder
            ? GrainCalculator.parseToDecimal(_placeholders[_activeDriver]!)
            : 0;
      } else {
        decimalInches = GrainCalculator.parseToDecimal(activeString);
      }
    }

    final GrainResult r =
        GrainCalculator.calculate(_activeDriver, decimalInches);

    _updateRowField('ab', r.ab, _activeDriver == 'ab');
    _updateRowField('a', r.a, _activeDriver == 'a');
    _updateRowField('b', r.b, _activeDriver == 'b');
  }

  void _updateRowField(String id, double value, bool isDriver) {
    final String formattedFraction =
        GrainCalculator.formatToFraction(value, _precision);

    if (_isPurePlaceholder) {
      _displayText[id] = formattedFraction;
      _isPlaceholder[id] = true;
    } else {
      _isPlaceholder[id] = false;
      if (isDriver) {
        if (_userInputs[id]!.isNotEmpty) {
          _displayText[id] = _userInputs[id]! + (_precision.isMm ? ' mm' : '');
        } else {
          _displayText[id] = _precision.isMm ? '0 mm' : '0"';
        }
      } else {
        _displayText[id] = formattedFraction.isNotEmpty
            ? formattedFraction
            : (_precision.isMm ? '0 mm' : '0"');
      }
    }
    _decimal[id] = GrainCalculator.decimalLabel(value);
  }
}
