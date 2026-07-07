import 'precision.dart';

/// Premium-gated capabilities exposed by Golden Grain Calculator.
enum AppFeature {
  precision16,
  precision32,
  precision64,
  millimeterConversion,
  premiumTheme,
}

/// User-facing label and lock state for subscription comparison UI.
class FeatureItem {
  const FeatureItem({
    required this.feature,
    required this.title,
    required this.subtitle,
  });

  final AppFeature feature;
  final String title;
  final String subtitle;

  bool isUnlocked({required bool isPremium}) =>
      FeatureAccess.isUnlocked(feature, isPremium: isPremium);
}

/// Central rules for which features are free vs Pro Precision subscribers.
class FeatureAccess {
  FeatureAccess._();

  static const List<FeatureItem> catalog = [
    FeatureItem(
      feature: AppFeature.precision16,
      title: '1/16" precision',
      subtitle: 'Standard fraction layout mode',
    ),
    FeatureItem(
      feature: AppFeature.precision32,
      title: '1/32" precision',
      subtitle: 'Tighter framing & millwork layouts',
    ),
    FeatureItem(
      feature: AppFeature.precision64,
      title: '1/64" precision',
      subtitle: 'Extreme fine woodworking precision',
    ),
    FeatureItem(
      feature: AppFeature.millimeterConversion,
      title: 'Millimeter (MM) engine',
      subtitle: 'Full metric conversion on every row',
    ),
    FeatureItem(
      feature: AppFeature.premiumTheme,
      title: 'Pro Precision theme',
      subtitle: 'Gold PRO badge and unlocked controls',
    ),
  ];

  static bool isUnlocked(AppFeature feature, {required bool isPremium}) {
    switch (feature) {
      case AppFeature.precision16:
        return true;
      case AppFeature.precision32:
      case AppFeature.precision64:
      case AppFeature.millimeterConversion:
      case AppFeature.premiumTheme:
        return isPremium;
    }
  }

  static bool isPrecisionUnlocked(
    Precision precision, {
    required bool isPremium,
  }) {
    if (precision.isFreeTier) {
      return true;
    }
    return isPremium;
  }
}
