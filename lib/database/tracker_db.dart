import 'package:trackmate/data/tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

// ✅ Classe dedicata che estende ChangeNotifier
class TrackerNotifier extends ChangeNotifier {
  // ✅ Ora puoi chiamare notifyListeners() senza warning
  void notifyChanges() {
    notifyListeners();
  }
}

class TrackerDB {
  /// ✅ Usa la classe dedicata invece di ChangeNotifier diretto
  static final TrackerNotifier changeNotifier = TrackerNotifier();

  static String tableName = 'tracker';

  static Future<void> migrate(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $tableName('
        'uuid TEXT PRIMARY KEY,'
        'id TEXT,'
        'name TEXT,'
        'license_plate TEXT,'
        'chassis_number TEXT,'
        'model TEXT,'
        'color INTEGER,'
        'phone_number TEXT,'
        'admin_number TEXT,'
        'sos_numbers TEXT,'
        'pin TEXT,'
        'speed_limit INTEGER,'
        'sleep_limit INTEGER,'
        'ignition_alarm INTEGER,'
        'power_alarm_sms INTEGER,'
        'power_alarm_call INTEGER,'
        'battery INTEGER,'
        'apn TEXT,'
        'iccid TEXT,'
        'timestamp TEXT)');
  }

  /// Add a new tracker to the database
  static Future<void> add(Database db, Tracker tracker) async {
    await db.execute(
        'INSERT INTO $tableName (uuid, id, name, license_plate, chassis_number,'
            'model, color, phone_number, admin_number, sos_numbers,'
            'pin, speed_limit, sleep_limit, ignition_alarm, power_alarm_sms,'
            'power_alarm_call, battery, apn, iccid, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          tracker.uuid,
          tracker.id,
          tracker.name,
          tracker.licensePlate,
          tracker.chassisNumber,
          tracker.model,
          tracker.color,
          tracker.phoneNumber,
          tracker.adminNumber,
          tracker.sosNumbers.join(','), // ✅ Fix: join sosNumbers list
          tracker.pin,
          tracker.speedLimit,
          tracker.sleepLimit,
          tracker.ignitionAlarm ? 1 : 0,
          tracker.powerAlarmSMS ? 1 : 0,
          tracker.powerAlarmCall ? 1 : 0,
          tracker.battery,
          tracker.apn,
          tracker.iccid,
          tracker.timestamp.toIso8601String()
        ]);
    // ✅ Notifica cambiamenti UI
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// Update data from the tracker in database
  static Future<void> update(Database db, Tracker tracker) async {
    await db.execute(
        'UPDATE $tableName SET id=?, name=?, license_plate=?, chassis_number=?,'
            'model=?, color=?, phone_number=?, admin_number=?, sos_numbers=?,'
            'pin=?, speed_limit=?, sleep_limit=?, ignition_alarm=?, power_alarm_sms=?,'
            'power_alarm_call=?, battery=?, apn=?, iccid=?, timestamp=? WHERE uuid=?',
        [
          tracker.id,
          tracker.name,
          tracker.licensePlate,
          tracker.chassisNumber,
          tracker.model,
          tracker.color,
          tracker.phoneNumber,
          tracker.adminNumber,
          tracker.sosNumbers.join(','), // ✅ Fix: join sosNumbers list
          tracker.pin,
          tracker.speedLimit,
          tracker.sleepLimit,
          tracker.ignitionAlarm ? 1 : 0,
          tracker.powerAlarmSMS ? 1 : 0,
          tracker.powerAlarmCall ? 1 : 0,
          tracker.battery, // ✅ Questo è il campo critico per la batteria
          tracker.apn,
          tracker.iccid,
          tracker.timestamp.toIso8601String(),
          tracker.uuid
        ]);
    // ✅ Notifica cambiamenti UI - FONDAMENTALE per aggiornare la lista
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// Get details of a tracker by its UUID
  static Future<Tracker> get(Database db, String uuid) async {
    List<Map<String, Object?>> values = await db.rawQuery(
        'SELECT * FROM $tableName WHERE uuid=?', [uuid]);
    if (values.isEmpty) {
      throw Exception('Tracker does not exist.');
    }
    return parse(values[0]);
  }

  /// Delete a tracker by its UUID
  static Future<void> delete(Database db, String uuid) async {
    await db.rawDelete('DELETE FROM $tableName WHERE uuid = ?', [uuid]);
    // ✅ Notifica cambiamenti UI
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// Count the number of trackers stored in database
  static Future<int?> count(Database db) async {
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
  }

  /// Get a list of all trackers available in database
  static Future<List<Tracker>> list(Database db, {String sortAttribute = 'name', String sortDirection = 'ASC'}) async {
    List<Map<String, Object?>> list = await db.rawQuery(
        'SELECT * FROM $tableName ORDER BY $sortAttribute $sortDirection');
    List<Tracker> trackers = [];
    for (int i = 0; i < list.length; i++) {
      trackers.add(parse(list[i]));
    }
    return trackers;
  }

  /// Parse database retrieved data into a usable object.
  static Tracker parse(Map<String, Object?> values) {
    Tracker tracker = Tracker();

    // ✅ Controlli null-safe migliorati
    tracker.uuid = values['uuid']?.toString() ?? '';
    tracker.id = values['id']?.toString() ?? '';
    tracker.name = values['name']?.toString() ?? 'Tracker';
    tracker.licensePlate = values['license_plate']?.toString() ?? '';
    tracker.chassisNumber = values['chassis_number']?.toString() ?? '';
    tracker.model = values['model']?.toString() ?? '';
    tracker.color = int.tryParse(values['color']?.toString() ?? '0') ?? 0xFFFF0000;
    tracker.phoneNumber = values['phone_number']?.toString() ?? '';
    tracker.adminNumber = values['admin_number']?.toString() ?? '';

    // ✅ Fix: parsing sosNumbers dalla stringa CSV
    String sosString = values['sos_numbers']?.toString() ?? '';
    tracker.sosNumbers = sosString.isEmpty ? <String>[] : sosString.split(',');

    tracker.pin = values['pin']?.toString() ?? '123456';
    tracker.speedLimit = int.tryParse(values['speed_limit']?.toString() ?? '0') ?? 0;
    tracker.sleepLimit = int.tryParse(values['sleep_limit']?.toString() ?? '0') ?? 0;
    tracker.ignitionAlarm = (int.tryParse(values['ignition_alarm']?.toString() ?? '0') ?? 0) == 1;
    tracker.powerAlarmSMS = (int.tryParse(values['power_alarm_sms']?.toString() ?? '0') ?? 0) == 1;
    tracker.powerAlarmCall = (int.tryParse(values['power_alarm_call']?.toString() ?? '0') ?? 0) == 1;

    // ✅ IMPORTANTE: parsing batteria
    tracker.battery = int.tryParse(values['battery']?.toString() ?? '0') ?? 0;

    tracker.apn = values['apn']?.toString() ?? '';
    tracker.iccid = values['iccid']?.toString() ?? '';

    // ✅ Parsing DateTime sicuro
    try {
      String timestampStr = values['timestamp']?.toString() ?? DateTime.now().toIso8601String();
      tracker.timestamp = DateTime.parse(timestampStr);
    } catch (e) {
      tracker.timestamp = DateTime.now();
      if (kDebugMode) {
        print('TrackerDB: Error parsing timestamp: $e');
      }
    }

    return tracker;
  }

  /// Test tracker database functionality.
  static Future<void> test(Database db) async {
    if (kDebugMode) {
      const int size = 10;
      print('Initial count: ${await count(db)}');

      List<Future<void>> addFutures = [];
      for (int i = 0; i < size; i++) {
        addFutures.add(add(db, Tracker()));
      }

      await Future.wait(addFutures);
      print('Trackers: ${await list(db)}');
      print('Final count: ${await count(db)}');
    }
  }
}
