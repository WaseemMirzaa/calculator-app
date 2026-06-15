import 'package:flutter_test/flutter_test.dart';
import 'package:golden_grain_calculator/controllers/calculator_controller.dart';
import 'package:golden_grain_calculator/models/precision.dart';

void main() {
  test('SPACE key lets you type a whole + fraction like "10 1/2"', () {
    final c = CalculatorController();
    addTearDown(c.dispose);

    for (final k in ['1', '0', ' ', '1', '/', '2']) {
      c.pressKey(k);
    }

    final ab = c.rowView('ab');
    expect(ab.text, '10 1/2'); // the space made it through
    expect(ab.decimal, '10.5000"'); // backend parsed it to 10.5"
    // The golden segment A = 10.5 / phi ≈ 6.4894" (matches the source HTML).
    expect(c.rowView('a').decimal, '6.4894"');
  });

  test('SPACE is ignored in MM mode (a raw mm number has no spaces)', () {
    final c = CalculatorController(initialPrecision: Precision.mm);
    addTearDown(c.dispose);

    for (final k in ['1', '0', '0', ' ']) {
      c.pressKey(k);
    }

    expect(c.rowView('ab').text, '100 mm'); // the trailing space did nothing
  });

  test('MM mode reports the golden segments in millimetres', () {
    final c = CalculatorController(initialPrecision: Precision.mm);
    addTearDown(c.dispose);

    for (final k in ['1', '0', '0']) {
      c.pressKey(k);
    }

    expect(c.rowView('ab').text, '100 mm');
    expect(c.rowView('a').text, endsWith('mm'));
    expect(c.rowView('b').text, endsWith('mm'));
  });

  test('changing precision keeps the driver value, reformatted', () {
    final c = CalculatorController();
    addTearDown(c.dispose);

    c.pressKey('8'); // AB = 8"
    expect(c.rowView('ab').decimal, '8.0000"');

    c.setPrecision(Precision.p64);
    expect(c.precision, Precision.p64);
    // A = 8 / phi ≈ 4.9443" regardless of precision.
    expect(c.rowView('a').decimal, '4.9443"');
  });
}
