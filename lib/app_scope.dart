import 'package:flutter/widgets.dart';

import 'services/premium_service.dart';

/// Exposes the app-wide [PremiumService] to the widget tree without pulling in
/// a third-party state-management dependency.
///
/// Because it is an [InheritedNotifier], any widget that reads it via
/// [AppScope.of] automatically rebuilds when the premium flag changes (e.g.
/// right after a purchase), so the calculator's locks fall away live.
class AppScope extends InheritedNotifier<PremiumService> {
  const AppScope({
    super.key,
    required PremiumService premium,
    required super.child,
  }) : super(notifier: premium);

  static PremiumService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree');
    return scope!.notifier!;
  }
}
