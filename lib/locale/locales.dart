// lib/locale/locales.dart
import 'package:flutter/material.dart';
import 'package:trackmate/locale/app_localizations.dart';

class Locales {
  static String get(String key, BuildContext context, {List<String>? args}) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return '***$key***';
    }
    return args != null
        ? localizations.getString(key, args: args)
        : localizations.get(key);
  }

  // ✅ USA AppLocalizations.supportedLocales
  static List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  static bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }
}
