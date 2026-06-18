@Tags(['screenshots'])
library;

// Generates Play Store assets into android/fastlane/metadata/.../images.
// Skipped by normal `flutter test` (see dart_test.yaml). Regenerate with:
//   flutter test --run-skipped --tags screenshots --update-goldens
//
// Real fonts are loaded from the Flutter SDK so text renders (golden tests use
// a placeholder font by default). Paths target a from-source SDK; on a packaged
// SDK, point them at a Roboto .ttf you provide.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:golden_grain_calculator/app_scope.dart';
import 'package:golden_grain_calculator/screens/calculator_screen.dart';
import 'package:golden_grain_calculator/screens/upgrade_screen.dart';
import 'package:golden_grain_calculator/services/premium_service.dart';
import 'package:golden_grain_calculator/theme/app_theme.dart';

const String _img = '../android/fastlane/metadata/android/en-US/images';
final String _sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var any = false;
  for (final p in paths) {
    final f = File(p);
    if (f.existsSync()) {
      final Uint8List bytes = f.readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      any = true;
    }
  }
  if (any) await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFont('Roboto', [
    '$_sdk/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    '$_sdk/engine/src/flutter/txt/third_party/fonts/Roboto-Medium.ttf',
    // Fallback within the family so the 🔒 lock glyph renders.
    '$_sdk/engine/src/flutter/txt/third_party/fonts/NotoColorEmoji.ttf',
  ]);
  await _loadFont('MaterialIcons', [
    '$_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

ThemeData _theme() {
  final t = buildAppTheme();
  return t.copyWith(
    textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
}

Widget _app(PremiumService premium, Widget home) => AppScope(
      premium: premium,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: home,
      ),
    );

Future<PremiumService> _premium({bool pro = false}) async {
  SharedPreferences.setMockInitialValues(pro ? {'gg_is_premium': true} : {});
  final p = PremiumService();
  await p.init();
  return p;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 2.2;
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('1 — free calculator', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    final p = await _premium();
    await tester.pumpWidget(_app(p, const CalculatorScreen()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$_img/phoneScreenshots/1_free.png'));
  });

  testWidgets('2 — premium calculator', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    final p = await _premium(pro: true);
    await tester.pumpWidget(_app(p, const CalculatorScreen()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$_img/phoneScreenshots/2_premium.png'));
  });

  testWidgets('3 — navigation drawer', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    final p =
        await _premium(); // free tier: shows the upgrade CTA, no debug item
    await tester.pumpWidget(_app(p, const CalculatorScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$_img/phoneScreenshots/3_menu.png'));
  });

  testWidgets('4 — upgrade screen', (tester) async {
    _phone(tester);
    addTearDown(tester.view.reset);
    final p = await _premium();
    await tester.pumpWidget(_app(p, const UpgradeScreen()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$_img/phoneScreenshots/4_upgrade.png'));
  });

  testWidgets('feature graphic 1024x500', (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final banner = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.scaffold),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.panel,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.goldPrimary, width: 3),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.black50,
                        blurRadius: 40,
                        offset: Offset(0, 16)),
                    BoxShadow(
                        color: AppColors.goldGlow,
                        blurRadius: 50,
                        spreadRadius: -10),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (r) =>
                      AppGradients.goldMetallic.createShader(r),
                  blendMode: BlendMode.srcIn,
                  child: const Text(
                    'φ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 190,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 56),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) =>
                          AppGradients.goldMetallic.createShader(r),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'GOLDEN GRAIN',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          height: 1.05,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Golden ratio inch-fraction\nlayout calculator',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.textLight,
                        fontSize: 26,
                        height: 1.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(banner);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('$_img/featureGraphic.png'));
  });
}
