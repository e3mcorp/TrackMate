import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/tracker_details.dart';
import 'package:trackmate/screens/tracker_messages.dart';
import 'package:trackmate/screens/tracker_map.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_native_contact_picker_plus/flutter_native_contact_picker_plus.dart';
import 'package:flutter_native_contact_picker_plus/model/contact_model.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

class TrackerEditScreen extends StatefulWidget {
  final Tracker tracker;
  const TrackerEditScreen(this.tracker, {super.key});

  @override
  State<TrackerEditScreen> createState() => TrackerEditScreenState();
}

class TrackerEditScreenState extends State<TrackerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FlutterContactPickerPlus _contactPicker = FlutterContactPickerPlus();

  // ✅ CONTROLLER CORRETTO (no dispose needed)
  final SideMenuController _sideController = SideMenuController();

  // ✅ NIENTE DISPOSE - non è necessario in questo package
  // @override
  // void dispose() {
  //   _sideController.dispose(); // Non esiste
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      return _buildMobileLayout(localizations, theme, colorScheme);
    } else {
      return _buildDesktopLayout(localizations, theme, colorScheme);
    }
  }

  // ✅ LAYOUT MOBILE (drawer classico)
  Widget _buildMobileLayout(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('editTracker') ?? 'Edit Tracker'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      drawer: _buildClassicDrawer(localizations, theme, colorScheme),
      body: _buildMainContent(localizations, theme, colorScheme),
      floatingActionButton: _buildFloatingActionButton(localizations, colorScheme),
    );
  }

  // ✅ LAYOUT DESKTOP con SideMenu CORRETTO
  Widget _buildDesktopLayout(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      body: Row(
        children: [
          // ✅ SIDE MENU con API CORRETTA
          SideMenu(
            controller: _sideController,
            backgroundColor: colorScheme.primaryContainer,
            mode: SideMenuMode.open,
            hasResizer: true,
            // ✅ hasToggleButton NON ESISTE - rimosso

            builder: (data) {
              return SideMenuData(
                // ✅ HEADER PERSONALIZZATO
                header: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.gps_fixed,
                          color: colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations?.get('tracker') ?? 'Tracker',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ INDICATORI STATO
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusChip(
                            widget.tracker.isOnline ? 'Online' : 'Offline',
                            widget.tracker.isOnline ? Icons.wifi : Icons.wifi_off,
                            widget.tracker.isOnline ? Colors.green : Colors.orange,
                          ),
                          _buildStatusChip(
                            '${widget.tracker.battery}%',
                            _getBatteryIcon(),
                            _getBatteryColor(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ✅ ITEMS DEL MENU (senza badgeContent)
                items: [
                  const SideMenuItemDataTitle(
                    title: 'Commands',
                    titleStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => _showSpeedLimitDialog(),
                    title: '${localizations?.get('speedLimit') ?? 'Speed Limit'} ${widget.tracker.speedLimit > 0 ? '(${widget.tracker.speedLimit})' : ''}',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.speed, color: colorScheme.onPrimaryContainer),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => _showPowerAlarmCallDialog(),
                    title: '${localizations?.get('powerAlarmCall') ?? 'Power Alarm Call'} ${widget.tracker.powerAlarmCall ? '✓' : ''}',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.call, color: colorScheme.onPrimaryContainer),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => _showPowerAlarmSMSDialog(),
                    title: '${localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS'} ${widget.tracker.powerAlarmSMS ? '✓' : ''}',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.sms_outlined, color: colorScheme.onPrimaryContainer),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => _showSleepTimeDialog(),
                    title: '${localizations?.get('sleepTime') ?? 'Sleep Time'} ${widget.tracker.sleepLimit > 0 ? '(${widget.tracker.sleepLimit}m)' : ''}',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.mode_standby, color: colorScheme.onPrimaryContainer),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => _showFactoryResetDialog(),
                    title: localizations?.get('factoryReset') ?? 'Factory Reset',
                    titleStyle: TextStyle(color: colorScheme.error),
                    icon: Icon(Icons.delete_forever, color: colorScheme.error),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => widget.tracker.getTrackerInfo(),
                    title: localizations?.get('getInfo') ?? 'Get Info',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
                  ),

                  const SideMenuItemDataTitle(
                    title: 'Navigation',
                    titleStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackerMessageListScreen(widget.tracker),
                      ),
                    ),
                    title: '${localizations?.get('messages') ?? 'Messages'} ${widget.tracker.messages.isNotEmpty ? '(${widget.tracker.messages.length})' : ''}',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.sms_rounded, color: colorScheme.onPrimaryContainer),
                  ),

                  SideMenuItemDataTile(
                    isSelected: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackerDetailsScreen(widget.tracker),
                      ),
                    ),
                    title: localizations?.get('details') ?? 'Details',
                    titleStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                    icon: Icon(Icons.list, color: colorScheme.onPrimaryContainer),
                  ),
                ],

                // ✅ FOOTER
                footer: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _sideController.toggle();
                        },
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Toggle Menu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 36),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'TrackMate v1.0',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ✅ CONTENUTO PRINCIPALE
          Expanded(
            child: Column(
              children: [
                // AppBar desktop
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(Icons.gps_fixed, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        localizations?.get('editTracker') ?? 'Edit Tracker',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.tracker.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
                // Contenuto principale
                Expanded(
                  child: _buildMainContent(localizations, theme, colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(localizations, colorScheme),
    );
  }

  // ✅ HELPER PER STATUS CHIP
  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DRAWER CLASSICO per mobile (invariato)
  Widget _buildClassicDrawer(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gps_fixed,
                    color: colorScheme.onPrimary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  localizations?.get('tracker') ?? 'Tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _buildDrawerItem(Icons.speed, localizations?.get('speedLimit') ?? 'Speed Limit',
              widget.tracker.phoneNumber.isNotEmpty, _showSpeedLimitDialog, colorScheme,
              badge: widget.tracker.speedLimit > 0 ? '${widget.tracker.speedLimit}' : null),

          _buildDrawerItem(Icons.call, localizations?.get('powerAlarmCall') ?? 'Power Alarm Call',
              widget.tracker.phoneNumber.isNotEmpty, _showPowerAlarmCallDialog, colorScheme,
              isEnabled: widget.tracker.powerAlarmCall),

          _buildDrawerItem(Icons.sms_outlined, localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS',
              widget.tracker.phoneNumber.isNotEmpty, _showPowerAlarmSMSDialog, colorScheme,
              isEnabled: widget.tracker.powerAlarmSMS),

          _buildDrawerItem(Icons.mode_standby, localizations?.get('sleepTime') ?? 'Sleep Time',
              widget.tracker.phoneNumber.isNotEmpty, _showSleepTimeDialog, colorScheme,
              badge: widget.tracker.sleepLimit > 0 ? '${widget.tracker.sleepLimit}m' : null),

          _buildDrawerItem(Icons.delete_forever, localizations?.get('factoryReset') ?? 'Factory Reset',
              widget.tracker.phoneNumber.isNotEmpty, _showFactoryResetDialog, colorScheme,
              iconColor: colorScheme.error),

          _buildDrawerItem(Icons.info_outline, localizations?.get('getInfo') ?? 'Get Info',
              widget.tracker.phoneNumber.isNotEmpty, () => widget.tracker.getTrackerInfo(), colorScheme),

          const Divider(),

          _buildDrawerItem(Icons.sms_rounded, localizations?.get('messages') ?? 'Messages', true,
                  () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => TrackerMessageListScreen(widget.tracker),
              )), colorScheme,
              badge: widget.tracker.messages.isNotEmpty ? '${widget.tracker.messages.length}' : null),

          _buildDrawerItem(Icons.list, localizations?.get('details') ?? 'Details', true,
                  () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => TrackerDetailsScreen(widget.tracker),
              )), colorScheme),
        ],
      ),
    );
  }

  // ✅ HELPER PER DRAWER ITEMS (invariato)
  Widget _buildDrawerItem(IconData icon, String title, bool enabled, VoidCallback? onTap,
      ColorScheme colorScheme, {String? badge, bool? isEnabled, Color? iconColor}) {
    return ListTile(
      enabled: enabled,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: enabled ? (iconColor ?? colorScheme.onSurfaceVariant) : Colors.grey),
          if (isEnabled == true)
            Positioned(
              right: -4, top: -4,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
          if (badge != null)
            Positioned(
              right: -8, top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge, style: TextStyle(
                    color: colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
      onTap: enabled ? onTap : null,
    );
  }

  // ✅ CONTENUTO PRINCIPALE (invariato dal file precedente)
  Widget _buildMainContent(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormFields(localizations, theme, colorScheme),
            const SizedBox(height: 32),
            _buildActionButtons(localizations, theme, colorScheme),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ✅ FLOATING ACTION BUTTON (invariato)
  Widget? _buildFloatingActionButton(AppLocalizations? localizations, ColorScheme colorScheme) {
    if (widget.tracker.phoneNumber.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: () async {
        widget.tracker.requestLocation();
        if (context.mounted) {
          Modal.toast(context, localizations?.get('requestedPosition') ?? 'Position requested');
        }
      },
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      icon: const Icon(Icons.gps_fixed),
      label: Text(localizations?.get('requestPosition') ?? 'Request Position'),
    );
  }

  // ✅ HELPER METHODS PER BATTERIA
  Color _getBatteryColor() {
    if (widget.tracker.battery <= 20) return Colors.red;
    if (widget.tracker.battery <= 50) return Colors.orange;
    return Colors.green;
  }

  IconData _getBatteryIcon() {
    if (widget.tracker.battery <= 10) return Icons.battery_0_bar;
    if (widget.tracker.battery <= 20) return Icons.battery_1_bar;
    if (widget.tracker.battery <= 40) return Icons.battery_3_bar;
    if (widget.tracker.battery <= 60) return Icons.battery_4_bar;
    if (widget.tracker.battery <= 80) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  // ✅ TUTTI I FORM FIELDS E DIALOG METHODS rimangono identici
  Widget _buildFormFields(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        TextFormField(
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return localizations?.get('requiredField') ?? 'Required Field';
            }
            return null;
          },
          initialValue: widget.tracker.name,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.drive_file_rename_outline),
            labelText: localizations?.get('name') ?? 'Name',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => widget.tracker.name = value,
        ),
        const SizedBox(height: 16),

        TextFormField(
          initialValue: widget.tracker.licensePlate,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.document_scanner),
            labelText: localizations?.get('licensePlate') ?? 'License Plate',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => widget.tracker.licensePlate = value,
        ),
        const SizedBox(height: 16),

        TextFormField(
          initialValue: widget.tracker.chassisNumber,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_rental),
            labelText: localizations?.get('chassisNumber') ?? 'Chassis Number',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => widget.tracker.chassisNumber = value,
        ),
        const SizedBox(height: 16),

        TextFormField(
          initialValue: widget.tracker.model,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_repair),
            labelText: localizations?.get('model') ?? 'Model',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => widget.tracker.model = value,
        ),
        const SizedBox(height: 16),

        TextFormField(
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return localizations?.get('requiredField') ?? 'Required Field';
            }
            return null;
          },
          initialValue: widget.tracker.phoneNumber,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone),
            labelText: localizations?.get('phoneNumber') ?? 'Phone Number',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(Icons.contact_phone, color: colorScheme.onSurfaceVariant),
              onPressed: _selectContact,
            ),
          ),
          onChanged: (value) => widget.tracker.phoneNumber = value,
        ),
        const SizedBox(height: 16),

        TextFormField(
          initialValue: widget.tracker.pin,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.password),
            labelText: localizations?.get('pin') ?? 'PIN',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) => widget.tracker.pin = value,
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 0,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.palette),
            title: Text(localizations?.get('color') ?? 'Color'),
            trailing: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Color(widget.tracker.color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            onTap: _showColorPicker,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.save, size: 24),
            label: Text(localizations?.get('save') ?? 'Save'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveTracker,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.timeline, size: 22),
            label: Text(localizations?.get('history') ?? 'History'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => TrackerPositionMapScreen(widget.tracker),
            )),
          ),
        ),
      ],
    );
  }

  // ✅ TUTTI I DIALOG E METODI HELPER rimangono identici al file precedente
  Future<void> _showSpeedLimitDialog() async {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    int speed = widget.tracker.speedLimit;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.speed, color: colorScheme.primary),
        title: Text(localizations?.get('speedLimit') ?? 'Speed Limit'),
        content: TextFormField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          controller: TextEditingController(text: speed.toString()),
          onChanged: (value) => speed = int.tryParse(value) ?? speed,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'km/h'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.get('cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              widget.tracker.setSpeedLimit(speed);
              await _updateTracker();
              Navigator.pop(context);
            },
            child: Text(localizations?.get('ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPowerAlarmCallDialog() async {
    final localizations = AppLocalizations.of(context);
    Modal.question(
      context,
      localizations?.get('powerAlarmCall') ?? 'Power Alarm Call',
      [
        ModalOption(localizations?.get('yes') ?? 'Yes', () async {
          widget.tracker.setPowerAlarmCall(true);
          await _updateTracker();
          Navigator.pop(context);
        }),
        ModalOption(localizations?.get('no') ?? 'No', () async {
          widget.tracker.setPowerAlarmCall(false);
          await _updateTracker();
          Navigator.pop(context);
        }),
      ],
    );
  }

  Future<void> _showPowerAlarmSMSDialog() async {
    final localizations = AppLocalizations.of(context);
    Modal.question(
      context,
      localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS',
      [
        ModalOption(localizations?.get('yes') ?? 'Yes', () async {
          widget.tracker.setPowerAlarmSMS(true);
          await _updateTracker();
          Navigator.pop(context);
        }),
        ModalOption(localizations?.get('no') ?? 'No', () async {
          widget.tracker.setPowerAlarmSMS(false);
          await _updateTracker();
          Navigator.pop(context);
        }),
      ],
    );
  }

  Future<void> _showSleepTimeDialog() async {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    int time = widget.tracker.sleepLimit;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.mode_standby, color: colorScheme.primary),
        title: Text(localizations?.get('sleepLimit') ?? 'Sleep Limit'),
        content: TextFormField(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          controller: TextEditingController(text: time.toString()),
          onChanged: (value) => time = int.tryParse(value) ?? time,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations?.get('cancel') ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              widget.tracker.setSleepTime(time);
              await _updateTracker();
              Navigator.pop(context);
            },
            child: Text(localizations?.get('ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFactoryResetDialog() async {
    final localizations = AppLocalizations.of(context);
    Modal.confirm(
      context,
      localizations?.get('warning') ?? 'Warning',
      localizations?.get('confirmFactoryReset') ?? 'Are you sure you want to reset tracker?',
      onConfirm: () => widget.tracker.factoryReset(),
    );
  }

  Future<void> _selectContact() async {
    try {
      Contact? contact = await _contactPicker.selectPhoneNumber();
      if (contact?.selectedPhoneNumber != null) {
        setState(() {
          widget.tracker.phoneNumber = contact!.selectedPhoneNumber!;
        });
      } else if (contact?.phoneNumbers != null && contact!.phoneNumbers!.isNotEmpty) {
        setState(() {
          widget.tracker.phoneNumber = contact.phoneNumbers!.first;
        });
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting contact: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleziona Colore'),
        content: SingleChildScrollView(
          child: MaterialPicker(
            pickerColor: Color(widget.tracker.color),
            onColorChanged: (color) => setState(() {
              widget.tracker.color = color.value;
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTracker() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _updateTracker();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _updateTracker() async {
    try {
      final db = await DataBase.get();
      await TrackerDB.update(db!, widget.tracker);
    } catch (e) {
      debugPrint('Error updating tracker: $e');
      if (context.mounted) {
        final localizations = AppLocalizations.of(context);
        Modal.toast(context, localizations?.get('errorSaving') ?? 'Error saving');
      }
    }
  }
}
