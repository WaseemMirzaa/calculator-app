import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:golden_grain_calculator/main.dart';
import 'package:golden_grain_calculator/services/premium_service.dart';

/// Boots the app and advances past the splash screen's timer + fade.
Future<PremiumService> _boot(WidgetTester tester,
    {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final premium = PremiumService();
  await premium.init();
  await tester.pumpWidget(GoldenGrainApp(premium: premium));
  await tester.pump(const Duration(seconds: 3)); // fire the splash timer
  await tester.pumpAndSettle(); // finish the route transition
  return premium;
}

void main() {
  testWidgets('boots to splash, then shows the free-tier calculator',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final premium = PremiumService();
    await premium.init();

    await tester.pumpWidget(GoldenGrainApp(premium: premium));

    // The splash screen is shown first.
    expect(find.text('GOLDEN GRAIN'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // The calculator is now visible in its free configuration.
    expect(find.text('GOLDEN GRAIN CALCULATOR'), findsOneWidget);
    expect(find.text('FREE'), findsOneWidget);
    // The three input/output rows are present (labels are uppercased in the UI).
    expect(find.text('COMBINED LAYOUT (A + B)'), findsOneWidget);
    expect(find.text('LARGE SEGMENT (A)'), findsOneWidget);
    expect(find.text('SMALL SEGMENT (B)'), findsOneWidget);
    // A locked premium precision toggle is shown.
    expect(find.textContaining('1/32'), findsOneWidget);
  });

  testWidgets('typing on the keypad drives the golden-ratio calculation',
      (tester) async {
    await _boot(tester);

    // Type "8" into the active (AB) row.
    await tester.ensureVisible(find.text('8'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8'));
    await tester.pump();

    // AB = 8" → A = 8 / phi ≈ 4.9443", surfaced in the decimal subtexts.
    expect(find.text('8.0000"'), findsOneWidget);
    expect(find.text('4.9443"'), findsOneWidget);
  });

  testWidgets('tapping a locked toggle opens the upsell modal', (tester) async {
    await _boot(tester);

    expect(find.text('Unlock Pro Precision'), findsNothing);

    await tester.ensureVisible(find.textContaining('1/32'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('1/32'));
    await tester.pumpAndSettle();

    // The free-tier upsell overlay appears with its exact heading + CTA.
    expect(find.text('Unlock Pro Precision'), findsOneWidget);
    expect(find.text('Upgrade Now - \$3.99'), findsOneWidget);
  });

  testWidgets('premium tier shows the PRO badge', (tester) async {
    await _boot(tester, prefs: {'gg_is_premium': true});
    expect(find.text('PRO'), findsOneWidget);
    expect(find.text('FREE'), findsNothing);
  });
}
