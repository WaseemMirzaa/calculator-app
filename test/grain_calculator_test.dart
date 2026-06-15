import 'package:flutter_test/flutter_test.dart';
import 'package:golden_grain_calculator/logic/grain_calculator.dart';
import 'package:golden_grain_calculator/models/precision.dart';

void main() {
  group('parseToDecimal', () {
    test('whole + fraction with space (the AB placeholder)', () {
      expect(GrainCalculator.parseToDecimal('10 1/2'), 10.5);
    });

    test('whole + fraction with inch mark (the A placeholder)', () {
      expect(GrainCalculator.parseToDecimal('6 1/2"'), 6.5);
    });

    test('plain inches with inch mark (the B placeholder)', () {
      expect(GrainCalculator.parseToDecimal('4"'), 4.0);
    });

    test('bare fraction', () {
      expect(GrainCalculator.parseToDecimal('3/8'), 0.375);
    });

    test('feet then inches', () {
      expect(GrainCalculator.parseToDecimal("1'6\""), 18.0);
    });

    test('empty string is zero', () {
      expect(GrainCalculator.parseToDecimal(''), 0.0);
    });

    test('trailing dot behaves like JS parseFloat (5. == 5)', () {
      expect(GrainCalculator.parseToDecimal('5.'), 5.0);
    });
  });

  group('formatToFraction (fractions)', () {
    test('exact half at 1/16', () {
      expect(GrainCalculator.formatToFraction(10.5, Precision.p16), '10 1/2"');
    });

    test('reduces 8/16 to 1/2', () {
      expect(GrainCalculator.formatToFraction(6.5, Precision.p16), '6 1/2"');
    });

    test('whole inches only', () {
      expect(GrainCalculator.formatToFraction(4.0, Precision.p16), '4"');
    });

    test('sub-inch fraction reduces 6/16 to 3/8', () {
      expect(GrainCalculator.formatToFraction(0.375, Precision.p16), '3/8"');
    });

    test('rolls up to feet at exactly 12 inches', () {
      expect(GrainCalculator.formatToFraction(12.0, Precision.p16), "1'");
    });

    test('feet plus inches', () {
      expect(GrainCalculator.formatToFraction(18.0, Precision.p16), "1'6\"");
    });

    test('tighter denominator keeps 1/32', () {
      expect(
        GrainCalculator.formatToFraction(0.03125, Precision.p32),
        '1/32"',
      );
    });

    test('non-positive returns empty string', () {
      expect(GrainCalculator.formatToFraction(0, Precision.p16), '');
      expect(GrainCalculator.formatToFraction(-1, Precision.p16), '');
    });
  });

  group('formatToFraction (millimetres)', () {
    test('one inch is 25 mm (rounded)', () {
      expect(GrainCalculator.formatToFraction(1.0, Precision.mm), '25 mm');
    });

    test('converts and rounds decimal inches', () {
      // 4.010662" * 25.4 = 101.87 → 102 mm
      expect(
        GrainCalculator.formatToFraction(4.010662, Precision.mm),
        '102 mm',
      );
    });
  });

  group('golden ratio calculation', () {
    test('AB driver splits into A and B (default placeholder)', () {
      final r = GrainCalculator.calculate('ab', 10.5);
      expect(r.ab, 10.5);
      expect(r.a, closeTo(6.4893, 0.0005));
      expect(r.b, closeTo(4.0107, 0.0005));
      // A and B recombine to AB.
      expect(r.a + r.b, closeTo(r.ab, 1e-9));
    });

    test('A driver scales up to AB by phi', () {
      final r = GrainCalculator.calculate('a', 6.5);
      expect(r.a, 6.5);
      expect(r.ab, closeTo(6.5 * GrainCalculator.phi, 1e-9));
      expect(r.ab / r.a, closeTo(GrainCalculator.phi, 1e-9));
    });

    test('B driver: A is phi times B and AB is their sum', () {
      final r = GrainCalculator.calculate('b', 4.0);
      expect(r.b, 4.0);
      expect(r.a, closeTo(4.0 * GrainCalculator.phi, 1e-9));
      expect(r.ab, closeTo(r.a + r.b, 1e-9));
      // The major/minor ratio is the golden ratio.
      expect(r.a / r.b, closeTo(GrainCalculator.phi, 1e-9));
    });
  });

  group('decimal subtext', () {
    test('formats to four decimals with an inch mark', () {
      expect(GrainCalculator.decimalLabel(10.5), '10.5000"');
      expect(GrainCalculator.decimalLabel(6.489338), '6.4893"');
    });
  });
}
