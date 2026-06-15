import '../models/precision.dart';

/// The result of one golden-ratio computation: the combined length and its two
/// golden segments, expressed as decimal inches.
class GrainResult {
  const GrainResult({required this.ab, required this.a, required this.b});

  /// Combined layout A + B.
  final double ab;

  /// Large (major) segment A.
  final double a;

  /// Small (minor) segment B.
  final double b;
}

/// Pure, stateless port of the calculator "backend" found in the HTML
/// `<script>` blocks. Nothing here touches Flutter — it can be unit tested in
/// isolation and is shared verbatim by the free and premium experiences.
///
/// The golden ratio relationships are:
///   * AB is the driver  → A = AB / φ,  B = AB − A
///   * A  is the driver  → AB = A · φ,  B = AB − A
///   * B  is the driver  → A = B · φ,   AB = A + B
class GrainCalculator {
  GrainCalculator._();

  /// φ — the golden ratio, identical to the `PHI` constant in the source.
  static const double phi = 1.618033988749895;

  /// Millimetres per inch, used by the MM precision engine.
  static const double mmPerInch = 25.4;

  // ---------------------------------------------------------------------------
  // parseToDecimal — convert a free-form imperial string into decimal inches.
  // A faithful translation of the JS `parseToDecimal`, including its handling
  // of feet (`'`), inch marks (`"`), whole + fraction (`10 1/2`) and bare
  // fractions (`3/8`).
  // ---------------------------------------------------------------------------
  static double parseToDecimal(String inputStr) {
    if (inputStr.isEmpty) return 0;
    double totalInches = 0;
    String workingStr = inputStr.trim().replaceAll('"', '');

    if (workingStr.contains("'")) {
      final feetParts = workingStr.split("'");
      final feet = _jsNum(feetParts[0], 0);
      totalInches += feet * 12;
      workingStr = feetParts.length > 1 ? feetParts[1].trim() : '';
    }
    if (workingStr.isEmpty) return totalInches;

    if (workingStr.contains(' ') || workingStr.contains('/')) {
      final parts = workingStr.split(RegExp(r'\s+'));
      double whole = 0;
      String fractionPart = '';

      if (parts.length == 2) {
        whole = _jsNum(parts[0], 0);
        fractionPart = parts[1];
      } else if (parts.length == 1) {
        if (parts[0].contains('/')) {
          fractionPart = parts[0];
        } else {
          return totalInches + _jsNum(parts[0], 0);
        }
      }

      if (fractionPart.contains('/')) {
        final ratio = fractionPart.split('/');
        final num = _jsNum(ratio[0], 0);
        final den = _jsNum(ratio.length > 1 ? ratio[1] : '', 1);
        totalInches += whole + (num / den);
        return totalInches;
      }
    }
    return totalInches + _jsNum(workingStr, 0);
  }

  // ---------------------------------------------------------------------------
  // formatToFraction — render decimal inches as an imperial fraction string,
  // rounded to the given precision. Mirrors the JS `formatToFraction`,
  // including feet roll-up, GCD reduction and the MM branch.
  // ---------------------------------------------------------------------------
  static String formatToFraction(double decimalVal, Precision precision) {
    if (decimalVal.isNaN || decimalVal <= 0) return '';

    if (precision.isMm) {
      final mmVal = _jsRound(decimalVal * mmPerInch);
      return '$mmVal mm';
    }

    final denominator = precision.denominator!;
    final double totalInches = _jsRound(decimalVal * denominator) / denominator;
    final int feet = (totalInches / 12).floor();
    final double inchesRemainder = totalInches % 12;

    int wholeInches = inchesRemainder.floor();
    final double fractionRemainder = inchesRemainder - wholeInches;
    int fractionNumerator = _jsRound(fractionRemainder * denominator);

    if (fractionNumerator == denominator) {
      wholeInches += 1;
      fractionNumerator = 0;
    }

    String result = '';
    if (feet > 0) result += "$feet'";

    if (wholeInches > 0 || fractionNumerator > 0 || feet == 0) {
      if (fractionNumerator == 0) {
        result += '$wholeInches"';
      } else {
        final int commonDivisor = _gcd(fractionNumerator, denominator);
        final int finalNum = fractionNumerator ~/ commonDivisor;
        final int finalDen = denominator ~/ commonDivisor;

        if (wholeInches > 0) {
          result += '$wholeInches $finalNum/$finalDen"';
        } else {
          result += '$finalNum/$finalDen"';
        }
      }
    }
    return result;
  }

  /// Apply the golden-ratio relationship for the active [driver] (`'ab'`,
  /// `'a'` or `'b'`) given its value in decimal inches.
  static GrainResult calculate(String driver, double decimalInches) {
    double valAB;
    double valA;
    double valB;

    if (driver == 'ab') {
      valAB = decimalInches;
      valA = valAB / phi;
      valB = valAB - valA;
    } else if (driver == 'a') {
      valA = decimalInches;
      valAB = valA * phi;
      valB = valAB - valA;
    } else {
      valB = decimalInches;
      valA = valB * phi;
      valAB = valA + valB;
    }
    return GrainResult(ab: valAB, a: valA, b: valB);
  }

  /// Decimal-inch subtext exactly as the HTML renders it: `value.toFixed(4)"`.
  static String decimalLabel(double value) => '${value.toStringAsFixed(4)}"';

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Public, faithful equivalent of the JS idiom `parseFloat(str) || fallback`,
  /// shared by the controller for raw millimetre buffers.
  static double parseFloatOr(String str, double fallback) =>
      _jsNum(str, fallback);

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  /// JS `Math.round`: rounds half **up** (toward +∞). All inputs here are
  /// non-negative, where this coincides with Dart's `round()`, but we keep the
  /// explicit floor(x + 0.5) form to be unambiguous.
  static int _jsRound(double x) => (x + 0.5).floor();

  /// Emulates the JS idiom `parseFloat(str) || fallback`.
  ///
  /// `parseFloat` reads the leading numeric portion of a string and ignores
  /// trailing garbage (e.g. `parseFloat("10abc") === 10`). The `|| fallback`
  /// then substitutes the fallback for the *falsy* results `NaN` **and** `0`.
  static double _jsNum(String str, double fallback) {
    final v = _parseFloat(str);
    if (v.isNaN || v == 0) return fallback;
    return v;
  }

  /// Faithful subset of JavaScript's `parseFloat`.
  static double _parseFloat(String str) {
    final s = str.trim();
    final match =
        RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?').firstMatch(s);
    if (match == null) return double.nan;
    var token = match.group(0)!;
    // `double.parse` rejects a trailing '.' ("5.") that JS parseFloat reads as
    // 5 — strip it so typing "5" then "." behaves identically to the source.
    if (token.endsWith('.')) token = token.substring(0, token.length - 1);
    return double.tryParse(token) ?? double.nan;
  }
}
