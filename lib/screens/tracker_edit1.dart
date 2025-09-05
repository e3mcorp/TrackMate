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


class TrackerEditScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerEditScreen(this.tracker, {super.key});

  @override
  State<TrackerEditScreen> createState() => TrackerEditScreenState();
}

class TrackerEditScreenState extends State<TrackerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FlutterContactPickerPlus _contactPicker = FlutterContactPickerPlus();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('editTracker') ?? 'Edit Tracker'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      drawer: _buildDrawer(localizations, theme, colorScheme),
      // ✅ SOLUZIONE: Usa SingleChildScrollView invece di ListView
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form fields
              _buildFormFields(localizations, theme, colorScheme),

              const SizedBox(height: 32), // Spazio prima dei pulsanti

              // ✅ Pulsanti dentro la scroll view (non più in Card separata)
              _buildActionButtons(localizations, theme, colorScheme),

              // ✅ Spazio extra per evitare che i pulsanti siano troppo in basso
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // FloatingActionButton rimane fuori dalla scroll view
      floatingActionButton: widget.tracker.phoneNumber.isEmpty
          ? null
          : FloatingActionButton(
        tooltip: localizations?.get('requestPosition') ?? 'Request Position',
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        onPressed: () async {
          widget.tracker.requestLocation();
          if (context.mounted) {
            Modal.toast(
              context,
              localizations?.get('requestedPosition') ?? 'Position requested',
            );
          }
        },
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }

  Widget _buildFormFields(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        // Campo Nome (obbligatorio)
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => widget.tracker.name = value,
        ),
        const SizedBox(height: 16),

        // Campo Targa
        TextFormField(
          initialValue: widget.tracker.licensePlate,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.document_scanner),
            labelText: localizations?.get('licensePlate') ?? 'License Plate',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => widget.tracker.licensePlate = value,
        ),
        const SizedBox(height: 16),

        // Campo Telaio
        TextFormField(
          initialValue: widget.tracker.chassisNumber,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_rental),
            labelText: localizations?.get('chassisNumber') ?? 'Chassis Number',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => widget.tracker.chassisNumber = value,
        ),
        const SizedBox(height: 16),

        // Campo Modello
        TextFormField(
          initialValue: widget.tracker.model,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.car_repair),
            labelText: localizations?.get('model') ?? 'Model',
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) => widget.tracker.model = value,
        ),
        const SizedBox(height: 16),

        // Campo Telefono (obbligatorio)
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.contact_phone, color: colorScheme.onSurfaceVariant),
              onPressed: _selectContact,
            ),
          ),
          onChanged: (value) => widget.tracker.phoneNumber = value,
        ),
        const SizedBox(height: 16),

        // Campo PIN
        TextFormField(
          initialValue: widget.tracker.pin,
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
        const SizedBox(height: 16),

        // Selettore Colore
        Card(
          elevation: 0,
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Pulsante Save
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.save, size: 24),
            label: Text(localizations?.get('save') ?? 'Save'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saveTracker,
          ),
        ),
        const SizedBox(height: 12),

        // Pulsante History
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.timeline, size: 22),
            label: Text(localizations?.get('history') ?? 'History'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackerPositionMapScreen(widget.tracker),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Center(
              child: Text(
                localizations?.get('tracker') ?? 'Tracker',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Opzioni del drawer con icone colorate
          _buildDrawerOption(
            Icons.speed,
            localizations?.get('speedLimit') ?? 'Speed Limit',
            colorScheme.onSurfaceVariant,
            widget.tracker.phoneNumber.isNotEmpty,
            _showSpeedLimitDialog,
          ),
          _buildDrawerOption(
            Icons.call,
            localizations?.get('powerAlarmCall') ?? 'Power Alarm Call',
            colorScheme.onSurfaceVariant,
            widget.tracker.phoneNumber.isNotEmpty,
            _showPowerAlarmCallDialog,
          ),
          _buildDrawerOption(
            Icons.sms_outlined,
            localizations?.get('powerAlarmSMS') ?? 'Power Alarm SMS',
            colorScheme.onSurfaceVariant,
            widget.tracker.phoneNumber.isNotEmpty,
            _showPowerAlarmSMSDialog,
          ),
          _buildDrawerOption(
            Icons.mode_standby,
            localizations?.get('sleepTime') ?? 'Sleep Time',
            colorScheme.onSurfaceVariant,
            widget.tracker.phoneNumber.isNotEmpty,
            _showSleepTimeDialog,
          ),
          _buildDrawerOption(
            Icons.delete_forever,
            localizations?.get('factoryReset') ?? 'Factory Reset',
            colorScheme.error,
            widget.tracker.phoneNumber.isNotEmpty,
            _showFactoryResetDialog,
          ),
          _buildDrawerOption(
            Icons.info_outline,
            localizations?.get('getInfo') ?? 'Get Info',
            colorScheme.onSurfaceVariant,
            widget.tracker.phoneNumber.isNotEmpty,
                () => widget.tracker.getTrackerInfo(),
          ),

          const Divider(),

          _buildDrawerOption(
            Icons.sms_rounded,
            localizations?.get('messages') ?? 'Messages',
            colorScheme.onSurfaceVariant,
            true,
                () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => TrackerMessageListScreen(widget.tracker),
            )),
          ),
          _buildDrawerOption(
            Icons.list,
            localizations?.get('details') ?? 'Details',
            colorScheme.onSurfaceVariant,
            true,
                () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => TrackerDetailsScreen(widget.tracker),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerOption(IconData icon, String title, Color iconColor, bool enabled, VoidCallback onTap) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: enabled ? null : Colors.grey)),
      onTap: enabled ? onTap : null,
    );
  }

  // Metodi helper per i dialog
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
        Modal.toast(
          context,
          localizations?.get('errorSaving') ?? 'Error saving',
        );
      }
    }
  }
}
