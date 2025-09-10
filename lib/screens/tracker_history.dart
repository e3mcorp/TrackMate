import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/locale/app_localizations.dart';

class TrackerHistoryScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerHistoryScreen(this.tracker, {super.key});

  @override
  State<TrackerHistoryScreen> createState() => _TrackerHistoryScreenState();
}

class _TrackerHistoryScreenState extends State<TrackerHistoryScreen> {
  final MapController _mapController = MapController();
  List<TrackerPosition> _positions = [];
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  int? _focusedIndex;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
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

  Future<void> _loadPositions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final db = await DataBase.get();
      final rows = await TrackerPositionDB.list(db!, widget.tracker.uuid);

      if (!mounted) return;

      setState(() {
        _positions = rows;
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
    final dayPositions = _positionsOfSelectedDay;
    if (dayPositions.isEmpty) return;

    await Future.delayed(const Duration(milliseconds: 150));
    final latest = dayPositions.first;
    _mapController.move(LatLng(latest.latitude, latest.longitude), 15.0);
  }

  List<TrackerPosition> get _positionsOfSelectedDay {
    if (_positions.isEmpty) return const [];
    return _positions.where((p) {
      final d = DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day);
      final s = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      return d == s;
    }).toList();
  }

  Future<void> _pickDay() async {
    final daysWithData = _getDaysWithPositions();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime tempSelected = _selectedDay;
        DateTime tempFocused = _focusedDay;

        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Seleziona una data'),
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: 300,
              height: 380,
              child: TableCalendar<String>(
                locale: 'it_IT',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: tempFocused,
                selectedDayPredicate: (day) => isSameDay(tempSelected, day),
                eventLoader: (day) {
                  final dayLocal = DateTime(day.year, day.month, day.day);
                  return daysWithData.contains(dayLocal) ? const ['gps'] : const [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setDialogState(() {
                    tempSelected = selectedDay;
                    tempFocused = focusedDay;
                  });
                  Navigator.of(context).pop(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  defaultTextStyle: theme.textTheme.bodyMedium!,
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: colorScheme.error,
                  ),
                  outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.38),
                  ),
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: Color(widget.tracker.color),
                    shape: BoxShape.circle,
                  ),
                  markerMargin: const EdgeInsets.only(top: 2),
                  markerSize: 6.0,
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: colorScheme.onSurface,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: theme.textTheme.bodySmall!.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: theme.textTheme.bodySmall!.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annulla'),
              ),
            ],
          );
        });
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _focusedDay = picked;
        _focusedIndex = null;
      });
      await _centerOnLatest();
    }
  }

  Set<DateTime> _getDaysWithPositions() {
    final Set<DateTime> days = {};
    for (final position in _positions) {
      final dayOnly = DateTime(
        position.timestamp.year,
        position.timestamp.month,
        position.timestamp.day,
      );
      days.add(dayOnly);
    }
    return days;
  }

  void _onMarkerTap(TrackerPosition position, int index) {
    HapticFeedback.selectionClick();
    setState(() => _focusedIndex = index);
    _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
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
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l?.get('errorOpeningMaps') ?? 'Error opening maps'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controlla se siamo dentro una TabBarView (modalità embedded)
    final isEmbedded = context.findAncestorWidgetOfExactType<TabBarView>() != null;

    if (isEmbedded) {
      // Modalità embedded - solo il contenuto senza AppBar
      return Consumer<void>(
        builder: (context, trackerNotifier, child) {
          if (_isLoading) {
            return _buildLoadingState(l, theme, colorScheme);
          }

          if (_error != null) {
            return _buildErrorState(l, theme, colorScheme);
          }

          if (_positions.isEmpty) {
            return _buildEmptyState(l, theme, colorScheme);
          }

          return Column(
            children: [
              _buildMap(colorScheme),
              _buildTimelineSheet(l, theme, colorScheme),
            ],
          );
        },
      );
    }

    // Modalità normale con AppBar completo
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l?.get('positionHistory') ?? 'Cronologia posizione'),
            Text(widget.tracker.name, style: theme.textTheme.labelSmall),
          ],
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPositions,
            tooltip: l?.get('refresh') ?? 'Refresh',
          ),
        ],
      ),
      body: Consumer<void>(
        builder: (context, trackerNotifier, child) {
          if (_isLoading) {
            return _buildLoadingState(l, theme, colorScheme);
          }

          if (_error != null) {
            return _buildErrorState(l, theme, colorScheme);
          }

          if (_positions.isEmpty) {
            return _buildEmptyState(l, theme, colorScheme);
          }

          return Column(
            children: [
              _buildMap(colorScheme),
              _buildTimelineSheet(l, theme, colorScheme),
            ],
          );
        },
      ),
      floatingActionButton: _positionsOfSelectedDay.isNotEmpty
          ? FloatingActionButton(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        onPressed: _centerOnLatest,
        child: const Icon(Icons.my_location),
      )
          : null,
    );
  }

  Widget _buildMap(ColorScheme colorScheme) {
    final dayPositions = _positionsOfSelectedDay;
    if (dayPositions.isEmpty) return const SizedBox(height: 280);

    final latest = dayPositions.first;
    final initialCenter = LatLng(latest.latitude, latest.longitude);

    final markers = [
      for (int i = 0; i < dayPositions.length; i++)
        Marker(
          point: LatLng(dayPositions[i].latitude, dayPositions[i].longitude),
          width: i == 0 ? 44 : 36,
          height: i == 0 ? 44 : 36,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _onMarkerTap(dayPositions[i], i),
            child: _buildMarkerIcon(
              isLatest: i == 0,
              isSelected: _focusedIndex == i,
              color: Color(widget.tracker.color),
              label: '${i + 1}',
            ),
          ),
        ),
    ];

    final linePoints = dayPositions
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    return SizedBox(
      height: 280,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 12.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.trackmate',
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
      ),
    );
  }

  Widget _buildMarkerIcon({
    required bool isLatest,
    required bool isSelected,
    required Color color,
    required String label,
  }) {
    Color baseColor;
    if (isSelected) {
      baseColor = color;
    } else if (isLatest) {
      baseColor = color;
    } else {
      baseColor = color.withOpacity(0.7);
    }

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: isSelected ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
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

  Widget _buildTimelineSheet(AppLocalizations? l, ThemeData theme, ColorScheme colorScheme) {
    final dayList = _positionsOfSelectedDay;
    final daysWithPositions = _getDaysWithPositions();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(widget.tracker.color).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(widget.tracker.color), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trovati ${daysWithPositions.length} giorni con rilevazioni GPS',
                      style: TextStyle(
                        color: Color(widget.tracker.color),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.subtract(const Duration(days: 1));
                        _focusedDay = _selectedDay;
                        _focusedIndex = null;
                      });
                      _centerOnLatest();
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _formatDay(_selectedDay),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.add(const Duration(days: 1));
                        _focusedDay = _selectedDay;
                        _focusedIndex = null;
                      });
                      _centerOnLatest();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _pickDay,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (dayList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l?.get('noPositionsForMap') ?? 'Nessuna posizione per questa data',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (daysWithPositions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Seleziona una data diversa dal calendario',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = dayList[index];
                    final selected = _focusedIndex == index;
                    return _TimelineTile(
                      time: _formatTime(p.timestamp),
                      title: '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
                      isPrimary: index == 0,
                      selected: selected,
                      color: Color(widget.tracker.color),
                      onTap: () => _onMarkerTap(p, index),
                      onOpenMaps: () => _openInExternalMaps(p),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? l, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            l?.get('loadingMap') ?? 'Caricamento mappa...',
            style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations? l, ThemeData theme, ColorScheme colorScheme) {
    final isEmbedded = context.findAncestorWidgetOfExactType<TabBarView>() != null;

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
              l?.get('errorLoadingMap') ?? 'Errore nel caricamento',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Errore sconosciuto',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (!isEmbedded) ...[
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: _loadPositions,
                child: Text(l?.get('retry') ?? 'Riprova'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l, ThemeData theme, ColorScheme colorScheme) {
    final isEmbedded = context.findAncestorWidgetOfExactType<TabBarView>() != null;

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
              child: Icon(Icons.timeline, size: 80, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text(
              l?.get('noPositionsForMap') ?? 'Nessuna posizione disponibile',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l?.get('requestPositionToSeeMap') ?? 'Richiedi una posizione dal tracker per vedere la cronologia',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (!isEmbedded) ...[
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _loadPositions,
                icon: const Icon(Icons.refresh),
                label: Text(l?.get('refresh') ?? 'Aggiorna'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDay(DateTime d) {
    final wd = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][d.weekday - 1];
    final mo = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'][d.month - 1];
    return '$wd ${d.day} $mo ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _TimelineTile extends StatelessWidget {
  final String time;
  final String title;
  final bool isPrimary;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onOpenMaps;

  const _TimelineTile({
    required this.time,
    required this.title,
    required this.isPrimary,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor = selected
        ? color.withOpacity(0.9)
        : scheme.surfaceVariant.withOpacity(isPrimary ? 0.35 : 0.25);
    final textColor = selected ? Colors.white : scheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            time,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? color : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: selected ? color : (isPrimary ? color : scheme.outline),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            Container(
              width: 2,
              height: 64,
              color: scheme.outlineVariant,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onOpenMaps,
                    icon: Icon(Icons.open_in_new, size: 18, color: selected ? Colors.white : scheme.onSurfaceVariant),
                    tooltip: 'Open in Maps',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
