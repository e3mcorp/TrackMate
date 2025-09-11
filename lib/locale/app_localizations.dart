// lib/locale/app_localizations.dart

import 'package:flutter/material.dart';
import 'package:trackmate/locale/locales_en.dart';
import 'package:trackmate/locale/locales_it.dart';
import 'package:trackmate/locale/locales_pt.dart';

class AppLocalizations {
  final Locale locale;
  final Map _localizedStrings;

  AppLocalizations._(this.locale, this._localizedStrings);

  /// Lista delle lingue supportate dall'app
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (United States)
    Locale('it', 'IT'), // Italian (Italy)
    Locale('pt', 'PT'), // Portuguese (Portugal)
  ];

  /// Delegate per la localizzazione
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  /// Ottieni l'istanza di AppLocalizations dal context
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Carica le traduzioni per la lingua specificata
  static Future<AppLocalizations> load(Locale locale) async {
    final Map<String, String> localizedStrings;

    switch (locale.languageCode) {
      case 'it':
        localizedStrings = LocalesIT.strings;
        break;
      case 'pt':
        localizedStrings = LocalesPT.strings;
        break;
      case 'en':
      default:
        localizedStrings = LocalesEN.strings;
        break;
    }

    return AppLocalizations._(locale, localizedStrings);
  }

  /// Ottieni una traduzione per chiave
  String get(String key) {
    return _localizedStrings[key] ?? '***$key***';
  }

  /// Ottieni una traduzione con parametri sostituibili
  String getString(String key, {List<String>? args}) {
    String value = get(key);
    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value.replaceAll('{$i}', args[i]);
      }
    }
    return value;
  }

  // Getter di convenienza per stringhe comuni
  String get appTitle => get('carTracker');
  String get welcome => get('welcome');
  String get settings => get('settings');
  String get back => get('back');
  String get next => get('next');
  String get complete => get('complete');
  String get cancel => get('cancel');
  String get save => get('save');
  String get delete => get('delete');
  String get edit => get('edit');
  String get add => get('add');
  String get ok => get('ok');
  String get yes => get('yes');
  String get no => get('no');
  String get loading => get('loading');
  String get retry => get('retry');
  String get undo => get('undo');

  // Getter per il setup wizard
  String get setupWizard => get('setupWizard');
  String get startSetup => get('startSetup');
  String get welcomeToCarTracker => get('welcomeToCarTracker');
  String get welcomeDescription => get('welcomeDescription');

  // Getter per tracker management
  String get noTrackers => get('noTrackers');
  String get addFirstTracker => get('addFirstTracker');
  String get editTracker => get('editTracker');
  String get createTracker => get('createTracker');
  String get addTracker => get('addTracker');
  String get deleteTracker => get('deleteTracker');
  String get confirmDelete => get('confirmDelete');

  // Getter per settings
  String get theme => get('theme');
  String get light => get('light');
  String get dark => get('dark');
  String get system => get('system');
  String get appearance => get('appearance');
  String get about => get('about');
  String get advanced => get('advanced');

  // Getter per tracker info
  String get name => get('name');
  String get phoneNumber => get('phoneNumber');
  String get battery => get('battery');
  String get tracker => get('tracker');
  String get trackers => get('trackers');

  // Getter per overview
  String get overview => get('overview');
  String get messages => get('messages');
  String get history => get('history');
  String get deviceInfo => get('deviceInfo');
  String get technicalInfo => get('technicalInfo');
  String get alarms => get('alarms');
  String get licensePlate => get('licensePlate');
  String get model => get('model');
  String get lastUpdate => get('lastUpdate');
  String get id => get('id');
  String get imei => get('imei');
  String get apn => get('apn');
  String get iccid => get('iccid');
  String get ignitionAlarm => get('ignitionAlarm');
  String get powerAlarmSMS => get('powerAlarmSMS');

  // Setup wizard specific getters
  String get baseInfo => get('baseInfo');
  String get basicInfoDesc => get('basicInfoDesc');
  String get trackerName => get('trackerName');
  String get trackerNameHint => get('trackerNameHint');
  String get licensePlateHint => get('licensePlateHint');
  String get vehicleModel => get('vehicleModel');
  String get vehicleModelHint => get('vehicleModelHint');
  String get colorIdentification => get('colorIdentification');
  String get simConfig => get('simConfig');
  String get simConfigDesc => get('simConfigDesc');
  String get trackerSimNumber => get('trackerSimNumber');
  String get simNumberHint => get('simNumberHint');
  String get adminNumber => get('adminNumber');
  String get adminNumberHint => get('adminNumberHint');
  String get commandPin => get('commandPin');
  String get commandPinHint => get('commandPinHint');
  String get commandPinHelp => get('commandPinHelp');
  String get apnConfig => get('apnConfig');
  String get usernameOptional => get('usernameOptional');
  String get passwordOptional => get('passwordOptional');
  String get timezone => get('timezone');
  String get timezoneSelect => get('timezoneSelect');
  String get timezoneSelected => get('timezoneSelected');
  String get alarmConfig => get('alarmConfig');
  String get alarmConfigDesc => get('alarmConfigDesc');
  String get speedLimit => get('speedLimit');
  String get speedLimitHint => get('speedLimitHint');
  String get ignitionAlarmDesc => get('ignitionAlarmDesc');
  String get powerAlarmCall => get('powerAlarmCall');
  String get smsConfig => get('smsConfig');
  String get smsConfigDesc => get('smsConfigDesc');
  String get noConfigNeeded => get('noConfigNeeded');
  String get defaultSettingsDesc => get('defaultSettingsDesc');
  String get commandsToSend => get('commandsToSend');
  String get allCommandsSent => get('allCommandsSent');
  String get sendingInProgress => get('sendingInProgress');
  String get configurationComplete => get('configurationComplete');
  String get trackerReady => get('trackerReady');
  String get pressSaveToComplete => get('pressSaveToComplete');
  String get configurationSummary => get('configurationSummary');
  String get smsCommandsSent => get('smsCommandsSent');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
