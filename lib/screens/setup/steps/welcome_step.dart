import 'package:flutter/material.dart';
import 'package:trackmate/locale/app_localizations.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.secondaryContainer.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.gps_fixed,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            localizations?.get('welcome') ?? 'Welcome!',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            localizations?.get('welcomeDescription') ??
                'TrackMate helps you monitor your vehicles via GPS trackers.\n\nYou will receive SMS with positions, battery status, and other useful information.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 0,
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeatureItem(
                    Icons.location_on,
                    localizations?.get('realTimePositions') ?? 'Real-time positions',
                    colorScheme,
                  ),
                  _buildFeatureItem(
                    Icons.battery_std,
                    localizations?.get('batteryMonitoring') ?? 'Battery monitoring',
                    colorScheme,
                  ),
                  _buildFeatureItem(
                    Icons.route,
                    localizations?.get('routeHistory') ?? 'Route history',
                    colorScheme,
                  ),
                  _buildFeatureItem(
                    Icons.notifications,
                    localizations?.get('automaticNotifications') ?? 'Automatic notifications',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
