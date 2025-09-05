import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker_plus/flutter_native_contact_picker_plus.dart';
import 'package:flutter_native_contact_picker_plus/model/contact_model.dart';
import 'package:intl/intl.dart';


class TrackerDetailsScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerDetailsScreen(this.tracker, {super.key});

  @override
  State<TrackerDetailsScreen> createState() => TrackerDetailsScreenState();
}

class TrackerDetailsScreenState extends State<TrackerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FlutterContactPickerPlus _contactPicker = FlutterContactPickerPlus();

  // ✅ Controllers gestiti correttamente
  late final TextEditingController _adminNumberController;
  late final TextEditingController _sosNumbersController;
  late final TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _adminNumberController = TextEditingController(text: widget.tracker.adminNumber);
    _sosNumbersController = TextEditingController(text: _listToString(widget.tracker.sosNumbers));
    _pinController = TextEditingController(text: widget.tracker.pin);
  }

  @override
  void dispose() {
    _adminNumberController.dispose();
    _sosNumbersController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _listToString(List<String> list) {
    return list.join(', ');
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
        title: Text(localizations?.get('trackerDetails') ?? 'Tracker Details'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEditableSection(localizations, theme, colorScheme),
              const SizedBox(height: 32),
              _buildDeviceInfoSection(localizations, theme, colorScheme),
              const SizedBox(height: 32),
              _buildTechnicalInfoSection(localizations, theme, colorScheme),
              const SizedBox(height: 32),
              _buildOperationalSection(localizations, theme, colorScheme),
              const SizedBox(height: 32),
              _buildAlarmsSection(localizations, theme, colorScheme),
              const SizedBox(height: 32),
              _buildActionButtons(localizations, theme, colorScheme),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSection(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('editableSettings') ?? 'Editable Settings',
      icon: Icons.edit,
      color: colorScheme.primary,
      children: [
        TextFormField(
          controller: _adminNumberController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.contact_phone),
            labelText: localizations?.get('adminNumber') ?? 'Admin Number',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.contact_phone, color: colorScheme.onSurfaceVariant),
              onPressed: _selectContact,
              tooltip: localizations?.get('selectContact') ?? 'Select Contact',
            ),
          ),
          onChanged: (value) => widget.tracker.adminNumber = value,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _sosNumbersController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.emergency),
            labelText: localizations?.get('sosNumbers') ?? 'SOS Numbers',
            helperText: localizations?.get('sosNumbersHelp') ?? 'Separate numbers with commas',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
          onChanged: (value) => widget.tracker.sosNumbers = _stringToList(value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pinController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.password),
            labelText: localizations?.get('pin') ?? 'PIN',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => widget.tracker.pin = value,
        ),
      ],
    );
  }

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
          widget.tracker.licensePlate,
          Icons.document_scanner,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('chassisNumber') ?? 'Chassis Number',
          widget.tracker.chassisNumber,
          Icons.car_rental,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('model') ?? 'Model',
          widget.tracker.model,
          Icons.car_repair,
          theme,
          colorScheme,
        ),
      ],
    );
  }

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
          localizations?.get('uuid') ?? 'UUID',
          widget.tracker.uuid,
          Icons.fingerprint,
          theme,
          colorScheme,
          monospace: true,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('apn') ?? 'APN',
          widget.tracker.apn,
          Icons.network_cell,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('iccid') ?? 'ICCID',
          widget.tracker.iccid,
          Icons.sim_card,
          theme,
          colorScheme,
          monospace: true,
        ),
      ],
    );
  }

  Widget _buildOperationalSection(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('operationalSettings') ?? 'Operational Settings',
      icon: Icons.settings,
      color: colorScheme.primary,
      children: [
        _buildReadOnlyField(
          localizations?.get('speedLimit') ?? 'Speed Limit',
          '${widget.tracker.speedLimit} km/h',
          Icons.speed,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildReadOnlyField(
          localizations?.get('sleepLimit') ?? 'Sleep Limit',
          '${widget.tracker.sleepLimit} min',
          Icons.mode_standby,
          theme,
          colorScheme,
        ),
        const SizedBox(height: 16),
        _buildBatteryField(localizations, theme, colorScheme),
        const SizedBox(height: 16),
        _buildColorField(localizations, theme, colorScheme),
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

  Widget _buildAlarmsSection(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return _buildSection(
      title: localizations?.get('alarms') ?? 'Alarms',
      icon: Icons.alarm,
      color: colorScheme.error,
      children: [
        _buildAlarmTile(
          localizations?.get('ignitionAlarm') ?? 'Ignition Alarm',
          widget.tracker.ignitionAlarm,
          Icons.car_repair,
          theme,
          colorScheme,
        ),
        _buildAlarmTile(
          localizations?.get('powerAlarmCall') ?? 'Power Alarm Call',
          widget.tracker.powerAlarmCall,
          Icons.call,
          theme,
          colorScheme,
        ),
        _buildAlarmTile(
          localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS',
          widget.tracker.powerAlarmSMS,
          Icons.sms_failed,
          theme,
          colorScheme,
        ),
      ],
    );
  }

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

  Widget _buildColorField(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.palette),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations?.get('trackerColor') ?? 'Tracker Color',
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(widget.tracker.color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline,
                width: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmTile(String title, bool value, IconData icon, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: value ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.save, size: 24),
        label: Text(localizations?.get('saveChanges') ?? 'Save Changes'),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _saveTracker,
      ),
    );
  }

  Future<void> _selectContact() async {
    try {
      Contact? contact = await _contactPicker.selectPhoneNumber();
      if (contact?.selectedPhoneNumber != null) {
        setState(() {
          widget.tracker.adminNumber = contact!.selectedPhoneNumber!;
          _adminNumberController.text = contact.selectedPhoneNumber!;
        });
      } else if (contact?.phoneNumbers != null && contact!.phoneNumbers!.isNotEmpty) {
        setState(() {
          widget.tracker.adminNumber = contact.phoneNumbers!.first;
          _adminNumberController.text = contact.phoneNumbers!.first;
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

  Color _getBatteryColor(int battery, ColorScheme colorScheme) {
    if (battery > 50) return colorScheme.primary;
    if (battery > 20) return colorScheme.tertiary;
    return colorScheme.error;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy - HH:mm:ss').format(dateTime);
  }

  Future<void> _saveTracker() async {
    try {
      final db = await DataBase.get();
      await TrackerDB.update(db!, widget.tracker);

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        Modal.toast(
          context,
          localizations?.get('savedSuccessfully') ?? 'Saved successfully',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating tracker: $e');
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        Modal.toast(
          context,
          localizations?.get('errorSaving') ?? 'Error saving',
        );
      }
    }
  }
}
