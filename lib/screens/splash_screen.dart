import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/utils/sms.dart';
import 'package:trackmate/screens/setup_wizard.dart';
import 'package:trackmate/screens/menu.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;

  String _statusKey = 'initializing';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _logoAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _textAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _progressController.forward();
    });
  }

  Future<void> _initialize() async {
    try {
      await _runInitializationStep('initializingDatabase', _initializeDatabase);
      await _runInitializationStep('checkingGPSPermissions', _requestPermissions);
      await _runInitializationStep('importingSMS', _importSMS);
      await _runInitializationStep('startingSMSListener', _startSMSListener);
      await _runInitializationStep('checkingConfiguration', _checkSetupAndNavigate);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _runInitializationStep(String statusKey, Future<void> Function() step) async {
    _updateStatus(statusKey);
    await step();
    await _updateProgress();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _initializeDatabase() async {
    try {
      await DataBase.get();
    } catch (e) {
      throw Exception('Database initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied, continuing without GPS features');
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  Future<void> _importSMS() async {
    try {
      await SMSUtils.importReceived();
    } catch (e) {
      debugPrint('SMS import failed: $e');
    }
  }

  Future<void> _startSMSListener() async {
    try {
      await SMSUtils.startListener();
    } catch (e) {
      debugPrint('SMS listener start failed: $e');
    }
  }

  Future<void> _checkSetupAndNavigate() async {
    final sp = await SharedPreferences.getInstance();
    final isSetupDone = sp.getBool('setup_done') ?? false;

    if (!isSetupDone) {
      final db = await DataBase.get();
      final trackers = await TrackerDB.list(db!);
      if (trackers.isEmpty) {
        _updateStatus('firstConfiguration');
        await Future.delayed(const Duration(milliseconds: 800));
        _navigateToSetup();
      } else {
        await sp.setBool('setup_done', true);
        _navigateToMain();
      }
    } else {
      _updateStatus('loadingComplete');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToMain();
    }
  }

  void _updateStatus(String statusKey) {
    if (mounted) {
      setState(() => _statusKey = statusKey);
    }
  }

  Future<void> _updateProgress() async {
    if (mounted) {
      setState(() {
        _progress += 0.2;
        if (_progress > 1.0) _progress = 1.0;
      });
    }
  }

  void _handleError(dynamic error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
        _statusKey = 'errorOccurred';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _navigateToMain();
      });
    }
  }

  // ✅ USA NAMED ROUTES
  void _navigateToSetup() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/setup');
  }

  void _navigateToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
                colorScheme.primaryContainer,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo animato
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.gps_fixed,
                              size: 70,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Titoli
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              localizations?.get('carTracker') ?? 'CarTracker',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              localizations?.get('appSubtitle') ?? 'GPS Tracking & Monitoring',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 3),

                  // Progress section
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _progressAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress bar
                            Container(
                              width: double.infinity,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Status text
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!_hasError) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ] else ...[
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Flexible(
                                  child: Text(
                                    localizations?.get(_statusKey) ?? _statusKey,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_hasError && _errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Continuing in fallback mode...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // Copyright
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textAnimation.value * 0.6,
                        child: Text(
                          localizations?.get('copyright') ?? '© 2025 CarTracker',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
