import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:another_telephony/telephony.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_message.dart';

/// ✅ Background SMS Handler per processare SMS quando app è chiusa
class BackgroundSmsHandler {
  static const String _channelId = 'trackmate_sms_channel';
  static const String _channelName = 'TrackMate SMS Processor';

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// Inizializza il background service
  static Future<void> initialize() async {
    await _initializeNotifications();
    await _initializeBackgroundService();
  }

  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(initializationSettings);

    // Crea notification channel per Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Processes GPS tracker SMS messages in background',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'TrackMate SMS Service',
        initialNotificationContent: 'Processing tracker messages...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundStart,
      ),
    );
  }

  /// ✅ Entry point per background service
  @pragma('vm:entry-point')
  static void onBackgroundStart(ServiceInstance service) async {
    // Setup Telephony listener per background
    final Telephony telephony = Telephony.instance;

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await _processBackgroundSMS(message, service);
      },
      listenInBackground: true,
    );

    // Keep service alive
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  /// ✅ Processa SMS in background quando app è chiusa
  static Future<void> _processBackgroundSMS(SmsMessage message, ServiceInstance service) async {
    try {
      if (message.body == null || message.address == null) return;

      final database = await DataBase.get();
      final trackers = await TrackerDB.list(database!);

      bool messageProcessed = false;

      for (final tracker in trackers) {
        if (tracker.compareAddress(message.address!)) {
          messageProcessed = true;

          // Processa il messaggio
          await _processTrackerMessage(tracker, message);

          // Mostra notifica se contiene informazioni importanti
          if (_isImportantMessage(message.body!)) {
            await _showImportantNotification(tracker, message);
          }

          if (kDebugMode) {
            print('BackgroundSMS: Processed message from ${message.address}');
          }
          break;
        }
      }

      // Aggiorna service con statistiche
      if (messageProcessed) {
        service.invoke('messageProcessed', {
          'address': message.address,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

    } catch (e) {
      if (kDebugMode) {
        print('BackgroundSMS Error: $e');
      }
    }
  }

  /// ✅ Processa messaggio dal tracker
  static Future<void> _processTrackerMessage(Tracker tracker, SmsMessage message) async {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(message.date!);

    // Aggiunge messaggio alla cronologia
    tracker.addMessage(TrackerMessage(
      MessageDirection.RECEIVED,
      message.body!,
      timestamp,
    ));

    // Processa comando per estrarre dati GPS, batteria, etc.
    tracker.processCommand(message);

    // Salva aggiornamenti nel database
    final db = await DataBase.get();
    await TrackerDB.update(db!, tracker);
  }

  /// ✅ Determina se messaggio necessita notifica
  static bool _isImportantMessage(String messageBody) {
    final body = messageBody.toLowerCase();

    // Keywords per messaggi importanti
    return body.contains('battery') ||
        body.contains('alarm') ||
        body.contains('sos') ||
        body.contains('speed') ||
        body.contains('low power') ||
        body.contains('offline') ||
        messageBody.contains('lat:');  // Coordinate GPS
  }

  /// ✅ Mostra notifica per messaggi importanti
  static Future<void> _showImportantNotification(Tracker tracker, SmsMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Important tracker notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'TrackMate Alert',
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    String title = 'TrackMate - ${tracker.name}';
    String body = _formatNotificationBody(message.body!);

    await _notifications.show(
      tracker.hashCode, // Unique ID per tracker
      title,
      body,
      notificationDetails,
    );
  }

  /// ✅ Formatta corpo notifica
  static String _formatNotificationBody(String messageBody) {
    if (messageBody.toLowerCase().contains('battery')) {
      return 'Battery status update received';
    } else if (messageBody.toLowerCase().contains('alarm')) {
      return 'Alarm triggered!';
    } else if (messageBody.contains('lat:')) {
      return 'New location received';
    } else {
      return messageBody.length > 50
          ? '${messageBody.substring(0, 47)}...'
          : messageBody;
    }
  }

  /// ✅ Avvia background service
  static Future<void> startBackgroundService() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
      if (kDebugMode) {
        print('BackgroundSMS: Service started');
      }
    }
  }

  /// ✅ Ferma background service
  static Future<void> stopBackgroundService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    if (kDebugMode) {
      print('BackgroundSMS: Service stopped');
    }
  }
}
