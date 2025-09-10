import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmate/locale/supported_locales.dart';

class LocaleManager extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';

  Locale _currentLocale = SupportedLocales.fallbackLocale;

  Locale get currentLocale => _currentLocale;

  List<Locale> get supportedLocales => SupportedLocales.supportedLocales;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('${_localeKey}_language');
    final countryCode = prefs.getString('${_localeKey}_country');

    if (languageCode != null) {
      final locale = Locale(languageCode, countryCode ?? '');
      if (SupportedLocales.isSupported(locale)) {
        _currentLocale = locale;
        notifyListeners();
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!SupportedLocales.isSupported(locale)) {
      locale = SupportedLocales.fallbackLocale;
    }

    _currentLocale = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_localeKey}_language', locale.languageCode);
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      await prefs.setString('${_localeKey}_country', locale.countryCode!);
    }

    notifyListeners();
  }

  String getLanguageDisplayName(Locale locale) {
    return SupportedLocales.getDisplayName(locale);
  }
}
