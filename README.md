# Golden Grain Calculator

[![CI](https://github.com/WaseemMirzaa/calculator-app/actions/workflows/ci.yml/badge.svg)](https://github.com/WaseemMirzaa/calculator-app/actions/workflows/ci.yml)

A Flutter port of the **Golden Grain Calculator** — an inch-fraction golden-ratio
layout tool for woodworking, framing and millwork. It ships in two tiers from a
single codebase:

| Tier | Precision | MM engine |
| --- | --- | --- |
| **Free** | `1/16` only | locked (upsell) |
| **Premium** ("Pro Precision") | `1/16`, `1/32`, `1/64` | full millimetre conversion |

The UI is a 1:1 reproduction of the supplied HTML/CSS layouts (same palette,
spacing, diagram, keypad and modal), and the calculation engine is a faithful
port of the original JavaScript.

## Screens

- **Splash** — branded launch screen, fades into the calculator.
- **Calculator** — the main tool. One adaptive layout serves both tiers; locks
  fall away the instant premium is unlocked.
- **Upgrade** — full-screen purchase page (also reachable from the in-calculator
  upsell modal shown when a free user taps a locked control).
- **Privacy Policy** / **Terms of Service** — reached from the in-app menu (the
  `⋮` button in the top bar).

## Running it

The Android / iOS / web platform folders are committed, so it runs out of the box:

```bash
flutter pub get
flutter run        # on a connected device / emulator / browser
```

Requires Flutter `>=3.10` (Dart `>=3.0`). Developed and verified on Flutter `3.44.2`.

### Tests & static analysis

```bash
flutter test       # engine unit tests + widget smoke tests
flutter analyze    # static analysis (flutter_lints)
```

## Continuous integration & the APK

GitHub Actions handles verification and packaging — see [`.github/workflows`](.github/workflows):

- **`ci.yml`** — on every push / PR to `main`: `dart format` check, `flutter analyze`,
  `flutter test`, then builds the **release APK** and uploads it as a build
  artifact (`golden-grain-calculator-release-apk`).
- **`release.yml`** — when a `v*` tag is pushed (e.g. `git tag v1.0.0 && git push --tags`):
  builds the release **APK + AAB** and publishes them to a **GitHub Release**.

**Getting the APK**

- **From CI:** open the latest green run of the *CI* workflow → download the
  `golden-grain-calculator-release-apk` artifact.
- **From a release:** push a `v*` tag and grab the `.apk` attached to the
  generated GitHub Release.
- **Locally:** `flutter build apk --release` →
  `build/app/outputs/flutter-apk/app-release.apk`
  (needs the Android SDK and access to Google's Maven repository).

### Play Store (beta)

`playstore-beta.yml` builds a **signed AAB** and uploads it — with the store
listing, changelog and screenshots — to a Google Play track via Fastlane.
Release signing reads `android/key.properties` (created in CI from secrets;
absent locally → debug signing). Full setup, required secrets and asset
regeneration are documented in **[PLAYSTORE.md](PLAYSTORE.md)**.

> The release build is signed with the debug key so it installs for testing.
> Before publishing to the Play Store, add a real keystore + `signingConfig`
> in `android/app/build.gradle.kts`.

## Architecture

```
lib/
├── main.dart                       App entry; loads premium flag, builds AppScope + MaterialApp
├── app_scope.dart                  InheritedNotifier exposing PremiumService to the tree
├── theme/app_theme.dart            Exact palette (CSS rgba precomputed as ARGB) + ThemeData
├── models/precision.dart           Precision enum: 1/16 · 1/32 · 1/64 · MM
├── logic/grain_calculator.dart     PURE engine — no Flutter imports, fully unit-tested
├── controllers/calculator_controller.dart   ChangeNotifier; ports the stateful JS 1:1
├── services/premium_service.dart   Mock IAP + persistence (real-billing hook documented)
├── widgets/
│   ├── calculator_card.dart        Composes header → diagram → toggle → rows → keypad
│   ├── diagram_widget.dart         AB dimension line + 61.8/38.2 hatched blocks (CustomPainters)
│   ├── precision_toggle.dart       Segmented precision control (locks in free tier)
│   ├── io_row.dart                 The three input/output rows
│   ├── keypad.dart                 4×4 keypad with faithful press feedback
│   └── upsell_modal.dart           Free-tier overlay (exact copy/styling)
└── screens/
    ├── splash_screen.dart
    ├── calculator_screen.dart      Adaptive free/premium + menu + upsell overlay
    ├── upgrade_screen.dart
    ├── legal_page.dart             Shared scaffold for long-form content
    ├── privacy_screen.dart
    └── terms_screen.dart
```

### The calculation engine

`GrainCalculator` is pure Dart (no Flutter dependency) so it is trivially
testable. It mirrors the original script:

- **`parseToDecimal`** — turns free-form imperial input (`10 1/2`, `6 1/2"`,
  `1'6"`, `3/8`) into decimal inches, reproducing JavaScript `parseFloat`
  semantics (leading-number parsing, the `|| fallback` quirk, and `"5." == 5`).
- **`formatToFraction`** — renders decimal inches back to a reduced fraction at
  the chosen denominator, rolling up to feet, or to whole millimetres in MM mode.
- **`calculate`** — applies the golden ratio (φ ≈ 1.618):
  - AB drives → `A = AB / φ`, `B = AB − A`
  - A drives → `AB = A · φ`, `B = AB − A`
  - B drives → `A = B · φ`, `AB = A + B`

`CalculatorController` holds the three input buffers, the active driver, the
"pure placeholder" flag and the precision mode, reproducing `pressKey`,
`setActiveRow`, `setPrecision` and the MM conversions exactly.

## Premium / In-App Purchase

`PremiumService` persists a single unlock flag via `shared_preferences`. The
`purchase()` and `restore()` methods are **mocked** (they simulate a successful
store round-trip). To ship for real, replace their bodies with a billing
integration (e.g. the [`in_app_purchase`](https://pub.dev/packages/in_app_purchase)
package) and only flip the flag on a verified purchase — every screen already
reacts to `isPremium`.

For convenience while testing, debug builds expose a "Switch to Free (debug)"
menu item so both layouts can be exercised on one install.

## Notes on layout fidelity

- All colours are the exact values from the CSS `:root` block; every translucent
  `rgba()` is precomputed as an ARGB constant.
- The golden-ratio diagram's diagonal hatching is drawn with a `CustomPainter`
  approximating the CSS `repeating-linear-gradient`.
- The only addition beyond the original card is a minimal transparent top bar
  (tier badge + `⋮` menu) so Privacy/Terms/Upgrade are reachable; the calculator
  card itself is unchanged.
