/*
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/settings_db.dart';
import 'package:trackmate/locale/locales.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../themes.dart';

/// Singleton class to store the application settings
class Settings extends ChangeNotifier {
  /// Global settings object
  static Settings global = Settings();

  /// Locale of the application
  String get locale {
    return Locales.code;
  }

  set locale(String value) {
    Locales.code = value;
    update();
  }

  /// Theme to use in the application
  ThemeMode get theme {
    return Themes.mode;
  }

  set theme(ThemeMode value) {
    Themes.mode = value;
    update();
  }

  /// Update settings on database and notify listeners for changes.
  ///
  /// Called after any parameter in the settings object has been changed.
  void update() async {
    Database? db = await DataBase.get();
    await SettingsDB.update(db!);
    notifyListeners();
  }
}
*/

// lib/data/settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/settings_db.dart';
import 'package:trackmate/locale/supported_locales.dart';

class Settings extends ChangeNotifier {
  static Settings? _instance;
  static Settings get global => _instance ??= Settings._();

  Settings._();

  // Private backing fields
  Locale _locale = SupportedLocales.fallbackLocale;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  // Public getters
  Locale get locale => _locale;
  ThemeMode get theme => _themeMode;
  bool get isInitialized => _isInitialized;

  // Locale getter that returns display name
  String get localeDisplayName => SupportedLocales.getDisplayName(_locale);

  /// Initialize settings by loading from persistence
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadFromPersistence();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Settings: Error initializing settings: $e');
      // Use defaults on error
      _isInitialized = true;
    }
  }

  /// Change locale with validation and persistence
  Future<void> setLocale(Locale newLocale) async {
    // Validate locale is supported
    if (!SupportedLocales.isSupported(newLocale)) {
      debugPrint('Settings: Unsupported locale $newLocale, using fallback');
      newLocale = SupportedLocales.fallbackLocale;
    }

    if (_locale == newLocale) return;

    _locale = newLocale;
    await _persistLocale();
    await _updateDatabase();
    notifyListeners();
  }

  /// Change theme with persistence
  Future<void> setTheme(ThemeMode newTheme) async {
    if (_themeMode == newTheme) return;

    _themeMode = newTheme;
    await _persistTheme();
    await _updateDatabase();
    notifyListeners();
  }

  /// Set both locale and theme in one operation
  Future<void> setBoth({Locale? locale, ThemeMode? theme}) async {
    bool hasChanges = false;

    if (locale != null && locale != _locale && SupportedLocales.isSupported(locale)) {
      _locale = locale;
      hasChanges = true;
    }

    if (theme != null && theme != _themeMode) {
      _themeMode = theme;
      hasChanges = true;
    }

    if (hasChanges) {
      await _persistAll();
      await _updateDatabase();
      notifyListeners();
    }
  }

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _locale = SupportedLocales.fallbackLocale;
    _themeMode = ThemeMode.system;

    await _persistAll();
    await _updateDatabase();
    notifyListeners();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadFromPersistence() async {
    final prefs = await SharedPreferences.getInstance();

    // Load locale
    final localeString = prefs.getString('settings_locale');
    if (localeString != null) {
      try {
        final parts = localeString.split('_');
        final locale = Locale(
            parts[0],
            parts.length > 1 ? parts[1] : null
        );
        if (SupportedLocales.isSupported(locale)) {
          _locale = locale;
        }
      } catch (e) {
        debugPrint('Settings: Error parsing locale $localeString: $e');
      }
    }

    // Load theme
    final themeIndex = prefs.getInt('settings_theme');
    if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
  }

  /// Persist locale to SharedPreferences
  Future<void> _persistLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = _locale.countryCode != null
          ? '${_locale.languageCode}_${_locale.countryCode}'
          : _locale.languageCode;
      await prefs.setString('settings_locale', localeString);
    } catch (e) {
      debugPrint('Settings: Error persisting locale: $e');
    }
  }

  /// Persist theme to SharedPreferences
  Future<void> _persistTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('settings_theme', _themeMode.index);
    } catch (e) {
      debugPrint('Settings: Error persisting theme: $e');
    }
  }

  /// Persist all settings
  Future<void> _persistAll() async {
    await Future.wait([
      _persistLocale(),
      _persistTheme(),
    ]);
  }

  /// Update settings in database (legacy support)
  Future<void> _updateDatabase() async {
    try {
      final db = await DataBase.get();
      if (db != null) {
        await SettingsDB.update(db);
      }
    } catch (e) {
      debugPrint('Settings: Error updating database: $e');
    }
  }

  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get all supported locales
  List<Locale> get supportedLocales => SupportedLocales.supportedLocales;

  /// Get all theme modes
  List<ThemeMode> get supportedThemes => ThemeMode.values;

  /// Check if locale is current
  bool isCurrentLocale(Locale locale) => _locale == locale;

  /// Check if theme is current
  bool isCurrentTheme(ThemeMode theme) => _themeMode == theme;

  @override
  String toString() {
    return 'Settings(locale: $_locale, theme: $_themeMode, initialized: $_isInitialized)';
  }
}
