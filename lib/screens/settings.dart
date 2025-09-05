// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trackmate/data/settings.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/global.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const double _sectionSpacing = 32.0;
  static const double _itemSpacing = 12.0;
  static const EdgeInsets _listPadding = EdgeInsets.all(16.0);
  static const EdgeInsets _headerPadding = EdgeInsets.only(left: 16, bottom: 12);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('settings') ?? 'Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: Consumer<Settings>(
          builder: (context, settings, child) {
            return ListView(
              padding: _listPadding,
              children: [
                // Sezione Aspetto
                _buildSectionHeader(
                  context,
                  localizations?.get('appearance') ?? 'Appearance',
                  Icons.palette,
                ),
                const SizedBox(height: _itemSpacing),
                _buildThemeSelector(context, settings),
                const SizedBox(height: _itemSpacing),
                _buildLanguageSelector(context, settings),
                const SizedBox(height: _sectionSpacing),

                // Sezione Informazioni
                _buildSectionHeader(
                  context,
                  localizations?.get('about') ?? 'About',
                  Icons.info_outline,
                ),
                const SizedBox(height: _itemSpacing),
                _buildVersionTile(context),
                const SizedBox(height: _itemSpacing),
                _buildLicenseTile(context),
                const SizedBox(height: _sectionSpacing),

                // Sezione Avanzate
                _buildSectionHeader(
                  context,
                  localizations?.get('advanced') ?? 'Advanced',
                  Icons.build,
                ),
                const SizedBox(height: _itemSpacing),
                _buildResetSettingsTile(context, settings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: _headerPadding,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, Settings settings) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getThemeIcon(settings.theme),
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          localizations?.get('theme') ?? 'Theme',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getThemeDisplayName(localizations, settings.theme),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: DropdownButton<ThemeMode>(
            value: settings.theme,
            underline: const SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurface,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(8),
            items: ThemeMode.values.map((ThemeMode theme) {
              return DropdownMenuItem(
                value: theme,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getThemeIcon(theme), size: 20),
                    const SizedBox(width: 8),
                    Text(_getThemeDisplayName(localizations, theme)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (ThemeMode? newTheme) => _handleThemeChange(
              context,
              settings,
              newTheme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, Settings settings) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.language,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          localizations?.get('locale') ?? 'Language',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getLanguageDisplayName(settings.locale),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: DropdownButton<Locale>(
            value: settings.locale,
            underline: const SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurface,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            borderRadius: BorderRadius.circular(8),
            items: AppLocalizations.supportedLocales.map((Locale locale) {
              return DropdownMenuItem(
                value: locale,
                child: Text(_getLanguageDisplayName(locale)),
              );
            }).toList(),
            onChanged: (Locale? newLocale) async {
              if (newLocale != null && newLocale != settings.locale) {
                await settings.setLocale(newLocale);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations?.get('languageChanged') ?? 'Language changed'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: colorScheme.inverseSurface,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVersionTile(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.info_outline,
            color: colorScheme.onTertiaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          localizations?.get('version') ?? 'Version',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'CarTracker v${Global.VERSION}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.copy,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _copyToClipboard(context, Global.VERSION),
          tooltip: localizations?.get('copyVersion') ?? 'Copy version',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseTile(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.description,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          localizations?.get('license') ?? 'License',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          localizations?.get('viewLicense') ?? 'View license',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => _launchUrl('https://github.com/emilius3m/car-tracker'),
      ),
    );
  }

  Widget _buildResetSettingsTile(BuildContext context, Settings settings) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.restore,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
        ),
        title: Text(
          localizations?.get('resetSettings') ?? 'Reset Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.error,
          ),
        ),
        subtitle: Text(
          localizations?.get('resetSettingsDescription') ?? 'Reset to defaults',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.error,
          size: 16,
        ),
        onTap: () => _showResetDialog(context, settings),
      ),
    );
  }

  // Helper methods
  IconData _getThemeIcon(ThemeMode theme) {
    return switch (theme) {
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.settings_brightness,
    };
  }

  String _getThemeDisplayName(AppLocalizations? localizations, ThemeMode theme) {
    return switch (theme) {
      ThemeMode.light => localizations?.get('light') ?? 'Light',
      ThemeMode.dark => localizations?.get('dark') ?? 'Dark',
      ThemeMode.system => localizations?.get('system') ?? 'System',
    };
  }

  String _getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'it':
        return '🇮🇹 Italiano';
      case 'pt':
        return '🇵🇹 Português';
      case 'en':
      default:
        return '🇺🇸 English';
    }
  }

  // Event handlers
  Future<void> _handleThemeChange(
      BuildContext context,
      Settings settings,
      ThemeMode? newTheme,
      ) async {
    if (newTheme != null && newTheme != settings.theme) {
      await settings.setTheme(newTheme);
      if (context.mounted) {
        final localizations = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.get('themeChanged') ?? 'Theme changed'),
            duration: const Duration(seconds: 2),
            backgroundColor: colorScheme.inverseSurface,
          ),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, Settings settings) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber,
            color: colorScheme.error,
          ),
          title: Text(localizations?.get('resetSettings') ?? 'Reset Settings'),
          content: Text(localizations?.get('resetSettingsConfirmation') ?? 'Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizations?.get('cancel') ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await settings.resetToDefaults();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations?.get('settingsReset') ?? 'Settings reset'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: colorScheme.inverseSurface,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: Text(localizations?.get('reset') ?? 'Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        final localizations = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.get('copiedToClipboard') ?? 'Copied to clipboard'),
            duration: const Duration(seconds: 2),
            backgroundColor: colorScheme.inverseSurface,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }
}
