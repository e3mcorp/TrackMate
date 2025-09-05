// lib/widgets/language_selector_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackmate/data/settings.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/locale/supported_locales.dart';

class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const LanguageSelectorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.get('selectLanguage')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: SupportedLocales.supportedLocales.length,
          itemBuilder: (context, index) {
            final locale = SupportedLocales.supportedLocales[index];
            final isSelected = settings.locale == locale;

            return ListTile(
              leading: Text(
                _getLanguageFlag(locale.languageCode),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(SupportedLocales.getDisplayName(locale)),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              selected: isSelected,
              onTap: () async {
                if (!isSelected) {
                  await settings.setLocale(locale);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.get('cancel')),
        ),
      ],
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇵🇹';
      default:
        return '🌍';
    }
  }
}
