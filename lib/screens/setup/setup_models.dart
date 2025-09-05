import 'package:flutter/material.dart';
import 'package:timezones_list/timezones_list.dart';
import 'package:timezones_list/timezone_model.dart';

class SetupData {
  // Controllers per i dati del tracker
  final TextEditingController nameController = TextEditingController();
  final TextEditingController trackerPhoneController = TextEditingController(); // ✅ Numero SIM del tracker
  final TextEditingController pinController = TextEditingController(text: '123456');

  // Controllers per l'admin number
  final TextEditingController adminPhoneController = TextEditingController(); // ✅ Numero dell'amministratore

  // Controllers per la configurazione di rete
  final TextEditingController apnController = TextEditingController();
  final TextEditingController apnUserController = TextEditingController();
  final TextEditingController apnPasswordController = TextEditingController();
  final TextEditingController serverHostController = TextEditingController(text: '47.254.77.28');
  final TextEditingController serverPortController = TextEditingController(text: '7700');

  // Controllers per le notifiche
  final TextEditingController batteryThresholdController = TextEditingController(text: '20');
  final TextEditingController updateMovingController = TextEditingController(text: '60');
  final TextEditingController updateStoppedController = TextEditingController(text: '300');

  // Timezone
  String? selectedTimezone = 'Europe/Rome';
  List<TimezoneModel> timezonesList = [];

  // Flags di stato
  bool useExistingConfig = false;

  SetupData() {
    _loadTimezones();
  }

  void _loadTimezones() {
    try {
      timezonesList = TimezonesList().getTimezonesList();
      if (timezonesList.isNotEmpty) {
        final defaultTz = timezonesList.firstWhere(
              (tz) => tz.value == 'Europe/Rome',
          orElse: () => timezonesList.first,
        );
        selectedTimezone = defaultTz.value;
      } else {
        selectedTimezone = 'Europe/Rome';
      }
    } catch (e) {
      debugPrint('Error loading timezones: $e');
      selectedTimezone = 'Europe/Rome';
      timezonesList = [];
    }
  }

  void dispose() {
    nameController.dispose();
    trackerPhoneController.dispose();
    pinController.dispose();
    adminPhoneController.dispose();
    apnController.dispose();
    apnUserController.dispose();
    apnPasswordController.dispose();
    serverHostController.dispose();
    serverPortController.dispose();
    batteryThresholdController.dispose();
    updateMovingController.dispose();
    updateStoppedController.dispose();
  }
}
