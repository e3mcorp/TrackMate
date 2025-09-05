// lib/locale/supported_locales.dart
import 'package:flutter/material.dart';

class SupportedLocales {
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (United States)
    Locale('it', 'IT'), // Italian (Italy)
    Locale('pt', 'PT'), // Portuguese (Portugal)
  ];

  static const Locale fallbackLocale = Locale('en', 'US');

  static final Map<String, String> languageNames = {
    'en': 'English',
    'it': 'Italiano',
    'pt': 'Português',
  };

  static final Map<String, String> countryNames = {
    'US': 'United States',
    'IT': 'Italia',
    'PT': 'Portugal',
  };

  static String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode.toUpperCase();
  }

  static String getDisplayName(Locale locale) {
    final language = getLanguageName(locale.languageCode);
    final country = countryNames[locale.countryCode];
    return country != null ? '$language ($country)' : language;
  }

  static bool isSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) =>
    supportedLocale.languageCode == locale.languageCode &&
        supportedLocale.countryCode == locale.countryCode);
  }

  static Locale resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return fallbackLocale;

    // Exact match (language + country)
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    // Language match only
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return fallbackLocale;
  }
}
