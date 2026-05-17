import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper around [SharedPreferences] for lightweight local data.
class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage({required SharedPreferences prefs}) : _prefs = prefs;

  // ── Keys ──
  static const _themeModeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _onboardingCompleteKey = 'onboarding_complete';

  // ── Theme ──
  Future<bool> saveThemeMode(String mode) =>
      _prefs.setString(_themeModeKey, mode);

  String getThemeMode() => _prefs.getString(_themeModeKey) ?? 'light';

  // ── Locale ──
  Future<bool> saveLocale(String locale) =>
      _prefs.setString(_localeKey, locale);

  String getLocale() => _prefs.getString(_localeKey) ?? 'en';

  // ── Onboarding ──
  Future<bool> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingCompleteKey, value);

  bool isOnboardingComplete() =>
      _prefs.getBool(_onboardingCompleteKey) ?? false;
}
