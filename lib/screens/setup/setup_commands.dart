import 'package:flutter/material.dart';
import 'package:trackmate/utils/sms.dart';
import 'setup_models.dart';

class SetupCommands {
  final SetupData setupData;

  SetupCommands(this.setupData);

  Future<void> sendCommand(String commandType, BuildContext context) async {
    String command;

    switch (commandType) {
      case 'apn':
        command = _buildAPNCommand();
        break;
      case 'server':
        command = _buildServerCommand();
        break;
      case 'timezone':
        command = _buildTimezoneCommand();
        break;
      case 'center':
        command = _buildCenterCommand();
        break;
      case 'timer':
        command = _buildTimerCommand();
        break;
      default:
        throw Exception('Unknown command type: $commandType');
    }

    final trackerPhone = setupData.trackerPhoneController.text.trim();
    await SMSUtils.send(command, trackerPhone, context: context);
  }

  String _buildAPNCommand() {
    final apn = setupData.apnController.text.trim();
    final user = setupData.apnUserController.text.trim();
    final password = setupData.apnPasswordController.text.trim();

    if (user.isEmpty && password.isEmpty) {
      return 'APN,$apn#';
    } else {
      return 'APN,$apn,$user,$password#';
    }
  }

  String _buildServerCommand() {
    final host = setupData.serverHostController.text.trim();
    final port = int.tryParse(setupData.serverPortController.text.trim()) ?? 7700;

    final isIP = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    final serverType = isIP ? 0 : 1;

    return 'SERVER,$serverType,$host,$port#';
  }

  // ✅ CORREZIONE: Metodo timezone corretto
  String _buildTimezoneCommand() {
    final timezone = setupData.selectedTimezone ?? 'Europe/Rome';
    return _convertTimezoneToGMTCommand(timezone);
  }

  // ✅ CONVERSIONE TIMEZONE CORRETTA secondo manuale MV710G
  String _convertTimezoneToGMTCommand(String timezone) {
    // Formato: GMT,A,B,C# secondo il manuale
    // A: E/W (East/West)
    // B: 0-12 (ore)
    // C: 0/15/30/45 (minuti, opzionale)

    switch (timezone) {
    // Europa Centrale (CET) - GMT+1
      case 'Europe/Rome':
      case 'Europe/Berlin':
      case 'Europe/Paris':
      case 'Europe/Madrid':
      case 'Europe/Amsterdam':
        return 'GMT,E,1#';

    // Europa Occidentale (WET) - GMT+0
      case 'Europe/London':
      case 'Europe/Lisbon':
      case 'UTC':
        return 'GMT,E,0#';

    // Europa Orientale (EET) - GMT+2
      case 'Europe/Athens':
      case 'Europe/Helsinki':
      case 'Europe/Kiev':
        return 'GMT,E,2#';

    // Russia Moscow - GMT+3
      case 'Europe/Moscow':
        return 'GMT,E,3#';

    // Asia
      case 'Asia/Dubai':
        return 'GMT,E,4#';

      case 'Asia/Kolkata':
        return 'GMT,E,5,30#'; // GMT+5:30 India

      case 'Asia/Shanghai':
      case 'Asia/Beijing':
        return 'GMT,E,8#';

      case 'Asia/Tokyo':
        return 'GMT,E,9#';

    // Australia
      case 'Australia/Sydney':
      case 'Australia/Melbourne':
        return 'GMT,E,10#';

    // Americas
      case 'America/New_York':
        return 'GMT,W,5#'; // EST

      case 'America/Chicago':
        return 'GMT,W,6#'; // CST

      case 'America/Denver':
        return 'GMT,W,7#'; // MST

      case 'America/Los_Angeles':
        return 'GMT,W,8#'; // PST

      case 'America/Sao_Paulo':
        return 'GMT,W,3#';

    // Default per l'Italia
      default:
        debugPrint('Timezone non supportato: $timezone, uso GMT+1 (Italia)');
        return 'GMT,E,1#';
    }
  }

  String _buildCenterCommand() {
    final pin = setupData.pinController.text.trim();
    final adminPhone = setupData.adminPhoneController.text.trim();

    // ✅ Se admin phone è vuoto, non inviare il comando CENTER
    if (adminPhone.isEmpty) {
      throw Exception('Admin phone number is empty - skipping CENTER command');
    }

    // Formato: CENTER,password,A,center number#
    return 'CENTER,$pin,A,$adminPhone#';
  }

  String _buildTimerCommand() {
    final movingInterval = int.tryParse(setupData.updateMovingController.text) ?? 60;
    final stoppedInterval = int.tryParse(setupData.updateStoppedController.text) ?? 300;

    return 'TIMER,$movingInterval,$stoppedInterval#';
  }

  Future<void> testConnection(BuildContext context) async {
    final trackerPhone = setupData.trackerPhoneController.text.trim();

    await SMSUtils.send('WHERE#', trackerPhone, context: context);
    await Future.delayed(const Duration(milliseconds: 500));
    await SMSUtils.send('STATUS#', trackerPhone, context: context);
  }

  Future<void> setSosNumbers(BuildContext context, List<String> sosNumbers) async {
    final trackerPhone = setupData.trackerPhoneController.text.trim();
    if (sosNumbers.isEmpty) return;

    String command = 'SOS,A';
    for (int i = 0; i < sosNumbers.length && i < 3; i++) {
      command += ',${sosNumbers[i]}';
    }
    command += '#';

    await SMSUtils.send(command, trackerPhone, context: context);
  }

  Future<void> setBatteryAlarm(BuildContext context) async {
    final trackerPhone = setupData.trackerPhoneController.text.trim();
    final threshold = setupData.batteryThresholdController.text.trim();

    final command = 'LVALM,ON,$threshold,1#';
    await SMSUtils.send(command, trackerPhone, context: context);
  }
}
