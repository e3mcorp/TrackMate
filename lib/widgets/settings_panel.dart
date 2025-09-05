// lib/widgets/settings_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmate/data/settings.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/locale/supported_locales.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Settings>(
      builder: (context, settings, child) {
        final localizations = AppLocalizations.of(context)!;

        return Column(
          children: [
            // Language selector
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.get('locale')),
              subtitle: Text(settings.localeDisplayName),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(context, settings),
            ),

            const Divider(),

            // Theme selector
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(localizations.get('theme')),
              subtitle: Text(settings.themeModeDisplayName),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showThemeDialog(context, settings),
            ),

            const Divider(),

            // Reset button
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: Text(localizations.get('resetSettings')),
              subtitle: Text(localizations.get('resetSettingsDescription')),
              onTap: () => _showResetDialog(context, settings),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, Settings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SupportedLocales.supportedLocales.map((locale) {
            return RadioListTile<Locale>(
              title: Text(SupportedLocales.getDisplayName(locale)),
              value: locale,
              groupValue: settings.locale,
              onChanged: (locale) {
                if (locale != null) {
                  settings.setLocale(locale);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, Settings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((theme) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeDisplayName(theme)),
              value: theme,
              groupValue: settings.theme,
              onChanged: (theme) {
                if (theme != null) {
                  settings.setTheme(theme);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, Settings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System';
    }
  }
}
