// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/data/settings.dart';
import 'package:trackmate/screens/splash_screen.dart';
import 'package:trackmate/screens/menu.dart';
import 'package:trackmate/screens/setup_wizard.dart';
import 'package:trackmate/themes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('en', 'US');

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }

            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }

            return const Locale('en', 'US');
          },
          themeMode: settings.theme,
          theme: Themes.lightTheme,
          darkTheme: Themes.darkTheme,

          // ✅ ROUTES DEFINITE
          routes: {
            '/': (context) => const MainMenu(),
            '/splash': (context) => const SplashScreen(),
            '/setup': (context) => SetupWizardScreen(
              mode: SetupMode.firstDevice,
              onComplete: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          },

          // ✅ SPLASH COME INITIAL ROUTE
          initialRoute: '/splash',
        );
      },
    );
  }
}
