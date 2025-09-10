import 'package:flutter/material.dart';
import 'app.dart';
import 'package:provider/provider.dart';
import 'package:trackmate/data/settings.dart' as app_settings;
import 'package:trackmate/database/tracker_db.dart'; // ← Aggiungi questo import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  await app_settings.Settings.global.initialize();

  runApp(
    MultiProvider( // ← Usa MultiProvider invece di singolo ChangeNotifierProvider
      providers: [
        ChangeNotifierProvider<app_settings.Settings>.value(
          value: app_settings.Settings.global,
        ),
        ChangeNotifierProvider<TrackerNotifier>.value( // ← Aggiungi il TrackerNotifier
          value: TrackerDB.changeNotifier,
        ),
      ],
      child: const App(),
    ),
  );
}
