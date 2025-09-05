import 'dart:typed_data';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/tracker_positions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackerPositionMapScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerPositionMapScreen(this.tracker, {super.key});

  @override
  State<TrackerPositionMapScreen> createState() => TrackerPositionMapScreenState();
}

class TrackerPositionMapScreenState extends State<TrackerPositionMapScreen> {
  MapboxMap? _mapboxMap;
  List<TrackerPosition> _positions = [];
  Map<String, TrackerPosition> _annotationData = {};
  PointAnnotationManager? _pointManager;
  PolylineAnnotationManager? _polylineManager;
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

        // Aggiorna la mappa se è già inizializzata
        if (_mapboxMap != null && _positions.isNotEmpty) {
          await _updateMapData();
        }
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

  // ✅ CORREZIONE: Usa tapEvents invece di addOnClickListener
  Future<void> _initializeManagers() async {
    if (_mapboxMap == null) return;

    try {
      _pointManager ??= await _mapboxMap!.annotations.createPointAnnotationManager();
      _polylineManager ??= await _mapboxMap!.annotations.createPolylineAnnotationManager();

      // ✅ Setup tap events con la sintassi corretta per Flutter Mapbox
      _pointManager?.tapEvents(
        onTap: (annotation) {
          final position = _annotationData[annotation.id];
          if (position != null) {
            _showPositionDialog(position);
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing map managers: $e');
    }
  }

  Future<void> _updateMapData() async {
    if (_positions.isEmpty || _pointManager == null || _polylineManager == null) return;

    try {
      // Clear existing annotations
      await _pointManager!.deleteAll();
      await _polylineManager!.deleteAll();
      _annotationData.clear();

      // Draw trajectory
      await _drawTrajectory();

      // Draw markers
      await _drawMarkers();

      // Center camera on latest position
      await _centerCameraOnLatestPosition();
    } catch (e) {
      debugPrint('Error updating map data: $e');
    }
  }

  Future<void> _drawMarkers() async {
    if (_pointManager == null || _positions.isEmpty) return;

    try {
      final ByteData bytes = await rootBundle.load("assets/sdf/geo-sdf.png");
      final Uint8List imageData = bytes.buffer.asUint8List();

      final List<PointAnnotationOptions> options = [];

      for (int i = 0; i < _positions.length; i++) {
        final position = _positions[i];
        options.add(
          PointAnnotationOptions(
            geometry: Point(
                coordinates: Position(position.longitude, position.latitude)
            ),
            image: imageData,
            iconSize: i == 0 ? 1.2 : 0.8, // Latest position is larger
            iconColor: i == 0
                ? widget.tracker.color
                : Color(widget.tracker.color).withOpacity(0.7).value,
            textField: '${i + 1}',
            textSize: 12.0,
            textOffset: [0.0, 2.2],
            textColor: Colors.white.value,
          ),
        );
      }

      final annotations = await _pointManager!.createMulti(options);

      // Store position data for tap events
      for (int i = 0; i < annotations.length && i < _positions.length; i++) {
        final annotation = annotations[i];
        if (annotation != null) {
          _annotationData[annotation.id] = _positions[i];
        }
      }
    } catch (e) {
      debugPrint('Error drawing markers: $e');
    }
  }

  Future<void> _drawTrajectory() async {
    if (_polylineManager == null || _positions.length < 2) return;

    try {
      final List<Position> coords = _positions
          .map((p) => Position(p.longitude, p.latitude))
          .toList();

      final PolylineAnnotationOptions line = PolylineAnnotationOptions(
        geometry: LineString(coordinates: coords),
        lineWidth: 3.0,
        lineOpacity: 0.8,
        lineColor: widget.tracker.color,
      );

      await _polylineManager!.create(line);
    } catch (e) {
      debugPrint('Error drawing trajectory: $e');
    }
  }

  Future<void> _centerCameraOnLatestPosition() async {
    if (_mapboxMap == null || _positions.isEmpty) return;

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final position = _positions.first;
      await _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(
              coordinates: Position(position.longitude, position.latitude)
          ),
          zoom: 15.0,
        ),
      );
    } catch (e) {
      debugPrint('Error centering camera: $e');
    }
  }

  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapboxMap = controller;
    await _initializeManagers();
    if (_positions.isNotEmpty) {
      await _updateMapData();
    }
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
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
      ),
      body: Consumer<TrackerNotifier>(
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

          return _buildMap();
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
            onPressed: _centerCameraOnLatestPosition,
            child: const Icon(Icons.my_location),
          ),
        ],
      )
          : null,
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
            localizations?.get('loadingMap') ?? 'Loading map...',
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
              localizations?.get('errorLoadingMap') ?? 'Error Loading Map',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: _loadPositions,
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
                Icons.map,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
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
              localizations?.get('requestPositionToSeeMap') ?? 'Request a position from your tracker to see the map',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

  Widget _buildMap() {
    if (_positions.isEmpty) return const SizedBox();

    return MapWidget(
      key: const ValueKey("tracker_map"),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            _positions.first.longitude,
            _positions.first.latitude,
          ),
        ),
        zoom: 12.0,
      ),
      onMapCreated: _onMapCreated,
    );
  }
}
