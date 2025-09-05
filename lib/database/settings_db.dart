// lib/database/settings_db.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trackmate/data/settings.dart' as app_settings;

class SettingsDB {
  static const String tableName = 'settings';

  /// Migra e inizializza la tabella settings
  static Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY,
        locale TEXT NOT NULL,
        theme INTEGER NOT NULL
      )
    ''');

    // Verifica se esistono già impostazioni
    if (!await has(db)) {
      await _createDefaultSettings(db);
    } else {
      await load(db);
    }
  }

  /// Crea le impostazioni predefinite nel database
  static Future<void> _createDefaultSettings(Database db) async {
    final settings = app_settings.Settings.global;

    await db.insert(tableName, {
      'id': 0,
      'locale': _localeToString(settings.locale),
      'theme': settings.theme.index,
    });
  }

  /// Aggiorna le impostazioni nel database
  static Future<void> update(Database db) async {
    final settings = app_settings.Settings.global;

    await db.update(
      tableName,
      {
        'locale': _localeToString(settings.locale),
        'theme': settings.theme.index,
      },
      where: 'id = ?',
      whereArgs: [0],
    );
  }

  /// Verifica se esistono impostazioni nel database
  static Future<bool> has(Database db) async {
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [0],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Carica le impostazioni dal database
  static Future<void> load(Database db) async {
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [0],
      limit: 1,
    );

    if (results.isNotEmpty) {
      _applySettingsFromMap(results.first);
    }
  }

  /// Applica le impostazioni caricate dal database
  static void _applySettingsFromMap(Map<String, dynamic> map) {
    try {
      final settings = app_settings.Settings.global;

      // Carica locale
      final localeString = map['locale'] as String?;
      if (localeString != null && localeString.isNotEmpty) {
        final locale = _stringToLocale(localeString);
        if (locale != null) {
          settings.setLocale(locale);
        }
      }

      // Carica tema
      final themeIndex = map['theme'] as int?;
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        settings.setTheme(ThemeMode.values[themeIndex]);
      }
    } catch (e) {
      debugPrint('SettingsDB: Errore nel parsing delle impostazioni: $e');
      // In caso di errore, mantieni le impostazioni predefinite
    }
  }

  /// Converte Locale in String per il database
  static String _localeToString(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  /// Converte String in Locale dal database
  static Locale? _stringToLocale(String localeString) {
    try {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else if (parts.length == 1) {
        return Locale(parts[0]);
      }
    } catch (e) {
      debugPrint('SettingsDB: Errore nel parsing del locale: $e');
    }
    return null;
  }

  /// Elimina tutte le impostazioni (per reset)
  static Future<void> clear(Database db) async {
    await db.delete(tableName, where: 'id = ?', whereArgs: [0]);
  }

  /// Reset alle impostazioni predefinite
  static Future<void> resetToDefaults(Database db) async {
    await clear(db);
    await _createDefaultSettings(db);
  }
}
