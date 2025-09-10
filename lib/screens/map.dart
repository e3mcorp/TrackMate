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
  List<Map<String, dynamic>> _allTrackerEntries = [];
  List<Map<String, dynamic>> _visibleTrackerEntries = [];

  // ✅ Stato per tracciare quali tracker sono visibili
  Set<String> _selectedTrackerUuids = <String>{};

  bool _isMapReady = false;
  Uint8List? _markerImageBytes;

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
          .map<Map<String, dynamic>>(
            (entry) => {
          'tracker': entry.tracker,
          'position': entry.position,
        },
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _allTrackerEntries = entries;

        // Se è la prima volta, seleziona tutti i tracker
        if (_selectedTrackerUuids.isEmpty) {
          _selectedTrackerUuids = Set<String>.from(
              _allTrackerEntries.map((entry) => (entry['tracker'] as Tracker).uuid)
          );
        }

        // Filtra solo i tracker selezionati
        _visibleTrackerEntries = _allTrackerEntries
            .where((entry) => _selectedTrackerUuids.contains((entry['tracker'] as Tracker).uuid))
            .toList();
      });

      if (_visibleTrackerEntries.isNotEmpty) {
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

  // ✅ Mostra/nasconde tracker specifico
  void _toggleTrackerVisibility(String trackerUuid, bool isVisible) {
    setState(() {
      if (isVisible) {
        _selectedTrackerUuids.add(trackerUuid);
      } else {
        _selectedTrackerUuids.remove(trackerUuid);
      }

      // Aggiorna i marker visibili
      _visibleTrackerEntries = _allTrackerEntries
          .where((entry) => _selectedTrackerUuids.contains((entry['tracker'] as Tracker).uuid))
          .toList();
    });

    // Riadatta la mappa se ci sono tracker visibili
    if (_visibleTrackerEntries.isNotEmpty) {
      _flyToFitTrackers();
    }
  }

  // ✅ Mostra/nascondi tutti i tracker
  void _toggleAllTrackers(bool showAll) {
    setState(() {
      if (showAll) {
        _selectedTrackerUuids = Set<String>.from(
            _allTrackerEntries.map((entry) => (entry['tracker'] as Tracker).uuid)
        );
      } else {
        _selectedTrackerUuids.clear();
      }

      _visibleTrackerEntries = _allTrackerEntries
          .where((entry) => _selectedTrackerUuids.contains((entry['tracker'] as Tracker).uuid))
          .toList();
    });

    if (_visibleTrackerEntries.isNotEmpty) {
      _flyToFitTrackers();
    }
  }

  Future<void> _flyToPosition(double latitude, double longitude, double zoom) async {
    _mapController.move(LatLng(latitude, longitude), zoom);
  }

  Future<void> _flyToFitTrackers() async {
    if (_visibleTrackerEntries.isEmpty) return;

    if (_visibleTrackerEntries.length == 1) {
      final TrackerPosition position = _visibleTrackerEntries.first['position'] as TrackerPosition;
      await _flyToPosition(position.latitude, position.longitude, 15.0);
      return;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final entry in _visibleTrackerEntries) {
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
    if (_visibleTrackerEntries.isNotEmpty) {
      await _flyToFitTrackers();
    } else if (userPos != null) {
      await _flyToUser(userPos);
    }
  }

  Future<void> _onMarkerTap(TrackerPosition position) async {
    final uri = Uri.parse(position.getGoogleMapsURL());
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening maps: $e');
    }
  }

  // ✅ Mostra bottom sheet per selezione tracker
  void _showTrackerFilterSheet(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.3,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle per trascinare
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Titolo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations?.get('selectTrackers') ?? 'Select Trackers',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Controlli globali
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _toggleAllTrackers(true);
                                setModalState(() {});
                                setState(() {});
                              },
                              icon: const Icon(Icons.check_box),
                              label: Text(localizations?.get('selectAll') ?? 'Select All'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _toggleAllTrackers(false);
                                setModalState(() {});
                                setState(() {});
                              },
                              icon: const Icon(Icons.check_box_outline_blank),
                              label: Text(localizations?.get('deselectAll') ?? 'Deselect All'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Lista tracker
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _allTrackerEntries.length,
                          itemBuilder: (context, index) {
                            final tracker = _allTrackerEntries[index]['tracker'] as Tracker;
                            final isSelected = _selectedTrackerUuids.contains(tracker.uuid);

                            return Card(
                              child: CheckboxListTile(
                                title: Text(
                                  tracker.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  tracker.phoneNumber.isEmpty
                                      ? 'No phone number'
                                      : tracker.phoneNumber,
                                ),
                                secondary: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(tracker.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  _toggleTrackerVisibility(tracker.uuid, value ?? false);
                                  setModalState(() {});
                                  setState(() {});
                                },
                                controlAffinity: ListTileControlAffinity.trailing,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Statistiche
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${_allTrackerEntries.length}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  localizations?.get('total') ?? 'Total',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_selectedTrackerUuids.length}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  localizations?.get('selected') ?? 'Selected',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
              return ChangeNotifierProvider.value(
                value: TrackerDB.changeNotifier,
                child: Consumer<TrackerNotifier>(  // ✅ Aggiungi <TrackerNotifier>
                  builder: (context, notifier, child) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_isMapReady) {
                        _onMapReady(pos);
                      }
                    });

                    final initialCenter = LatLng(pos?.latitude ?? 0, pos?.longitude ?? 0);
                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 2.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          userAgentPackageName: 'com.example.trackmate',
                        ),
                        MarkerLayer(
                          markers: [
                            for (final entry in _visibleTrackerEntries)
                              _buildMarker(
                                entry['tracker'] as Tracker,
                                entry['position'] as TrackerPosition,
                              ),
                          ],
                        ),
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
                  },
                ),
              );
            },
          ),
        ],
      ),
      // ✅ Floating action button principale con menu
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Filtro tracker - PRINCIPALE
          FloatingActionButton.extended(
            heroTag: "filter_trackers",
            onPressed: () => _showTrackerFilterSheet(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.filter_list),
            label: Text(
              '${_selectedTrackerUuids.length}/${_allTrackerEntries.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 12),

          // Azioni rapide
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Centra su tracker visibili
              if (_visibleTrackerEntries.isNotEmpty)
                FloatingActionButton(
                  heroTag: "center_trackers",
                  onPressed: _flyToFitTrackers,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  tooltip: localizations?.get('centerOnTrackers') ?? 'Center on visible trackers',
                  child: const Icon(Icons.center_focus_strong),
                ),

              // Centra su utente
              FloatingActionButton(
                heroTag: "center_user",
                onPressed: () async {
                  final userPos = await Geolocation.getPosition();
                  if (userPos != null) {
                    await _flyToUser(userPos);
                  }
                },
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                tooltip: localizations?.get('centerOnUser') ?? 'Center on my location',
                child: const Icon(Icons.my_location),
              ),

              // Richiedi posizioni
              FloatingActionButton(
                heroTag: "request_positions",
                onPressed: () async {
                  final db = await DataBase.get();
                  final trackers = await TrackerDB.list(db!);
                  int requestCount = 0;

                  for (final t in trackers) {
                    if (DataValidator.phoneNumber(t.phoneNumber)) {
                      t.requestLocation();
                      requestCount++;
                    }
                  }

                  if (context.mounted) {
                    Modal.toast(
                      context,
                      '${localizations?.get('requestedPosition') ?? 'Position requested'} ($requestCount)',
                    );
                  }
                },
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                tooltip: localizations?.get('requestAllPositions') ?? 'Request all positions',
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Marker _buildMarker(Tracker tracker, TrackerPosition position) {
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
