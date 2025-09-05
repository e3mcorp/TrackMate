import 'package:trackmate/data/tracker_position.dart';
import 'package:trackmate/data/tracker_message.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_message_db.dart';
import 'package:trackmate/database/tracker_position_db.dart';
import 'package:trackmate/utils/sms.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:another_telephony/telephony.dart';
import 'package:uuid/uuid.dart';

class Tracker {
  // ===== PROPRIETÀ BASE =====
  String uuid = '';
  String id = '';
  String name = 'Tracker';
  String licensePlate = '';
  String chassisNumber = '';
  String model = '';
  int color = 0xFFFF0000;
  String phoneNumber = '';
  String adminNumber = '';
  List<String> sosNumbers = List.filled(3, '');
  String pin = '123456';
  int speedLimit = 0;
  int sleepLimit = 0;
  bool ignitionAlarm = false;
  bool powerAlarmSMS = false;
  bool powerAlarmCall = false;
  int battery = 0;
  String apn = '';
  String iccid = '';
  DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(0);

  // ✅ CORREZIONE: Liste private con getter pubblici
  List<TrackerMessage> _messages = [];
  List<TrackerPosition> _positions = [];

  /// Public getter for messages
  List<TrackerMessage> get messages => List.unmodifiable(_messages);

  /// Public getter for positions
  List<TrackerPosition> get positions => List.unmodifiable(_positions);

  Tracker() {
    uuid = const Uuid().v4().toString();
  }

  /// Initialize tracker with data loading
  Future<void> initialize() async {
    await _loadMessagesFromDB();
    await _loadPositionsFromDB();
  }

  // ===== METODI BASE CORRETTI =====

  Future<void> sendSMS(String message) async {
    try {
      await SMSUtils.send(message, phoneNumber);
      await addMessage(TrackerMessage(MessageDirection.SENT, message, DateTime.now()));
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error sending SMS - $e');
      }
    }
  }

  Future<void> addMessage(TrackerMessage message) async {
    try {
      final Database? db = await DataBase.get();
      await TrackerMessageDB.add(db!, uuid, message);

      // Add to local cache
      _messages.add(message);

      // Keep only last 1000 messages for performance
      if (_messages.length > 1000) {
        _messages.removeAt(0);
      }

      if (kDebugMode) {
        print('TrackMate: Added message to tracker $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error adding message - $e');
      }
    }
  }

  Future<void> addPosition(TrackerPosition position) async {
    try {
      final Database? db = await DataBase.get();
      await TrackerPositionDB.add(db!, uuid, position);

      // Add to local cache
      _positions.add(position);

      // Keep only last 500 positions for performance
      if (_positions.length > 500) {
        _positions.removeAt(0);
      }

      if (kDebugMode) {
        print('TrackMate: Added position to tracker $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error adding position - $e');
      }
    }
  }

  Future<void> _loadMessagesFromDB() async {
    try {
      final Database? db = await DataBase.get();
      if (db != null) {
        // Load messages from database (implement this in TrackerMessageDB)
        // _messages = await TrackerMessageDB.getByTracker(db, uuid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error loading messages from DB - $e');
      }
    }
  }

  Future<void> _loadPositionsFromDB() async {
    try {
      final Database? db = await DataBase.get();
      if (db != null) {
        // Load positions from database (implement this in TrackerPositionDB)
        // _positions = await TrackerPositionDB.getByTracker(db, uuid);
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error loading positions from DB - $e');
      }
    }
  }

  Future<void> update() async {
    try {
      final Database? db = await DataBase.get();
      await TrackerDB.update(db!, this);
    } catch (e) {
      if (kDebugMode) {
        print('TrackMate: Error updating tracker - $e');
      }
    }
  }

  bool compareAddress(String address) {
    if (address.isEmpty || phoneNumber.isEmpty) return false;

    String a = address.replaceAll(' ', '').replaceAll('+', '');
    String b = phoneNumber.replaceAll(' ', '').replaceAll('+', '');

    if (a.length > b.length) {
      return a.contains(b);
    } else if (a.length < b.length) {
      return b.contains(a);
    }

    return a == b;
  }

  // ===== CONFIGURAZIONE BASE =====

  /// Configura APN (MV710G format)
  Future<void> setAPN(String apnName, [String username = '', String password = '']) async {
    String msg;
    if (username.isEmpty && password.isEmpty) {
      msg = 'APN,$apnName#';
    } else {
      msg = 'APN,$apnName,$username,$password#';
    }

    await sendSMS(msg);
    apn = apnName;
    await update();
  }

  /// Configura server con dominio o IP
  Future<void> setServer(String domain, int port, {bool useIP = false}) async {
    String msg = 'SERVER,${useIP ? 0 : 1},$domain,$port#';
    await sendSMS(msg);
  }

  /// Imposta fuso orario GMT
  Future<void> setGMTTimezone(String orientation, int wholeZone, [int halfZone = 0]) async {
    String msg = halfZone > 0
        ? 'GMT,$orientation,$wholeZone,$halfZone#'
        : 'GMT,$orientation,$wholeZone#';
    await sendSMS(msg);
  }

  /// Imposta fuso orario per dati
  Future<void> setDataTimezone(String orientation, int wholeZone, [int halfZone = 0]) async {
    String msg = halfZone > 0
        ? 'DATAGMT,$orientation,$wholeZone,$halfZone#'
        : 'DATAGMT,$orientation,$wholeZone#';
    await sendSMS(msg);
  }

  /// Factory reset
  Future<void> factoryReset() async {
    await sendSMS('FACTORY#');
  }

  /// Riavvia dispositivo
  Future<void> restartDevice() async {
    await sendSMS('RESTART#');
  }

  /// Abilita/disabilita traffico internet
  Future<void> setInternetTraffic(bool enabled) async {
    await sendSMS('TRAFFIC,${enabled ? 'ON' : 'OFF'}#');
  }

  /// Cambia IMEI (uso con cautela)
  Future<void> changeIMEI(String newImei) async {
    await sendSMS('IMEICHG,$newImei#');
  }

  // ===== GESTIONE PASSWORD E AMMINISTRATORE =====

  /// Imposta numero centro di controllo
  Future<void> setCenterNumber(String centerNumber) async {
    await sendSMS('CENTER,$pin,A,$centerNumber#');
  }

  /// Elimina numero centro di controllo
  Future<void> deleteCenterNumber() async {
    await sendSMS('CENTER,$pin,D#');
  }

  /// Abilita/disabilita password per comandi
  Future<void> setCommandPassword(bool enabled) async {
    await sendSMS('PWD,$pin,${enabled ? 'ON' : 'OFF'}#');
  }

  /// Cambia password comandi
  Future<void> changeCommandPassword(String oldPin, String newPin) async {
    await sendSMS('PWDCHG,$oldPin,$newPin#');
    pin = newPin;
    await update();
  }

  /// Reset password a default
  Future<void> resetPassword(String deviceId) async {
    await sendSMS('RSTPWD,$deviceId#');
  }

  // ===== GESTIONE SOS =====

  /// Imposta numeri SOS (fino a 3)
  Future<void> setSOSNumbers(List<String> numbers) async {
    if (numbers.length > 3) numbers = numbers.sublist(0, 3);
    String msg = 'SOS,A';
    for (String number in numbers) {
      msg += ',$number';
    }
    msg += '#';
    await sendSMS(msg);
    sosNumbers = List.filled(3, '');
    for (int i = 0; i < numbers.length; i++) {
      sosNumbers[i] = numbers[i];
    }
    await update();
  }

  /// Imposta singolo numero SOS
  Future<void> setSOSNumber(String phoneNumber, int slot) async {
    if (slot < 1 || slot > 3) throw Exception('Invalid slot value.');
    List<String> sosArgs = List.filled(3, '');
    sosArgs[slot - 1] = phoneNumber;
    String msg = 'SOS,A';
    for (String arg in sosArgs) {
      msg += ',$arg';
    }
    msg += '#';
    await sendSMS(msg);
    sosNumbers[slot - 1] = phoneNumber;
    await update();
  }

  /// Elimina numeri SOS
  Future<void> deleteSOSNumbers(List<int> slots) async {
    String msg = 'SOS,D';
    for (int slot in slots) {
      msg += ',$slot';
    }
    msg += '#';
    await sendSMS(msg);
    for (int slot in slots) {
      if (slot >= 1 && slot <= 3) {
        sosNumbers[slot - 1] = '';
      }
    }
    await update();
  }

  /// Elimina singolo numero SOS
  Future<void> deleteSOSNumber(int slot) async {
    if (slot < 1 || slot > 3) throw Exception('Invalid slot value.');
    await deleteSOSNumbers([slot]);
  }

  // ===== CONTROLLI REMOTI =====

  /// Controllo relè carburante
  Future<void> controlFuelRelay(int action) async {
    // 0: Riprendi carburante, 1: Taglia immediatamente, 2: Taglia sicuro
    await sendSMS('RELAY,$action#');
  }

  /// Riprendi carburante
  Future<void> resumeFuel() async {
    await sendSMS('RELAY,0#');
  }

  /// Taglia carburante immediatamente
  Future<void> cutFuelImmediate() async {
    await sendSMS('RELAY,1#');
  }

  /// Taglia carburante sicuro
  Future<void> cutFuelSafe() async {
    await sendSMS('RELAY,2#');
  }

  /// Arm manuale
  Future<void> setArmMode() async {
    await sendSMS('ARM#');
  }

  /// Disarm manuale
  Future<void> setDisarmMode() async {
    await sendSMS('DISARM#');
  }

  // ===== CONFIGURAZIONI TEMPORALI =====

  /// Imposta intervalli upload dati
  Future<void> setDataUploadInterval(int accOnSeconds, int accOffSeconds) async {
    await sendSMS('TIMER,$accOnSeconds,$accOffSeconds#');
  }

  /// Imposta heartbeat
  Future<void> setHeartbeat(int minutes) async {
    await sendSMS('HBT,$minutes#');
  }

  /// Imposta sensibilità sensore
  Future<void> setSensorSensitivity(int level) async {
    // Level 1-9 (1=debole, 9=forte)
    await sendSMS('LEVEL,$level#');
  }

  // ===== ALLARMI =====

  /// Configura allarme vibrazione
  Future<void> setVibrationAlarm(bool enabled, [int alarmMode = 1]) async {
    if (enabled) {
      // alarmMode: 0=Server, 1=SMS+Server, 2=SMS+Server+Call
      await sendSMS('SENALM,ON,$alarmMode#');
    } else {
      await sendSMS('SENALM,OFF#');
    }
  }

  /// Configura allarme spostamento
  Future<void> setShiftAlarm(bool enabled, [int distanceMeters = 300, int alarmMode = 1]) async {
    if (enabled) {
      await sendSMS('SHIFT,ON,$distanceMeters,$alarmMode#');
    } else {
      await sendSMS('SHIFT,OFF#');
    }
  }

  /// Auto-arm tramite ACC
  Future<void> setAutoArmByACC(bool enabled, [int delaySeconds = 60]) async {
    if (enabled) {
      await sendSMS('ACCARM,ON,$delaySeconds#');
    } else {
      await sendSMS('ACCARM,OFF#');
    }
  }

  /// Allarme cambiamento stato ACC
  Future<void> setACCStatusAlarm(bool enabled, [int mode = 2, int alarmMode = 1]) async {
    if (enabled) {
      // mode: 0=ACC ON, 1=ACC OFF, 2=Entrambi
      await sendSMS('ACCALM,ON,$mode,$alarmMode#');
      ignitionAlarm = true;
    } else {
      await sendSMS('ACCALM,OFF#');
      ignitionAlarm = false;
    }
    await update();
  }

  /// Allarme disconnessione alimentazione
  Future<void> setPowerDisconnectAlarm(bool enabled, [int alarmMode = 2]) async {
    if (enabled) {
      await sendSMS('PWRALM,ON,$alarmMode#');
      powerAlarmSMS = (alarmMode == 1 || alarmMode == 2);
      powerAlarmCall = (alarmMode == 2);
    } else {
      await sendSMS('PWRALM,OFF#');
      powerAlarmSMS = false;
      powerAlarmCall = false;
    }
    await update();
  }

  /// Allarme eccesso velocità
  Future<void> setOverspeedAlarm(bool enabled, [int speedKmh = 100, int alarmMode = 1]) async {
    if (enabled) {
      await sendSMS('SPEED,ON,$speedKmh,$alarmMode#');
      speedLimit = speedKmh;
    } else {
      await sendSMS('SPEED,OFF#');
      speedLimit = 0;
    }
    await update();
  }

  /// Allarme bassa tensione
  Future<void> setLowVoltageAlarm(bool enabled, [double voltageThreshold = 11.5, int alarmMode = 1]) async {
    if (enabled) {
      await sendSMS('LVALM,ON,$voltageThreshold,$alarmMode#');
    } else {
      await sendSMS('LVALM,OFF#');
    }
  }

  /// Allarme apertura porta
  Future<void> setDoorAlarm(bool enabled, [int alarmMode = 1]) async {
    if (enabled) {
      await sendSMS('DOORALM,ON,$alarmMode#');
    } else {
      await sendSMS('DOORALM,OFF#');
    }
  }

  // ===== CONFIGURAZIONI AVANZATE =====

  /// Imposta caricamento angolo
  Future<void> setAngleUpload(bool enabled, [int angleDegrees = 30, int detectSeconds = 3]) async {
    if (enabled) {
      await sendSMS('ANGLEREP,ON,$angleDegrees,$detectSeconds#');
    } else {
      await sendSMS('ANGLEREP,OFF#');
    }
  }

  /// Statistiche chilometraggio
  Future<void> setMileageStatistics(bool enabled, [int initialKm = 0]) async {
    if (enabled) {
      await sendSMS('MILEAGE,ON,$initialKm#');
    } else {
      await sendSMS('MILEAGE,OFF#');
    }
  }

  /// Richiedi chilometraggio attuale
  Future<void> requestCurrentMileage() async {
    await sendSMS('MILEAGE#');
  }

  // ===== RICHIESTE INFORMAZIONI =====

  /// Richiedi informazioni parametri
  Future<void> requestParameters() async {
    await sendSMS('PARAM#');
  }

  /// Richiedi informazioni allarmi
  Future<void> requestAlarmStatus() async {
    await sendSMS('ALARM#');
  }

  /// Richiedi posizione coordinate
  Future<void> requestLocation() async {
    await sendSMS('WHERE#');
  }

  /// Richiedi URL mappa
  Future<void> requestMapURL() async {
    await sendSMS('URL#');
  }

  /// Richiedi indirizzo
  Future<void> requestAddress() async {
    await sendSMS('POSITION#');
  }

  /// Richiedi stato completo
  Future<void> requestStatus() async {
    await sendSMS('STATUS#');
  }

  /// Richiedi versione
  Future<void> requestVersion() async {
    await sendSMS('VERSION#');
  }

  /// Richiedi IMEI
  Future<void> requestIMEI() async {
    await sendSMS('IMEI#');
  }

  // ===== METODI DI COMPATIBILITÀ (esistenti) =====

  Future<void> setIgnitionAlarm(bool enabled) async {
    await setACCStatusAlarm(enabled);
  }

  Future<void> setPowerAlarmSMS(bool enabled) async {
    await setPowerDisconnectAlarm(enabled, 1);
  }

  Future<void> setPowerAlarmCall(bool enabled) async {
    await setPowerDisconnectAlarm(enabled, 2);
  }

  Future<void> setSpeedLimit(int speed) async {
    await setOverspeedAlarm(speed > 0, speed);
  }

  Future<void> setSleepTime(int time) async {
    String msg = 'sleep,$pin,$time';
    sleepLimit = time;
    await sendSMS(msg);
    await update();
  }

  Future<void> changePIN(String newPin) async {
    await changeCommandPassword(pin, newPin);
  }

  Future<void> setAdminNumber(String phoneNumber) async {
    await setCenterNumber(phoneNumber);
    adminNumber = phoneNumber;
    await update();
  }

  Future<void> listSOSNumbers() async {
    await sendSMS('C10#');
  }

  Future<void> getTrackerInfo() async {
    await requestParameters();
  }

  Future<void> setTimezone(String timezone) async {
    await sendSMS('zone$pin $timezone');
  }

  // ===== PARSER MIGLIORATO =====

  Map<String, dynamic>? parseDeviceStatus(String message) {
    final regex = RegExp(
      r'(\w+)\([^)]*\)[^\n]*BUILD:([^\n]+)\n'
      r'ID:(\d+)\n'
      r'IP:([^\s]+)\s+(\d+)\n'
      r'BAT:(\d+)%\n'
      r'UT:(\d+),(\d+),(\d+)\n'
      r'APN:([^\n]+)\n'
      r'GPS:([^\n]+)\n'
      r'GSM:(\d+)',
      multiLine: true,
    );

    final match = regex.firstMatch(message.trim());
    if (match == null) return null;

    return {
      'model': match.group(1),
      'buildDate': match.group(2),
      'deviceId': match.group(3),
      'serverIp': match.group(4),
      'serverPort': int.tryParse(match.group(5) ?? '0'),
      'batteryLevel': int.tryParse(match.group(6) ?? '0'),
      'updateMoving': int.tryParse(match.group(7) ?? '0'),
      'updateStopped': int.tryParse(match.group(8) ?? '0'),
      'updateParam': int.tryParse(match.group(9) ?? '0'),
      'apn': match.group(10),
      'gpsStatus': match.group(11),
      'gsmSignal': int.tryParse(match.group(12) ?? '0'),
    };
  }

  Future<void> processCommand(SmsMessage msg) async {
    final DateTime messageTimestamp = DateTime.fromMillisecondsSinceEpoch(msg.date!);
    if (timestamp.isAfter(messageTimestamp)) {
      return;
    }

    timestamp = messageTimestamp;
    String body = msg.body!;
    await addMessage(TrackerMessage(MessageDirection.RECEIVED, body, messageTimestamp));

    // Parse ICCID from any message
    String? parsedIccid = _parseICCID(body);
    if (parsedIccid != null) {
      iccid = parsedIccid;
    }

    // Handle acknowledgments
    if (_isAcknowledgment(body)) {
      if (kDebugMode) {
        print('TrackMate: Command acknowledged: $body');
      }
      await update();
      return;
    }

    // Parse device status (STATUS# response)
    if (_isStatusResponse(body)) {
      _parseStatusResponse(body);
      await update();
      return;
    }

    // Parse parameter response (PARAM# response)
    if (_isParameterResponse(body)) {
      _parseParameterResponse(body);
      await update();
      return;
    }

    // Parse location responses
    if (body.startsWith('http') || body.contains('LAT:')) {
      await _parseLocationResponse(body, messageTimestamp);
      await update();
      return;
    }

    // Parse SOS numbers list
    if (body.startsWith('SOS:')) {
      _parseSOSNumbers(body);
      await update();
      return;
    }

    // MV710G Device Status
    if (body.contains('BUILD:') && body.contains('ID:') && body.contains('BAT:')) {
      Map<String, dynamic>? statusData = parseDeviceStatus(body);
      if (statusData != null) {
        model = statusData['model'] ?? model;
        id = statusData['deviceId'] ?? id;
        battery = statusData['batteryLevel'] ?? battery;
        apn = statusData['apn'] ?? apn;

        if (kDebugMode) {
          print('TrackMate: Parsed MV710G status:');
          print(' Model: $model');
          print(' Device ID: ${statusData['deviceId']}');
          print(' Battery: ${statusData['batteryLevel']}%');
          print(' Server: ${statusData['serverIp']}:${statusData['serverPort']}');
          print(' APN: ${statusData['apn']}');
        }
      }
      await update();
      return;
    }

    await update();
  }

  // ===== HELPER METHODS =====

  String? _parseICCID(String message) {
    final patterns = [
      RegExp(r'ICCID[:\s]+([A-F0-9]{15,22})', caseSensitive: false),
      RegExp(r'CCID[:\s]+([A-F0-9]{15,22})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message.trim());
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  bool _isAcknowledgment(String body) {
    final acks = [
      'SET APN OK', 'SET CENTER NUMBER OK', 'SET SOS NUMBER OK',
      'SET ARM MODE OK', 'SET VIBRATE ALARM OK', 'RESUME FUEL OK',
      'FUEL WILL BE CUT OFF', 'OPEN TRAFFIC OK', 'CLOSE TRAFFIC OK',
      'RESTORE FACTORY SETTINGS OK', 'RESTARTING',
      'SET LOW VOLTAGE ALARM OK', 'SET ACC ALARM OK',
      'CANCEL VIBRATE ALARM OK', 'CANCEL SHIFT ALARM OK',
      'CANCEL OVERSPEED ALARM OK', 'CANCEL LOW VOLTAGE ALARM OK'
    ];
    return acks.any((ack) => body.toUpperCase().contains(ack));
  }

  bool _isStatusResponse(String body) {
    return body.contains('BATTERY:') && body.contains('GPS:');
  }

  bool _isParameterResponse(String body) {
    return body.contains('ID:') && body.contains('IMEI:') && body.contains('TIMER:');
  }

  void _parseStatusResponse(String body) {
    // Parse battery
    final batteryMatch = RegExp(r'BATTERY:\s*(\d+)%').firstMatch(body);
    if (batteryMatch != null) {
      battery = int.tryParse(batteryMatch.group(1)!) ?? battery;
    }
  }

  void _parseParameterResponse(String body) {
    // Parse IMEI
    final imeiMatch = RegExp(r'IMEI:(\d+)').firstMatch(body);
    if (imeiMatch != null) {
      id = imeiMatch.group(1)!;
    }

    // Parse APN
    final apnMatch = RegExp(r'APN:([^\s]+)').firstMatch(body);
    if (apnMatch != null) {
      apn = apnMatch.group(1)!;
    }

    // Parse speed limit
    final speedMatch = RegExp(r'SPEEDLIMIT:\s*(\d+)km/h').firstMatch(body);
    if (speedMatch != null) {
      speedLimit = int.tryParse(speedMatch.group(1)!) ?? speedLimit;
    }
  }

  Future<void> _parseLocationResponse(String body, DateTime timestamp) async {
    if (body.contains('LAT:') && body.contains('LON:')) {
      // Parse coordinate format
      final latMatch = RegExp(r'LAT:[NS]?(-?\d+\.\d+)').firstMatch(body);
      final lonMatch = RegExp(r'LON:[EW]?(-?\d+\.\d+)').firstMatch(body);

      if (latMatch != null && lonMatch != null) {
        TrackerPosition position = TrackerPosition();
        position.timestamp = timestamp;
        position.latitude = double.parse(latMatch.group(1)!);
        position.longitude = double.parse(lonMatch.group(1)!);
        await addPosition(position);
      }
    } else if (body.startsWith('http')) {
      // Parse Google Maps URL
      final urlMatch = RegExp(r'q=([+-]?\d+\.\d+),([+-]?\d+\.\d+)').firstMatch(body);
      if (urlMatch != null) {
        TrackerPosition position = TrackerPosition();
        position.timestamp = timestamp;
        position.latitude = double.parse(urlMatch.group(1)!);
        position.longitude = double.parse(urlMatch.group(2)!);
        await addPosition(position);
      }
    }
  }

  void _parseSOSNumbers(String body) {
    // Parse SOS:13267052361,13488888888,13599999999
    final sosMatch = RegExp(r'SOS:([^#\n\r]+)').firstMatch(body);
    if (sosMatch != null) {
      List<String> numbers = sosMatch.group(1)!.split(',');
      sosNumbers = List.filled(3, '');
      for (int i = 0; i < numbers.length && i < 3; i++) {
        sosNumbers[i] = numbers[i].trim();
      }
    }
  }

  // ===== UTILITY GETTERS =====

  /// Statistics about messages
  Map<String, int> get messageStats {
    final DateTime last24Hours = DateTime.now().subtract(const Duration(hours: 24));
    final int recentCount = _messages
        .where((msg) => msg.timestamp.isAfter(last24Hours))
        .length;

    return {
      'total': _messages.length,
      'recent': recentCount,
      'sent': _messages.where((msg) => msg.direction == MessageDirection.SENT).length,
      'received': _messages.where((msg) => msg.direction == MessageDirection.RECEIVED).length,
    };
  }

  /// Get the last known position
  TrackerPosition? get lastPosition {
    return _positions.isNotEmpty ? _positions.last : null;
  }

  /// Get last message
  TrackerMessage? get lastMessage {
    return _messages.isNotEmpty ? _messages.last : null;
  }

  /// Check if tracker is online (received message in last 24h)
  bool get isOnline {
    if (_messages.isEmpty) return false;
    final last24h = DateTime.now().subtract(const Duration(hours: 24));
    return _messages.any((msg) =>
    msg.direction == MessageDirection.RECEIVED &&
        msg.timestamp.isAfter(last24h));
  }

  /// Get battery status string
  String get batteryStatus {
    if (battery <= 0) return 'Unknown';
    if (battery <= 20) return 'Low ($battery%)';
    if (battery <= 50) return 'Medium ($battery%)';
    return 'Good ($battery%)';
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'id': id,
      'name': name,
      'licensePlate': licensePlate,
      'chassisNumber': chassisNumber,
      'model': model,
      'color': color,
      'phoneNumber': phoneNumber,
      'adminNumber': adminNumber,
      'sosNumbers': sosNumbers.join(','),
      'pin': pin,
      'speedLimit': speedLimit,
      'sleepLimit': sleepLimit,
      'ignitionAlarm': ignitionAlarm ? 1 : 0,
      'powerAlarmSMS': powerAlarmSMS ? 1 : 0,
      'powerAlarmCall': powerAlarmCall ? 1 : 0,
      'battery': battery,
      'apn': apn,
      'iccid': iccid,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Create Tracker from Map
  factory Tracker.fromMap(Map<String, dynamic> map) {
    final tracker = Tracker()
      ..uuid = map['uuid'] ?? ''
      ..id = map['id'] ?? ''
      ..name = map['name'] ?? 'Tracker'
      ..licensePlate = map['licensePlate'] ?? ''
      ..chassisNumber = map['chassisNumber'] ?? ''
      ..model = map['model'] ?? ''
      ..color = map['color'] ?? 0xFFFF0000
      ..phoneNumber = map['phoneNumber'] ?? ''
      ..adminNumber = map['adminNumber'] ?? ''
      ..pin = map['pin'] ?? '123456'
      ..speedLimit = map['speedLimit'] ?? 0
      ..sleepLimit = map['sleepLimit'] ?? 0
      ..ignitionAlarm = (map['ignitionAlarm'] ?? 0) == 1
      ..powerAlarmSMS = (map['powerAlarmSMS'] ?? 0) == 1
      ..powerAlarmCall = (map['powerAlarmCall'] ?? 0) == 1
      ..battery = map['battery'] ?? 0
      ..apn = map['apn'] ?? ''
      ..iccid = map['iccid'] ?? ''
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0);

    // Parse SOS numbers
    String sosStr = map['sosNumbers'] ?? '';
    if (sosStr.isNotEmpty) {
      List<String> numbers = sosStr.split(',');
      tracker.sosNumbers = List.filled(3, '');
      for (int i = 0; i < numbers.length && i < 3; i++) {
        tracker.sosNumbers[i] = numbers[i].trim();
      }
    }

    return tracker;
  }

  @override
  String toString() {
    return 'Tracker{uuid: $uuid, name: $name, phoneNumber: $phoneNumber, battery: $battery%, lastUpdate: $timestamp}';
  }
}
