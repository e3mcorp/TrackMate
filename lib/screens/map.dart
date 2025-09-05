import 'dart:typed_data';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/utils/data-validator.dart';
import 'package:trackmate/utils/geolocation.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../themes.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late MapboxMap mapboxMap;
  PointAnnotationManager? pointManager;
  Map<String, dynamic> _annotationData = {};
  List<Map<String, dynamic>> _trackerEntries = [];
  bool _isMapReady = false;

  String _getStyleUri() {
    return Themes.checkMode() == ThemeMode.dark
        ? 'mapbox://styles/mapbox/dark-v10'
        : 'mapbox://styles/mapbox/light-v10';
  }

  @override
  void initState() {
    super.initState();
    // ✅ Aggiungi listener per TrackerDB per aggiornamenti posizioni
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
  }

  @override
  void dispose() {
    // ✅ Rimuovi listener per evitare memory leaks
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  /// ✅ NEW: Callback quando i dati tracker cambiano
  void _onTrackerDataChanged() {
    if (_isMapReady) {
      _reloadMarkersFromDatabase();
    }
  }

  /// ✅ NEW: Ricarica marker dal database quando i dati cambiano
  Future<void> _reloadMarkersFromDatabase() async {
    try {
      await _clearExistingMarkers();
      await _drawMarkers();

      if (kDebugMode) {
        print('MapScreen: Markers reloaded due to database change');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MapScreen: Error reloading markers: $e');
      }
    }
  }

  /// ✅ NEW: Pulisce i marker esistenti
  Future<void> _clearExistingMarkers() async {
    if (pointManager != null) {
      await pointManager!.deleteAll();
      _annotationData.clear();
    }
  }

  Future<void> _initManagers() async {
    pointManager ??= await mapboxMap.annotations.createPointAnnotationManager();
    pointManager?.tapEvents(
      onTap: (annotation) {
        try {
          final annotationId = annotation.id;
          final data = _annotationData[annotationId];
          if (data != null) {
            final dynamic positionData = data['position'];
            final dynamic trackerData = data['tracker'];
            if (positionData is TrackerPosition && trackerData is Tracker) {
              final TrackerPosition position = positionData;
              _flyToPosition(position.latitude, position.longitude, 16.0);
              launchUrl(Uri.parse(position.getGoogleMapsURL()));
            }
          }
        } catch (e) {
          debugPrint('Error handling annotation tap: $e');
        }
      },
    );
  }

  Future<void> _drawMarkers() async {
    final db = await DataBase.get();
    final rawEntries = await TrackerPositionDB.getAllTrackerLastPosition(db!);

    _trackerEntries = rawEntries.map((entry) => {
      'tracker': entry.tracker,
      'position': entry.position,
    }).toList();

    if (_trackerEntries.isEmpty) return;

    final ByteData bytes = await rootBundle.load("assets/sdf/geo-sdf.png");
    final Uint8List imageBytes = bytes.buffer.asUint8List();
    final Color? textColor = Themes.theme().textTheme.bodyLarge?.color;
    final Color? textBorderColor = Themes.theme().textTheme.titleSmall?.color;

    final List<PointAnnotationOptions> options = _trackerEntries.map((entry) {
      final Tracker tracker = entry['tracker'] as Tracker;
      final TrackerPosition position = entry['position'] as TrackerPosition;

      return PointAnnotationOptions(
        geometry: Point(coordinates: Position(position.longitude, position.latitude)),
        image: imageBytes,
        iconSize: 0.9,
        iconColor: Color(tracker.color).value,
        textField: tracker.name,
        textSize: 16.0,
        textOffset: [0.0, 2.0],
        textColor: (textColor ?? const Color(0xFF000000)).value,
        textHaloColor: (textBorderColor ?? const Color(0xFFFFFFFF)).value,
        textHaloWidth: 1.0,
      );
    }).toList();

    try {
      final createdAnnotations = await pointManager!.createMulti(options);

      // ✅ Mantieni riferimenti ai marker per il tap handling
      for (int i = 0; i < createdAnnotations.length && i < _trackerEntries.length; i++) {
        final annotation = createdAnnotations[i];
        if (annotation != null) {
          _annotationData[annotation.id] = {
            'position': _trackerEntries[i]['position'],
            'tracker': _trackerEntries[i]['tracker'],
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MapScreen: Error creating annotations: $e');
      }
    }
  }

  Future<void> _flyToPosition(double latitude, double longitude, double zoom) async {
    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _flyToFitTrackers() async {
    if (_trackerEntries.isEmpty) return;

    if (_trackerEntries.length == 1) {
      final TrackerPosition position = _trackerEntries.first['position'] as TrackerPosition;
      await _flyToPosition(position.latitude, position.longitude, 15.0);
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final entry in _trackerEntries) {
      final TrackerPosition position = entry['position'] as TrackerPosition;
      final lat = position.latitude;
      final lon = position.longitude;

      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lon < minLon) minLon = lon;
      if (lon > maxLon) maxLon = lon;
    }

    try {
      await _fallbackFlyToTrackers(minLat, maxLat, minLon, maxLon);
    } catch (e) {
      debugPrint('Error fitting camera to trackers: $e');
      await _fallbackFlyToTrackers(minLat, maxLat, minLon, maxLon);
    }
  }

  Future<void> _fallbackFlyToTrackers(double minLat, double maxLat, double minLon, double maxLon) async {
    final latPadding = (maxLat - minLat) * 0.1;
    final lonPadding = (maxLon - minLon) * 0.1;

    minLat -= latPadding;
    maxLat += latPadding;
    minLon -= lonPadding;
    maxLon += lonPadding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;

    double zoom;
    if (maxDiff < 0.001) {
      zoom = 18.0;
    } else if (maxDiff < 0.01) {
      zoom = 15.0;
    } else if (maxDiff < 0.05) {
      zoom = 12.0;
    } else if (maxDiff < 0.1) {
      zoom = 10.0;
    } else if (maxDiff < 1.0) {
      zoom = 8.0;
    } else {
      zoom = 6.0;
    }

    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLon, centerLat)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  Future<void> _flyToUser(geo.Position? userPos) async {
    if (userPos == null) return;
    await _flyToPosition(userPos.latitude, userPos.longitude, 15.0);
  }

  Future<void> _onMapCreated(MapboxMap controller, geo.Position? userPos) async {
    mapboxMap = controller;
    await mapboxMap.loadStyleURI(_getStyleUri());
    await _initManagers();

    // ✅ Marca la mappa come pronta per gli aggiornamenti
    _isMapReady = true;

    await _drawMarkers();

    if (_trackerEntries.isNotEmpty) {
      await _flyToFitTrackers();
    } else if (userPos != null) {
      await _flyToUser(userPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<geo.Position?>(
            future: Geolocation.getPosition(),
            builder: (context, snapshot) {
              final geo.Position? pos = snapshot.data;
              final Point center = Point(coordinates: Position(0, 0));

              // ✅ CORREZIONE: Usa ChangeNotifierProvider.value per ascoltare i cambiamenti
              return ChangeNotifierProvider.value(
                value: TrackerDB.changeNotifier,
                child: Consumer<TrackerNotifier>(
                  builder: (context, notifier, child) {
                    return MapWidget(
                      key: const ValueKey("map"),
                      cameraOptions: CameraOptions(center: center, zoom: 2.0),
                      styleUri: _getStyleUri(),
                      onMapCreated: (map) => _onMapCreated(map, pos),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ✅ Bottone per ricaricare manualmente i marker
          FloatingActionButton(
            heroTag: "refresh_markers",
            onPressed: () async {
              if (_isMapReady) {
                await _reloadMarkersFromDatabase();
                if (context.mounted) {
                  Modal.toast(
                    context,
                    localizations?.get('markersRefreshed') ?? 'Markers refreshed',
                  );
                }
              }
            },
            backgroundColor: Colors.orange,
            tooltip: localizations?.get('refreshMarkers') ?? 'Refresh markers',
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Bottone per centrare sui tracker
          if (_trackerEntries.isNotEmpty)
            FloatingActionButton(
              heroTag: "fly_to_trackers",
              onPressed: _flyToFitTrackers,
              backgroundColor: Colors.blue,
              tooltip: localizations?.get('centerOnTrackers') ?? 'Center on trackers',
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          const SizedBox(height: 10),

          // Bottone per volare alla posizione utente
          FloatingActionButton(
            heroTag: "fly_to_user",
            onPressed: () async {
              final userPos = await Geolocation.getPosition();
              if (userPos != null) {
                await _flyToUser(userPos);
              }
            },
            backgroundColor: Colors.green,
            tooltip: localizations?.get('centerOnUser') ?? 'Center on me',
            child: const Icon(Icons.person_pin_circle, color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Bottone per richiedere posizioni
          FloatingActionButton(
            heroTag: "request_position",
            onPressed: () async {
              final db = await DataBase.get();
              final trackers = await TrackerDB.list(db!);

              for (final t in trackers) {
                if (DataValidator.phoneNumber(t.phoneNumber)) {
                  t.requestLocation();
                }
              }

              if (context.mounted) {
                Modal.toast(
                  context,
                  localizations?.get('requestedPosition') ?? 'Position requested',
                );
              }
            },
            child: Icon(
              Icons.gps_fixed,
              color: Themes.theme().textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
