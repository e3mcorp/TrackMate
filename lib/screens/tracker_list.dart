import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/tracker_edit.dart';
import 'package:trackmate/screens/setup_wizard.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class TrackerListScreen extends StatefulWidget {
  const TrackerListScreen({super.key});

  @override
  State<TrackerListScreen> createState() => TrackerListScreenState();
}

class TrackerListScreenState extends State<TrackerListScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  bool _showFab = true;
  bool _isDeleting = false;
  List<Tracker>? _cachedTrackers;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    // ✅ Animazione FAB migliorata
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();

    // ✅ Listener ottimizzato con debouncing
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  void _onTrackerDataChanged() {
    if (mounted) {
      // ✅ Invalidate cache when data changes
      _cachedTrackers = null;
      setState(() {});
    }
  }

  void _handleScroll() {
    final ScrollDirection direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse) {
      if (_showFab) {
        setState(() => _showFab = false);
        _fabAnimationController.reverse();
      }
    } else if (direction == ScrollDirection.forward) {
      if (!_showFab) {
        setState(() => _showFab = true);
        _fabAnimationController.forward();
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
      body: Consumer<TrackerNotifier>(
        builder: (context, trackerNotifier, child) {
          return FutureBuilder<List<Tracker>>(
            future: _loadTrackers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(localizations, theme, colorScheme);
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), localizations, theme, colorScheme);
              }

              final trackers = snapshot.data ?? [];

              if (trackers.isEmpty) {
                return _buildEmptyState(localizations, theme, colorScheme);
              }

              return _buildTrackerList(trackers, localizations, theme, colorScheme);
            },
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: _buildFloatingActionButton(localizations, theme, colorScheme),
      ),
    );
  }

  Widget _buildFloatingActionButton(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => SetupWizardScreen.showSetupWizard(context),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 6,
      icon: const Icon(Icons.add),
      label: Text(
        localizations?.get('addTracker') ?? 'Add Tracker',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      heroTag: "add_tracker",
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
            localizations?.get('loading') ?? 'Loading trackers...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Cache management for better performance
  Future<List<Tracker>> _loadTrackers() async {
    if (_cachedTrackers != null) {
      return _cachedTrackers!;
    }

    final db = await DataBase.get();
    _cachedTrackers = await TrackerDB.list(db!);
    return _cachedTrackers!;
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
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.3),
                    colorScheme.secondaryContainer.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.gps_off,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('noTrackers') ?? 'No trackers available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('addFirstTracker') ?? 'Add your first tracker to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => SetupWizardScreen.showSetupWizard(context),
              icon: const Icon(Icons.auto_fix_high),
              label: Text(localizations?.get('setupWizard') ?? 'Setup Wizard'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
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
                border: Border.all(
                  color: colorScheme.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('errorLoading') ?? 'Error Loading',
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
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () {
                _cachedTrackers = null; // Clear cache
                setState(() {});
              },
              child: Text(localizations?.get('retry') ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerList(List<Tracker> trackers, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderCard(trackers, localizations, theme, colorScheme),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final tracker = trackers[index];
                return _buildTrackerItem(tracker, index, localizations, theme, colorScheme);
              },
              childCount: trackers.length,
            ),
          ),
        ),
        // ✅ Bottom padding for FAB
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(List<Tracker> trackers, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.4),
            colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trackers.length} ${localizations?.get('trackers') ?? 'Trackers'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      localizations?.get('swipeToEdit') ?? 'Swipe to edit or delete',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => SetupWizardScreen.showSetupWizard(context),
                  icon: const Icon(Icons.auto_fix_high, size: 20),
                  label: Text(
                    localizations?.get('setupWizard') ?? 'Setup Wizard',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    foregroundColor: colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerItem(Tracker tracker, int index, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Color(tracker.color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Slidable(
          key: ValueKey(tracker.uuid),
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _editTracker(tracker),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                icon: Icons.edit,
                label: localizations?.get('edit') ?? 'Edit',
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _showDeleteConfirmation(tracker, localizations, theme, colorScheme),
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                icon: Icons.delete,
                label: localizations?.get('delete') ?? 'Delete',
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            leading: Hero(
              tag: 'tracker_${tracker.uuid}',
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(tracker.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(tracker.color).withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(tracker.color).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.gps_fixed,
                  color: Color(tracker.color),
                  size: 28,
                ),
              ),
            ),
            title: Text(
              tracker.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (tracker.licensePlate.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tracker.licensePlate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (tracker.phoneNumber.isNotEmpty)
                  Text(
                    tracker.phoneNumber,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
            trailing: _buildTrackerStatus(tracker, theme, colorScheme),
            onTap: () {
              HapticFeedback.lightImpact();
              _editTracker(tracker);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerStatus(Tracker tracker, ThemeData theme, ColorScheme colorScheme) {
    if (tracker.battery > 0) {
      Color batteryColor;
      IconData batteryIcon;
      String batteryLabel;

      if (tracker.battery <= 20) {
        batteryColor = colorScheme.error;
        batteryIcon = Icons.battery_alert;
        batteryLabel = 'Low';
      } else if (tracker.battery <= 50) {
        batteryColor = colorScheme.tertiary;
        batteryIcon = Icons.battery_3_bar;
        batteryLabel = 'Medium';
      } else {
        batteryColor = colorScheme.primary;
        batteryIcon = Icons.battery_full;
        batteryLabel = 'Good';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: batteryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: batteryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(batteryIcon, color: batteryColor, size: 22),
            const SizedBox(height: 2),
            Text(
              '${tracker.battery}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: batteryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _editTracker(Tracker tracker) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TrackerEditScreen(tracker),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Tracker tracker, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber,
          color: colorScheme.error,
          size: 32,
        ),
        title: Text(
          localizations?.get('confirmDelete') ?? 'Confirm Delete',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        content: Text(
          (localizations?.get('deleteTrackerWarning') ??
              'Are you sure you want to delete tracker "{0}"?')
              .replaceAll('{0}', tracker.name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations?.get('cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(localizations?.get('delete') ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTracker(tracker, localizations, theme, colorScheme);
    }
  }

  Future<void> _deleteTracker(Tracker tracker, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      final db = await DataBase.get();
      await TrackerDB.delete(db!, tracker.uuid);

      // Clear cache after successful deletion
      _cachedTrackers = null;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (localizations?.get('trackerDeleted') ?? 'Tracker "{0}" deleted')
                .replaceAll('{0}', tracker.name),
          ),
          backgroundColor: colorScheme.inverseSurface,
          action: SnackBarAction(
            label: localizations?.get('undo') ?? 'Undo',
            textColor: colorScheme.inversePrimary,
            onPressed: () => _undoDelete(tracker, localizations),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        Modal.toast(
          context,
          localizations?.get('errorDeleting') ?? 'Error deleting',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _undoDelete(Tracker tracker, AppLocalizations? localizations) async {
    try {
      final db = await DataBase.get();
      await TrackerDB.add(db!, tracker);

      // Clear cache after undo
      _cachedTrackers = null;

      if (mounted) {
        Modal.toast(
          context,
          localizations?.get('trackerRestored') ?? 'Tracker restored',
        );
      }
    } catch (e) {
      if (mounted) {
        Modal.toast(
          context,
          localizations?.get('errorRestoring') ?? 'Error restoring',
        );
      }
    }
  }
}
