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

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // markers data: [{'tracker': Tracker, 'position': TrackerPosition}]
  List<Map<String, Object>> _trackerEntries = [];
  bool _isMapReady = false;

  Uint8List? _markerImageBytes; // opzionale se vuoi usare l’asset esistente

  @override
  void initState() {
    super.initState();
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
    _loadMarkerAsset();
  }

  @override
  void dispose() {
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  Future<void> _loadMarkerAsset() async {
    try {
      final bytes = await rootBundle.load("assets/sdf/geo-sdf.png");
      setState(() {
        _markerImageBytes = bytes.buffer.asUint8List();
      });
    } catch (_) {
      // asset opzionale; in fallback useremo marker circolari
    }
  }

  void _onTrackerDataChanged() {
    if (_isMapReady) {
      _reloadMarkersFromDatabase();
    }
  }

  Future<void> _reloadMarkersFromDatabase() async {
    try {
      final db = await DataBase.get();
      final rawEntries = await TrackerPositionDB.getAllTrackerLastPosition(db!);
      final entries = rawEntries
          .map<Map<String, Object>>(
            (entry) => {
          'tracker': entry.tracker,
          'position': entry.position,
        },
      )
          .toList();
      if (!mounted) return;
      setState(() {
        _trackerEntries = entries;
      });
      if (_trackerEntries.isNotEmpty) {
        await _flyToFitTrackers();
      }
      if (kDebugMode) {
        debugPrint('MapScreen: Markers reloaded due to database change');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapScreen: Error reloading markers: $e');
      }
    }
  }

  Future<void> _flyToPosition(double latitude, double longitude, double zoom) async {
    _mapController.move(LatLng(latitude, longitude), zoom);
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

    await _fallbackFlyToTrackers(minLat, maxLat, minLon, maxLon);
  }

  Future<void> _fallbackFlyToTrackers(double minLat, double maxLat, double minLon, double maxLon) async {
    // padding 10%
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

    _mapController.move(LatLng(centerLat, centerLon), zoom);
  }

  Future<void> _flyToUser(geo.Position? userPos) async {
    if (userPos == null) return;
    await _flyToPosition(userPos.latitude, userPos.longitude, 15.0);
  }

  Future<void> _onMapReady(geo.Position? userPos) async {
    _isMapReady = true;
    await _reloadMarkersFromDatabase();
    if (_trackerEntries.isNotEmpty) {
      await _flyToFitTrackers();
    } else if (userPos != null) {
      await _flyToUser(userPos);
    }
  }

  Future<void> _onMarkerTap(TrackerPosition position) async {
    // Apri direttamente Google Maps come facevi nel tap dell’annotation
    final uri = Uri.parse(position.getGoogleMapsURL());
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening maps: $e');
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

              // Usa ChangeNotifierProvider.value per ascoltare i cambiamenti del DB
              return ChangeNotifierProvider.value(
                value: TrackerDB.changeNotifier,
                child: Consumer<Object?>(
                  builder: (context, notifier, child) {
                    // Inizializza quando la mappa viene costruita la prima volta
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_isMapReady) {
                        _onMapReady(pos);
                      }
                    });

                    // Centro iniziale (fallback)
                    final initialCenter = LatLng(pos?.latitude ?? 0, pos?.longitude ?? 0);

                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 2.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                      ),
                      children: [
                        // TileLayer: qui puoi sostituire il provider (OSM, Stadia, MapTiler, ecc.)
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.trackmate',
                        ),
                        // Layer markers (uno per tracker)
                        MarkerLayer(
                          markers: [
                            for (final entry in _trackerEntries)
                              _buildMarker(
                                entry['tracker'] as Tracker,
                                entry['position'] as TrackerPosition,
                              ),
                          ],
                        ),
                        // Attribution OSM (conforme alle policy)
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
          // Bottone per ricaricare manualmente i marker
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

  Marker _buildMarker(Tracker tracker, TrackerPosition position) {
    // Marker tappabile: apre Google Maps e fa anche flyTo
    return Marker(
      point: LatLng(position.latitude, position.longitude),
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () async {
          await _flyToPosition(position.latitude, position.longitude, 16.0);
          await _onMarkerTap(position);
        },
        child: _buildMarkerIcon(
          color: Color(tracker.color),
          label: tracker.name,
        ),
      ),
    );
  }

  Widget _buildMarkerIcon({
    required Color color,
    required String label,
  }) {
    // Fallback semplice: pallino circolare con label (nome tracker)
    // Se vuoi usare l’icona SDF, puoi sostituire con Image.memory(_markerImageBytes!)
    final textColor = Themes.theme().textTheme.bodyLarge?.color ?? Colors.white;
    final borderColor = Themes.theme().textTheme.titleSmall?.color ?? Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(
        _shorten(label),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: borderColor.withOpacity(0.8),
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }

  String _shorten(String s) {
    if (s.length <= 4) return s;
    return s.substring(0, 4).toUpperCase();
  }
}
