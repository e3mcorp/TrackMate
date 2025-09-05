import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionsHelper {
  /// ✅ Richiede tutti i permessi necessari per SMS background
  static Future<bool> requestAllSMSPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();

    // Richiedi ignore battery optimization per Android
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 23) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    return statuses.values.every((status) =>
    status == PermissionStatus.granted);
  }

  /// ✅ Verifica se app può funzionare in background
  static Future<bool> canRunInBackground() async {
    if (!Platform.isAndroid) return true;

    return await Permission.ignoreBatteryOptimizations.isGranted;
  }
}
