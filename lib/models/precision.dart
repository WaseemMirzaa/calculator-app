/// The four precision modes exposed by the calculator's top toggle bar.
///
/// In the source HTML these are the literal values `16`, `32`, `64` and the
/// string `'MM'`. We model them as an enum and recover the numeric
/// denominator / display label through the helpers below.
enum Precision {
  p16,
  p32,
  p64,
  mm;

  /// `true` for the millimetre mode, which is handled specially everywhere a
  /// fraction denominator would otherwise be used.
  bool get isMm => this == Precision.mm;

  /// The fraction denominator (16 / 32 / 64). `null` for [Precision.mm].
  int? get denominator {
    switch (this) {
      case Precision.p16:
        return 16;
      case Precision.p32:
        return 32;
      case Precision.p64:
        return 64;
      case Precision.mm:
        return null;
    }
  }

  /// Label shown on the toggle button — matches the HTML button text.
  String get label {
    switch (this) {
      case Precision.p16:
        return '1/16';
      case Precision.p32:
        return '1/32';
      case Precision.p64:
        return '1/64';
      case Precision.mm:
        return 'MM';
    }
  }

  /// In the free tier only 1/16 is unlocked; the others open the upsell modal.
  bool get isFreeTier => this == Precision.p16;
}
