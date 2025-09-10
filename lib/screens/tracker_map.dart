import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/tracker_positions.dart';

class TrackerPositionMapScreen extends StatefulWidget {
  final Tracker tracker;
  const TrackerPositionMapScreen(this.tracker, {super.key});

  @override
  State<TrackerPositionMapScreen> createState() => _TrackerPositionMapScreenState();
}

class _TrackerPositionMapScreenState extends State<TrackerPositionMapScreen> {
  final MapController _mapController = MapController();

  // Positions newest-first (index 0 is latest)
  List<TrackerPosition> _positions = [];
  bool _isLoading = true;
  String? _error;

  // Asset for marker icon (optional)
  Uint8List? _markerImage;

  @override
  void initState() {
    super.initState();
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
    _loadAssets();
    _loadPositions();
  }

  @override
  void dispose() {
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  void _onTrackerDataChanged() {
    if (!mounted) return;
    _loadPositions();
  }

  Future<void> _loadAssets() async {
    try {
      final bytes = await rootBundle.load("assets/sdf/geo-sdf.png");
      if (!mounted) return;
      setState(() {
        _markerImage = bytes.buffer.asUint8List();
      });
    } catch (_) {
      // L'icona personalizzata è opzionale; se mancante useremo un marker di fallback
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

      if (!mounted) return;
      setState(() {
        _positions = positions;
        _isLoading = false;
      });

      if (_positions.isNotEmpty) {
        await _centerOnLatest();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _positions = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _centerOnLatest() async {
    if (_positions.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 150));
    final latest = _positions.first;
    _mapController.move(LatLng(latest.latitude, latest.longitude), 15.0);
  }

  void _onMarkerTap(TrackerPosition position) {
    _showPositionDialog(position);
  }

  void _showPositionDialog(TrackerPosition position) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.gps_fixed, color: colorScheme.primary, size: 32),
        title: Text(
          localizations?.get('positionDetails') ?? 'Position Details',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: ListTile(
                leading: Icon(Icons.access_time, color: colorScheme.primary),
                title: Text(
                  localizations?.get('timestamp') ?? 'Timestamp',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(position.timestamp.toString()),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.secondaryContainer.withOpacity(0.3),
              child: ListTile(
                leading: Icon(Icons.location_on, color: colorScheme.secondary),
                title: Text(
                  localizations?.get('coordinates') ?? 'Coordinates',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  '${position.latitude.toStringAsFixed(6)}°, ${position.longitude.toStringAsFixed(6)}°',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations?.get('close') ?? 'Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openInExternalMaps(position);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(localizations?.get('openInMaps') ?? 'Open in Maps'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInExternalMaps(TrackerPosition position) async {
    try {
      HapticFeedback.lightImpact();
      final url = position.getGoogleMapsURL();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.get('errorOpeningMaps') ?? 'Error opening maps'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      /*appBar: AppBar(
        title: Text(localizations?.get('trackerMap') ?? 'Tracker Map'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPositions,
            tooltip: localizations?.get('refresh') ?? 'Refresh',
          ),
        ],
      ),*/
      body: Consumer<Object?>(
        builder: (context, trackerNotifier, child) {
          if (_isLoading) {
            return _buildLoadingState(localizations, theme, colorScheme);
          }
          if (_error != null) {
            return _buildErrorState(localizations, theme, colorScheme);
          }
          if (_positions.isEmpty) {
            return _buildEmptyState(localizations, theme, colorScheme);
          }
          return _buildMap(colorScheme);
        },
      ),
      floatingActionButton: _positions.isNotEmpty
          ? Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "list",
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TrackerPositionListScreen(widget.tracker),
                ),
              );
            },
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "center",
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            onPressed: _centerOnLatest,
            child: const Icon(Icons.my_location),
          ),
        ],
      )
          : null,
    );
  }

  Widget _buildMap(ColorScheme colorScheme) {
    if (_positions.isEmpty) return const SizedBox();

    final latest = _positions.first;
    final initialCenter = LatLng(latest.latitude, latest.longitude);

    // Markers: latest più grande/colore pieno; altri più piccoli/alpha
    final markers = <Marker>[
      for (int i = 0; i < _positions.length; i++)
        Marker(
          point: LatLng(_positions[i].latitude, _positions[i].longitude),
          width: i == 0 ? 44 : 36,
          height: i == 0 ? 44 : 36,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _onMarkerTap(_positions[i]),
            child: _buildMarkerIcon(
              isLatest: i == 0,
              color: Color(widget.tracker.color),
              label: '${i + 1}',
            ),
          ),
        ),
    ];

    // Polyline della traccia
    final linePoints = _positions
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Tile Layer (OSM libero). Inserire un attribution widget per conformità.
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.trackmate',
          tileProvider: NetworkTileProvider(),
        ),
        PolylineLayer(
          polylines: [
            if (linePoints.length >= 2)
              Polyline(
                points: linePoints,
                strokeWidth: 3.0,
                color: Color(widget.tracker.color).withOpacity(0.8),
              ),
          ],
        ),
        MarkerLayer(markers: markers),
        // Attribution OSM
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black.withOpacity(0.4),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkerIcon({
    required bool isLatest,
    required Color color,
    required String label,
  }) {
    // Se si dispone dell’immagine SDF, si può costruire una Image.memory,
    // altrimenti si usa un cerchio + label per semplicità.
    final baseColor = isLatest ? color : color.withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            localizations?.get('loadingMap') ?? 'Loading map...',
            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
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
              child: Icon(Icons.error_outline, size: 80, color: colorScheme.error),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('errorLoadingMap') ?? 'Error Loading Map',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(onPressed: _loadPositions, child: Text(localizations?.get('retry') ?? 'Retry')),
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
              child: Icon(Icons.map, size: 80, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('noPositionsForMap') ?? 'No positions to display',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('requestPositionToSeeMap') ??
                  'Request a position from the tracker to see the map',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _loadPositions,
              icon: const Icon(Icons.refresh),
              label: Text(localizations?.get('refresh') ?? 'Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
