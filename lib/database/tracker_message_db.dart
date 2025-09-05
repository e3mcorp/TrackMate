import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_message.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Tracker message stores messages exchanged with GPS trackers.
class TrackerMessageDB {
  static String tableName = 'tracker_message';

  static Future<void> migrate(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS $tableName ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'tracker_id STRING,'
        'direction INTEGER,'
        'timestamp STRING,'
        'data STRING,'
        'FOREIGN KEY(tracker_id) REFERENCES tracker(id))');
  }

  /// Add a new tracker message the database
  static Future<void> add(Database db, String trackerUUID, TrackerMessage message) async {
    await db.execute(
        'INSERT INTO $tableName (tracker_id, direction, timestamp, data) VALUES (?, ?, ?, ?)',
        [
          trackerUUID,
          message.direction.index,
          message.timestamp.toIso8601String(),
          message.data
        ]
    );

    // ✅ AGGIUNTO: Notifica cambiamenti per aggiornare UI automaticamente
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// Get a list of all messages of the a specific tracker available in database
  static Future<List<TrackerMessage>> list(Database db, String trackerUUID,
      {String sortAttribute = 'timestamp', String sortDirection = 'DESC'}) async {
    List<Map<String, Object?>> list = await db.rawQuery(
        'SELECT * FROM $tableName WHERE tracker_id = ? ORDER BY $sortAttribute $sortDirection',
        [trackerUUID]);

    List<TrackerMessage> messages = [];
    for (int i = 0; i < list.length; i++) {
      messages.add(parse(list[i]));
    }
    return messages;
  }

  /// Parse database retrieved data into a usable object.
  static TrackerMessage parse(Map<String, Object?> values) {
    String data = values['data'].toString();
    DateTime timestamp = DateTime.parse(values['timestamp'].toString());
    MessageDirection direction = MessageDirection.values[int.parse(values['direction'].toString())];

    TrackerMessage message = TrackerMessage(direction, data, timestamp);
    message.id = int.parse(values['id'].toString());
    return message;
  }

  /// ✅ AGGIUNTO: Metodo per aggiornare un messaggio esistente
  static Future<void> update(Database db, TrackerMessage message) async {
    await db.execute(
        'UPDATE $tableName SET direction=?, timestamp=?, data=? WHERE id=?',
        [
          message.direction.index,
          message.timestamp.toIso8601String(),
          message.data,
          message.id,
        ]
    );

    // ✅ Notifica cambiamenti
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// ✅ AGGIUNTO: Metodo per eliminare un messaggio
  static Future<void> delete(Database db, int messageId) async {
    await db.execute('DELETE FROM $tableName WHERE id = ?', [messageId]);

    // ✅ Notifica cambiamenti
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// ✅ AGGIUNTO: Metodo per eliminare tutti i messaggi di un tracker
  static Future<void> deleteAllForTracker(Database db, String trackerUUID) async {
    await db.execute('DELETE FROM $tableName WHERE tracker_id = ?', [trackerUUID]);

    // ✅ Notifica cambiamenti
    TrackerDB.changeNotifier.notifyChanges();
  }

  /// Test functionality of the message storage
  static Future<void> test(Database db) async {
    if (kDebugMode) {
      Tracker tracker = Tracker();
      await TrackerDB.add(db, tracker);

      List<Future<void>> addFutures = [];
      const int size = 10;
      for (int i = 0; i < size; i++) {
        addFutures.add(add(db, tracker.uuid,
            TrackerMessage(MessageDirection.SENT, 'test $i', DateTime.now())));
      }

      await Future.wait(addFutures);
      print('Messages added: ${await list(db, tracker.uuid)}');
    }
  }
}
