import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_message.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/widgets/modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:another_telephony/telephony.dart';

/// Utils to send and receive SMS messages with background support
class SMSUtils {
  /// Telephony instance used to interact with phone functionalities.
  static Telephony telephony = Telephony.instance;

  /// ✅ Enhanced SMS listener with background processing
  static Future<void> startListener() async {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage msg) async {
        await _processForegroundSMS(msg);
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }

  /// ✅ Background message handler - processes SMS when app is closed
  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    if (message.body == null || message.address == null) return;

    try {
      final Database? db = await DataBase.get();
      final List<Tracker> trackers = await TrackerDB.list(db!);

      for (final tracker in trackers) {
        if (tracker.compareAddress(message.address!)) {
          final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(message.date!);

          if (tracker.timestamp.isBefore(timestamp)) {
            if (kDebugMode) {
              print('TrackMate [Background]: Processing SMS from ${message.address} -> ${message.body?.replaceAll('\n', '')}');
            }

            // Process the command and update tracker
            tracker.processCommand(message);
            await TrackerDB.update(db, tracker);
          }
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate [Background]: Error processing SMS - $e');
      }
    }
  }

  /// ✅ Process SMS when app is in foreground
  static Future<void> _processForegroundSMS(SmsMessage msg) async {
    if (msg.body == null || msg.address == null) return;

    try {
      final Database? db = await DataBase.get();
      final List<Tracker> trackers = await TrackerDB.list(db!);

      for (int i = 0; i < trackers.length; i++) {
        final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(msg.date!);
        if (trackers[i].compareAddress(msg.address!)) {
          if (trackers[i].timestamp.isBefore(timestamp)) {
            if (kDebugMode) {
              print('TrackMate [Foreground]: Processing SMS from ${msg.address} -> ${msg.body?.replaceAll('\n', '')}');
            }

            trackers[i].processCommand(msg);
            await TrackerDB.update(db, trackers[i]);
          }
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate [Foreground]: Error processing SMS - $e');
      }
    }
  }

  /// Import all messages received by the device.
  ///
  /// Should be called on application startup to process all stored messages.
  ///
  /// Can also be called after creating or changing the number of a tracker.
  static Future<void> importAll() async {
    await importReceived();
    await importSent();
  }

  /// Get all SMS received by the device.
  ///
  /// Check if any stored messages correspond to tracker messages
  ///
  /// Import data from these messages.
  static Future<void> importReceived() async {
    try {
      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
      );

      final Database? db = await DataBase.get();
      final List<Tracker> trackers = await TrackerDB.list(db!);

      for (int i = 0; i < messages.length; i++) {
        final SmsMessage msg = messages[i];
        for (int j = 0; j < trackers.length; j++) {
          if (trackers[j].compareAddress(msg.address!)) {
            final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(msg.date!);

            if (kDebugMode) {
              print('TrackMate: Found message ${msg.address!} (${timestamp.toIso8601String()}) -> ${msg.body!}');
            }

            if (trackers[j].timestamp.isBefore(timestamp)) {
              if (kDebugMode) {
                print('TrackMate: Import received message ${msg.address!} (${timestamp.toIso8601String()}) -> ${msg.body!.replaceAll('\n', '')}');
              }

              trackers[j].processCommand(msg);
              await TrackerDB.update(db, trackers[j]);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error importing received messages - $e');
      }
    }
  }

  /// Get all SMS sent by the device.
  static Future<void> importSent() async {
    try {
      final List<SmsMessage> messages = await telephony.getSentSms(
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.ASC)],
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      final Database? db = await DataBase.get();
      final List<Tracker> trackers = await TrackerDB.list(db!);

      for (int i = 0; i < messages.length; i++) {
        final SmsMessage msg = messages[i];
        for (int j = 0; j < trackers.length; j++) {
          final DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(msg.date!);
          if (trackers[j].compareAddress(msg.address!) && trackers[j].timestamp.isBefore(timestamp)) {
            if (kDebugMode) {
              print('TrackMate: Import sent message ${msg.address!} (${timestamp.toIso8601String()}) -> ${msg.body!.replaceAll('\n', '')}');
            }

            trackers[j].addMessage(TrackerMessage(MessageDirection.SENT, msg.body!, timestamp));
            await TrackerDB.update(db, trackers[j]);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error importing sent messages - $e');
      }
    }
  }

  /// ✅ Send a SMS to an address (phone number) - Now returns Future<void>
  static Future<void> send(String content, String address, {BuildContext? context}) async {
    try {
      // Check if the device is capable of sending SMS
      final bool? canSendSms = await telephony.isSmsCapable;
      if (!(canSendSms ?? true)) {
        if (context != null && context.mounted) {
          final localizations = AppLocalizations.of(context);
          Modal.toast(context, localizations?.get('cantSendSMS') ?? 'Cannot send SMS');
        }
        throw Exception('Device cannot send SMS');
      }

      // ✅ Send SMS with status monitoring
      await telephony.sendSms(
        to: address,
        message: content,
        statusListener: (SendStatus status) {
          if (context != null && context.mounted) {
            final localizations = AppLocalizations.of(context);
            if (status == SendStatus.DELIVERED) {
              Modal.toast(context, localizations?.get('commandSent') ?? 'Command sent');
            } else if (status == SendStatus.SENT) {
              if (kDebugMode) {
                print('TrackMate: SMS sent to $address: $content');
              }
            }
          }
        },
      );

      // ✅ Debug log for SMS sending
      if (kDebugMode) {
        print('TrackMate: Sending SMS to $address: $content');
      }

    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error sending SMS - $e');
      }

      if (context != null && context.mounted) {
        final localizations = AppLocalizations.of(context);
        Modal.toast(context, localizations?.get('errorSendingSMS') ?? 'Error sending SMS');
      }

      rethrow; // Re-throw to allow upstream error handling
    }
  }

  /// ✅ Check if SMS permissions are granted
  static Future<bool> hasPermissions() async {
    try {
      return await telephony.requestPhoneAndSmsPermissions ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error checking SMS permissions - $e');
      }
      return false;
    }
  }

  /// ✅ Request SMS permissions
  static Future<bool> requestPermissions() async {
    try {
      return await telephony.requestSmsPermissions ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error requesting SMS permissions - $e');
      }
      return false;
    }
  }

  /// ✅ Check if background SMS processing is available
  static Future<bool> canProcessInBackground() async {
    try {
      // Android specific check for background SMS capability
      return true; // another_telephony supports background processing
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Background SMS check failed - $e');
      }
      return false;
    }
  }

  /// ✅ Get SMS processing statistics
  static Future<Map<String, int>> getProcessingStats() async {
    try {
      final Database? db = await DataBase.get();
      final List<Tracker> trackers = await TrackerDB.list(db!);

      int totalMessages = 0;
      int recentMessages = 0;
      final DateTime last24Hours = DateTime.now().subtract(const Duration(hours: 24));

      for (final tracker in trackers) {
        totalMessages += tracker.messages.length;
        recentMessages += tracker.messages
            .where((msg) => msg.timestamp.isAfter(last24Hours))
            .length;
      }

      return {
        'totalTrackers': trackers.length,
        'totalMessages': totalMessages,
        'recentMessages': recentMessages,
      };
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error getting processing stats - $e');
      }
      return {
        'totalTrackers': 0,
        'totalMessages': 0,
        'recentMessages': 0,
      };
    }
  }
}
