import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the single piece of cross-screen state: whether the user has unlocked
/// the premium ("Pro Precision") package.
///
/// The unlock is persisted with [SharedPreferences] so it survives restarts.
/// The actual money movement is mocked here behind [purchase] / [restore];
/// wire those to Google Play Billing / StoreKit (e.g. the `in_app_purchase`
/// package) for production — the rest of the app already reacts to the flag.
class PremiumService extends ChangeNotifier {
  static const String _prefsKey = 'gg_is_premium';

  /// One-time unlock price, surfaced in the upsell copy.
  static const String price = r'$3.99';

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// Loads the persisted flag. Safe to call before `runApp`.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      // Storage unavailable (e.g. first run / restricted platform): default free.
      _isPremium = false;
    }
    notifyListeners();
  }

  /// Mock purchase flow. In production this is where you would launch the
  /// platform billing sheet and only flip the flag on a verified purchase.
  Future<void> purchase() async {
    // Simulate a short round-trip to the store.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await _setPremium(true);
  }

  /// Mock "restore purchases": re-reads the persisted entitlement. In
  /// production, query the store for previously owned products instead.
  Future<bool> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      // ignore — keep current value
    }
    notifyListeners();
    return _isPremium;
  }

  /// Debug-only helper to drop back to the free tier so both layouts can be
  /// exercised on a single install.
  Future<void> resetToFree() => _setPremium(false);

  Future<void> _setPremium(bool value) async {
    _isPremium = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // ignore persistence failures; in-memory state still updates
    }
    notifyListeners();
  }
}
