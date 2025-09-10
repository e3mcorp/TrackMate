import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/tracker_history.dart';
import 'package:trackmate/screens/tracker_messages.dart';
import 'package:trackmate/utils/sms.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_native_contact_picker_plus/flutter_native_contact_picker_plus.dart';
import 'package:flutter_native_contact_picker_plus/model/contact_model.dart';
import 'package:intl/intl.dart';

class TrackerDetailsScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerDetailsScreen(this.tracker, {super.key});

  @override
  State<TrackerDetailsScreen> createState() => _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState extends State<TrackerDetailsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FlutterContactPickerPlus _contactPicker = FlutterContactPickerPlus();

  // Tab controller per le 3 schede
  late final TabController _tabController;
  bool _isEditMode = false;

  // Controllers per i campi editabili
  late final TextEditingController _nameController;
  late final TextEditingController _licensePlateController;
  late final TextEditingController _chassisNumberController;
  late final TextEditingController _modelController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _pinController;
  late final TextEditingController _adminNumberController;
  late final TextEditingController _sosNumbersController;

  @override
  void initState() {
    super.initState();

    // ✅ Inizializza TabController con 3 schede
    _tabController = TabController(length: 3, vsync: this);

    // Inizializza i controllers
    _nameController = TextEditingController(text: widget.tracker.name);
    _licensePlateController = TextEditingController(text: widget.tracker.licensePlate);
    _chassisNumberController = TextEditingController(text: widget.tracker.chassisNumber);
    _modelController = TextEditingController(text: widget.tracker.model);
    _phoneNumberController = TextEditingController(text: widget.tracker.phoneNumber);
    _pinController = TextEditingController(text: widget.tracker.pin);
    _adminNumberController = TextEditingController(text: widget.tracker.adminNumber);
    _sosNumbersController = TextEditingController(text: _listToString(widget.tracker.sosNumbers));

    // ✅ Listener per cambiamenti di tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isEditMode = false; // Exit edit mode when changing tabs
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _licensePlateController.dispose();
    _chassisNumberController.dispose();
    _modelController.dispose();
    _phoneNumberController.dispose();
    _pinController.dispose();
    _adminNumberController.dispose();
    _sosNumbersController.dispose();
    super.dispose();
  }

  String _listToString(List<String> list) {
    return list.where((s) => s.isNotEmpty).join(', ');
  }

  List<String> _stringToList(String value) {
    if (value.isEmpty) return [];
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.tracker.name),
        centerTitle: false,
        actions: [
          // Quick actions sempre visibili
          IconButton(
            icon: const Icon(Icons.gps_fixed),
            onPressed: _requestPosition,
            tooltip: 'Richiedi posizione',
          ),
          if (_tabController.index == 0) // Solo in Overview
            IconButton(
              icon: Icon(_isEditMode ? Icons.save : Icons.edit),
              onPressed: _isEditMode ? _saveChanges : _toggleEditMode,
              tooltip: _isEditMode ? 'Save' : 'Edit',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: Text(localizations?.get('getInfo') ?? 'Get Info'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'factory_reset',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: colorScheme.error),
                  title: Text(localizations?.get('factoryReset') ?? 'Factory Reset'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        // ✅ TabBar nel bottom dell'AppBar
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard_outlined),
              text: localizations?.get('overview') ?? 'Overview',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: widget.tracker.messages.isNotEmpty,
                label: Text('${widget.tracker.messages.length}'),
                child: const Icon(Icons.message_outlined),
              ),
              text: localizations?.get('messages') ?? 'Messages',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: widget.tracker.positions.isNotEmpty,
                label: Text('${widget.tracker.positions.length}'),
                child: const Icon(Icons.history_outlined),
              ),
              text: localizations?.get('history') ?? 'History',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewView(), // Tab 0: Overview
            _buildMessagesView(),  // Tab 1: Messages
            _buildHistoryView(),   // Tab 2: History
          ],
        ),
      ),
      //floatingActionButton: _buildContextualFab(),
    );
  }

  // ===== CONTEXTUAL FAB =====
  Widget? _buildContextualFab() {
    final localizations = AppLocalizations.of(context);
    switch (_tabController.index) {
      case 1: // Messages view
        return FloatingActionButton.extended(
          onPressed: _sendCustomMessage,
          icon: const Icon(Icons.send),
          label: Text(localizations?.get('sendSMS') ?? 'Send SMS'),
        );
      case 2: // History view
        return FloatingActionButton(
          onPressed: () => widget.tracker.requestLocation(),
          child: const Icon(Icons.gps_fixed),
          tooltip: 'Request Position',
        );
      default:
        return null;
    }
  }

  // ===== OVERVIEW TAB =====
  Widget _buildOverviewView() {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isEditMode) {
      return _buildEditView(localizations, theme, colorScheme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status Card prominente
          //_buildStatusCard(localizations, theme, colorScheme),
          //const SizedBox(height: 16),

          // Device Info
          _buildDeviceInfoSection(localizations, theme, colorScheme),
          const SizedBox(height: 16),

          // Technical Info
          _buildTechnicalInfoSection(localizations, theme, colorScheme),
          const SizedBox(height: 16),

          // Settings Preview
          _buildSettingsPreview(localizations, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Status indicator
                const Spacer(),
                Text(
                  _formatDateTime(widget.tracker.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Battery and key metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    icon: _getBatteryIcon(),
                    label: 'Battery',
                    value: '${widget.tracker.battery}%',
                    color: _getBatteryColor(widget.tracker.battery, colorScheme),
                  ),
                ),
                _buildDivider(colorScheme),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.message,
                    label: 'Messages',
                    value: '${widget.tracker.messages.length}',
                    color: colorScheme.primary,
                  ),
                ),
                _buildDivider(colorScheme),
                Expanded(
                  child: _buildMetricItem(
                    icon: Icons.location_on,
                    label: 'Positions',
                    value: '${widget.tracker.positions.length}',
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      width: 1,
      height: 40,
      color: colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }



  // ===== MESSAGES TAB =====
  Widget _buildMessagesView() {
    // ✅ Passa parametri per embedded mode se il widget lo supporta
    return TrackerMessageListScreen(widget.tracker);
  }

  // ===== HISTORY TAB =====
  Widget _buildHistoryView() {
    // ✅ Passa parametri per embedded mode se il widget lo supporta
    return TrackerHistoryScreen(widget.tracker);
  }

  // ===== DEVICE INFO SECTION =====
  Widget _buildDeviceInfoSection(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('deviceInfo') ?? 'Device Information',
      icon: Icons.devices,
      color: colorScheme.secondary,
      children: [
        _buildReadOnlyField(
          localizations?.get('name') ?? 'Name',
          widget.tracker.name,
          Icons.drive_file_rename_outline,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('phoneNumber') ?? 'Phone Number',
          widget.tracker.phoneNumber,
          Icons.phone,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('licensePlate') ?? 'License Plate',
          widget.tracker.licensePlate.isEmpty ? '-' : widget.tracker.licensePlate,
          Icons.document_scanner,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('model') ?? 'Model',
          widget.tracker.model.isEmpty ? '-' : widget.tracker.model,
          Icons.car_repair,
          theme,
          colorScheme,
        ),
      ],
    );
  }

  // ===== TECHNICAL INFO SECTION =====
  Widget _buildTechnicalInfoSection(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('technicalInfo') ?? 'Technical Information',
      icon: Icons.memory,
      color: colorScheme.tertiary,
      children: [
        _buildReadOnlyField(
          localizations?.get('id') ?? 'ID',
          widget.tracker.id,
          Icons.perm_identity,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('imei') ?? 'IMEI',
          widget.tracker.id.isEmpty ? '-' : widget.tracker.id,
          Icons.fingerprint,
          theme,
          colorScheme,
          monospace: true,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('apn') ?? 'APN',
          widget.tracker.apn.isEmpty ? '-' : widget.tracker.apn,
          Icons.network_cell,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('iccid') ?? 'ICCID',
          widget.tracker.iccid.isEmpty ? '-' : widget.tracker.iccid,
          Icons.sim_card,
          theme,
          colorScheme,
          monospace: true,
        ),
      ],
    );
  }

  // ===== SETTINGS PREVIEW SECTION =====
  Widget _buildSettingsPreview(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('alarms') ?? 'Alarms & Settings',
      icon: Icons.settings,
      color: colorScheme.primary,
      children: [
        _buildBatteryField(localizations, theme, colorScheme),
        const SizedBox(height: 16),
        _buildSimpleAlarmTile(
          localizations?.get('ignitionAlarm') ?? 'Ignition Alarm',
          widget.tracker.ignitionAlarm,
          Icons.car_repair,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 8),
        _buildSimpleAlarmTile(
          localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS',
          widget.tracker.powerAlarmSMS,
          Icons.sms_failed,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('lastUpdate') ?? 'Last Update',
          _formatDateTime(widget.tracker.timestamp),
          Icons.schedule,
          theme,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildSimpleAlarmTile(String title, bool value, IconData icon, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value ? 'ON' : 'OFF',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ===== EDIT VIEW =====
  Widget _buildEditView(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditableFormFields(localizations, theme, colorScheme),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: Text(localizations?.get('cancel') ?? 'Cancel'),
                    onPressed: _cancelEdit,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(localizations?.get('save') ?? 'Save'),
                    onPressed: _saveChanges,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableFormFields(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Basic Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.get('basicInfo') ?? 'Basic Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localizations?.get('requiredField') ?? 'Required field';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.drive_file_rename_outline),
                    labelText: localizations?.get('name') ?? 'Name',
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return localizations?.get('requiredField') ?? 'Required field';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone),
                    labelText: localizations?.get('phoneNumber') ?? 'Phone Number',
                    filled: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contact_phone),
                      onPressed: _selectContact,
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licensePlateController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.document_scanner),
                    labelText: localizations?.get('licensePlate') ?? 'License Plate',
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.car_repair),
                    labelText: localizations?.get('model') ?? 'Model',
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Security Settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.get('securitySettings') ?? 'Security Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adminNumberController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.contact_phone),
                    labelText: localizations?.get('adminNumber') ?? 'Admin Number',
                    filled: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contact_phone),
                      onPressed: () => _selectContact(isAdmin: true),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sosNumbersController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.emergency),
                    labelText: localizations?.get('sosNumbers') ?? 'SOS Numbers',
                    helperText: localizations?.get('sosNumbersHelp') ?? 'Separate numbers with commas',
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.password),
                    labelText: localizations?.get('pin') ?? 'PIN',
                    filled: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Appearance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.get('appearance') ?? 'Appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(localizations?.get('color') ?? 'Color'),
                  trailing: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(widget.tracker.color),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outline),
                    ),
                  ),
                  onTap: _showColorPicker,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===== HELPER WIDGETS =====
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
      String label,
      String value,
      IconData icon,
      ThemeData theme,
      ColorScheme colorScheme, {
        bool monospace = false,
      }) {
    return TextFormField(
      enabled: false,
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
    );
  }

  Widget _buildBatteryField(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    final batteryColor = _getBatteryColor(widget.tracker.battery, colorScheme);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: batteryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: batteryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.tracker.battery <= 20
                ? Icons.battery_alert
                : widget.tracker.battery <= 50
                ? Icons.battery_3_bar
                : Icons.battery_full,
            color: batteryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations?.get('battery') ?? 'Battery',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${widget.tracker.battery}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: batteryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: widget.tracker.battery / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: batteryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== HELPER METHODS =====
  IconData _getBatteryIcon() {
    final battery = widget.tracker.battery;
    if (battery <= 20) return Icons.battery_alert;
    if (battery <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  Color _getBatteryColor(int battery, ColorScheme colorScheme) {
    if (battery > 50) return colorScheme.primary;
    if (battery > 20) return colorScheme.tertiary;
    return colorScheme.error;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy - HH:mm:ss').format(dateTime);
  }

  void _requestPosition() {
    widget.tracker.requestLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Position requested'),
        action: SnackBarAction(
          label: 'View Messages',
          onPressed: () => _tabController.animateTo(1), // ✅ Vai alla tab Messages
        ),
      ),
    );
  }

  void _sendCustomMessage() {
    showDialog(
      context: context,
      builder: (context) {
        String message = '';
        return AlertDialog(
          title: const Text('Send Custom SMS'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter command...',
            ),
            onChanged: (value) => message = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (message.isNotEmpty) {
                  widget.tracker.sendSMS(message);
                }
                Navigator.pop(context);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  // ===== ACTION METHODS =====
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _cancelEdit() {
    // Reset controllers to original values
    _nameController.text = widget.tracker.name;
    _licensePlateController.text = widget.tracker.licensePlate;
    _chassisNumberController.text = widget.tracker.chassisNumber;
    _modelController.text = widget.tracker.model;
    _phoneNumberController.text = widget.tracker.phoneNumber;
    _pinController.text = widget.tracker.pin;
    _adminNumberController.text = widget.tracker.adminNumber;
    _sosNumbersController.text = _listToString(widget.tracker.sosNumbers);

    setState(() {
      _isEditMode = false;
    });
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // Update tracker object
      widget.tracker.name = _nameController.text;
      widget.tracker.licensePlate = _licensePlateController.text;
      widget.tracker.chassisNumber = _chassisNumberController.text;
      widget.tracker.model = _modelController.text;
      widget.tracker.phoneNumber = _phoneNumberController.text;
      widget.tracker.pin = _pinController.text;
      widget.tracker.adminNumber = _adminNumberController.text;
      widget.tracker.sosNumbers = _stringToList(_sosNumbersController.text);

      // Save to database
      final db = await DataBase.get();
      await TrackerDB.update(db!, widget.tracker);

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.get('savedSuccessfully') ?? 'Saved successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        setState(() {
          _isEditMode = false;
        });
      }
    } catch (e) {
      debugPrint('Error updating tracker: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.get('errorSaving') ?? 'Error saving'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        widget.tracker.getTrackerInfo();
        break;
      case 'factory_reset':
        _showFactoryResetDialog();
        break;
    }
  }

  Future<void> _selectContact({bool isAdmin = false}) async {
    try {
      Contact? contact = await _contactPicker.selectPhoneNumber();
      if (contact?.selectedPhoneNumber != null) {
        setState(() {
          if (isAdmin) {
            _adminNumberController.text = contact!.selectedPhoneNumber!;
          } else {
            _phoneNumberController.text = contact!.selectedPhoneNumber!;
          }
        });
      } else if (contact?.phoneNumbers != null && contact!.phoneNumbers!.isNotEmpty) {
        setState(() {
          if (isAdmin) {
            _adminNumberController.text = contact.phoneNumbers!.first;
          } else {
            _phoneNumberController.text = contact.phoneNumbers!.first;
          }
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
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
        title: Text(AppLocalizations.of(context)?.get('selectColor') ?? 'Select Color'),
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
            child: Text(AppLocalizations.of(context)?.get('ok') ?? 'OK'),
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
}
