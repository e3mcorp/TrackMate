import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TrackerPositionListScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerPositionListScreen(this.tracker, {super.key});

  @override
  State<TrackerPositionListScreen> createState() => TrackerPositionListScreenState();
}

class TrackerPositionListScreenState extends State<TrackerPositionListScreen> {
  List<TrackerPosition>? _positions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
    _loadPositions();
  }

  @override
  void dispose() {
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  void _onTrackerDataChanged() {
    if (mounted) {
      _loadPositions();
    }
  }

  Future<void> _loadPositions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final db = await DataBase.get();
      final positions = await TrackerPositionDB.list(db!, widget.tracker.uuid);

      if (mounted) {
        setState(() {
          _positions = positions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _positions = [];
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refreshPositions() async {
    HapticFeedback.lightImpact();
    await _loadPositions();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations?.get('positions') ?? 'Positions'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshPositions,
            tooltip: localizations?.get('refresh') ?? 'Refresh',
          ),
        ],
      ),
      body: Consumer<TrackerNotifier>(
        builder: (context, trackerNotifier, child) {
          if (_isLoading) {
            return _buildLoadingState(localizations, theme, colorScheme);
          }

          if (_error != null) {
            return _buildErrorState(localizations, theme, colorScheme);
          }

          if (_positions == null || _positions!.isEmpty) {
            return _buildEmptyState(localizations, theme, colorScheme);
          }

          return _buildPositionsList(localizations, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.get('loadingPositions') ?? 'Loading positions...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('errorLoadingPositions') ?? 'Error Loading Positions',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error ?? 'Unknown error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: _refreshPositions,
              child: Text(localizations?.get('retry') ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.gps_off,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('noPositions') ?? 'No positions available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('requestPositionFirst') ?? 'Request a position from your tracker first',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _refreshPositions,
              icon: const Icon(Icons.refresh),
              label: Text(localizations?.get('refresh') ?? 'Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsList(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Header con statistiche
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_positions!.length} ${localizations?.get('positions') ?? 'Positions'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_positions!.isNotEmpty)
                      Text(
                        '${localizations?.get('lastUpdate') ?? 'Last update'}: ${_formatDateTime(_positions!.first.timestamp)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista posizioni
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPositions,
            color: colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              itemCount: _positions!.length,
              itemBuilder: (context, index) {
                final position = _positions![index];
                return _buildPositionItem(position, index, localizations, theme, colorScheme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionItem(TrackerPosition position, int index, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    final isRecent = _isRecentPosition(position.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRecent
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isRecent
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRecent
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.gps_fixed,
              color: isRecent
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateTime(position.timestamp),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (isRecent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localizations?.get('new') ?? 'NEW',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${position.latitude.toStringAsFixed(6)}°, ${position.longitude.toStringAsFixed(6)}°',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatFullDateTime(position.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: colorScheme.primary,
          ),
          onTap: () => _openInMaps(position),
        ),
      ),
    );
  }

  Future<void> _openInMaps(TrackerPosition position) async {
    try {
      HapticFeedback.lightImpact();
      final url = position.getGoogleMapsURL();
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.get('errorOpeningMaps') ?? 'Error opening maps'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm:ss').format(dateTime);
  }

  bool _isRecentPosition(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 30;
  }
}
