import 'package:flutter/material.dart';

/// Centralised palette + typography ported 1:1 from the HTML `:root` variables
/// and CSS rules. Every translucent value below is the exact `rgba()` from the
/// source stylesheet, precomputed as an ARGB constant (alpha = round(op*255))
/// so we never depend on the deprecated `Color.withOpacity`.
class AppColors {
  AppColors._();

  // --- Solid theme tokens (CSS :root) ---
  static const Color bgDarkWood = Color(0xFF14261C); // --bg-dark-wood
  static const Color bgPanel = Color(0xFF1B3326); // --bg-panel
  static const Color goldPrimary = Color(0xFFD4AF37); // --gold-primary
  static const Color goldBright = Color(0xFFF3E5AB); // --gold-bright
  static const Color textLight = Color(0xFFE8ECE9); // --text-light
  static const Color textMuted = Color(0xFF8AA093); // --text-muted
  static const Color bgKey = Color(0xFF254433); // --bg-key
  static const Color bgKeyActive = Color(0xFF2F5440); // --bg-key-active
  static const Color lockColor = Color(0xFFA34848); // --lock-color

  // --- Misc literals used inline in the CSS ---
  static const Color actionTextOnGold =
      Color(0xFF111111); // active toggle / upgrade btn text
  static const Color lockedToggleText =
      Color(0xFFFF9999); // locked toggle .locked color
  static const Color lockedKeyText =
      Color(0xFF4E6355); // locked mm key inline color

  // --- Gold (D4AF37) translucent variants ---
  static const Color gold05 = Color(0x0DD4AF37);
  static const Color gold10 = Color(0x1AD4AF37);
  static const Color gold15 = Color(0x26D4AF37);
  static const Color gold40 = Color(0x66D4AF37);
  static const Color gold60 = Color(0x99D4AF37);

  // --- Gold-bright (F3E5AB) translucent variant ---
  static const Color goldBright50 = Color(0x80F3E5AB); // placeholder text

  // --- Muted (8AA093) translucent variants (block B hatch + border) ---
  static const Color muted05 = Color(0x0D8AA093);
  static const Color muted15 = Color(0x268AA093);
  static const Color muted30 = Color(0x4D8AA093);

  // --- Black translucent variants ---
  static const Color black15 = Color(0x26000000);
  static const Color black20 = Color(0x33000000);
  static const Color black25 = Color(0x40000000);
  static const Color black30 = Color(0x4D000000);
  static const Color black50 = Color(0x80000000);

  // --- White translucent variants (subtle hairline borders) ---
  static const Color white02 = Color(0x05FFFFFF);
  static const Color white03 = Color(0x08FFFFFF);
  static const Color white05 = Color(0x0DFFFFFF);

  // --- Overlay used by the free-version upsell modal: rgba(20,38,28,0.95) ---
  static const Color modalScrim = Color(0xF214261C);

  // --- Premium finish tokens (subtle gradients + glow; not in the original
  //     CSS, added to give the layout a richer, more luxurious feel) ---
  static const Color goldDeep =
      Color(0xFFB8902F); // darker end of the gold sheen
  static const Color goldHighlight =
      Color(0xFFFBF3CE); // brightest gold catch-light
  static const Color panelLight = Color(0xFF21402F); // card gradient — top
  static const Color panelDark = Color(0xFF152A1F); // card gradient — bottom
  static const Color woodTop = Color(0xFF182D21); // scaffold gradient — top
  static const Color woodDeep =
      Color(0xFF0F1D15); // scaffold gradient — bottom/vignette
  static const Color keyLight = Color(0xFF2B4E3A); // key gradient — top
  static const Color keyDark = Color(0xFF20392B); // key gradient — bottom
  static const Color keyActiveDark = Color(0xFF274A37); // pressed key — bottom
  static const Color gold25 = Color(0x40D4AF37); // soft gold border
  static const Color goldGlow = Color(0x4DD4AF37); // gold glow shadow (0.30)
  static const Color goldGlowSoft =
      Color(0x26D4AF37); // fainter gold glow (0.15)
}

/// Reusable gradients + shadow recipes for the premium finish.
class AppGradients {
  AppGradients._();

  /// Metallic gold sheen for headings (used via [ShaderMask]).
  static const LinearGradient goldMetallic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.goldHighlight,
      AppColors.goldPrimary,
      AppColors.goldDeep,
      AppColors.goldPrimary,
    ],
    stops: [0.0, 0.45, 0.75, 1.0],
  );

  /// Vertical gold sheen for primary buttons / the active toggle.
  static const LinearGradient goldButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.goldHighlight,
      AppColors.goldPrimary,
      AppColors.goldDeep
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Subtle top-lit gradient for the calculator panel.
  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.panelLight, AppColors.bgPanel, AppColors.panelDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// Background vignette behind the card.
  static const LinearGradient scaffold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.woodTop, AppColors.bgDarkWood, AppColors.woodDeep],
    stops: [0.0, 0.45, 1.0],
  );

  /// Tactile, slightly domed gradient for keypad keys.
  static const LinearGradient key = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.keyLight, AppColors.bgKey, AppColors.keyDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// Pressed-key gradient.
  static const LinearGradient keyPressed = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bgKeyActive, AppColors.keyActiveDark],
  );
}

/// Builds the global [ThemeData]. The visual surfaces below are intentionally
/// driven by explicit colors in each widget so the layout matches the HTML
/// exactly; this theme mainly sets sane dark defaults for system chrome.
ThemeData buildAppTheme() {
  const base = ColorScheme.dark(
    primary: AppColors.goldPrimary,
    secondary: AppColors.goldBright,
    surface: AppColors.bgPanel,
    onPrimary: AppColors.actionTextOnGold,
    onSurface: AppColors.textLight,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.bgDarkWood,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    // -apple-system / Segoe UI / Roboto stack → let the platform pick its
    // default sans-serif (Roboto on Android, San Francisco on iOS).
    fontFamily: null,
  );
}
