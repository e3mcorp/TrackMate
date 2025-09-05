import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/screens/setup/setup_steps.dart';
import 'package:trackmate/screens/setup/setup_models.dart';
import 'package:trackmate/screens/setup/setup_commands.dart';

enum SetupMode { firstDevice, addDevice }

class SetupWizardScreen extends StatefulWidget {
  final SetupMode mode;
  final VoidCallback? onComplete;

  const SetupWizardScreen({
    required this.mode,
    this.onComplete,
    super.key,
  });

  static Future<SetupMode> detectSetupMode() async {
    final db = await DataBase.get();
    final trackers = await TrackerDB.list(db!);
    return trackers.isEmpty ? SetupMode.firstDevice : SetupMode.addDevice;
  }

  static Future<void> showSetupWizard(BuildContext context) async {
    final mode = await detectSetupMode();
    if (!context.mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => SetupWizardScreen(mode: mode),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  int _currentStep = 0;
  int get _totalSteps => widget.mode == SetupMode.firstDevice ? 5 : 4;

  late final SetupData _setupData;
  late final SetupCommands _setupCommands;
  late final List<GlobalKey<FormState>> _formKeys;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _setupData = SetupData();
    _setupCommands = SetupCommands(_setupData);
    _setupAnimations();
    _formKeys = List.generate(_totalSteps, (_) => GlobalKey<FormState>());
    _restoreProgress();
    _prefillDefaults();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _setupData.dispose();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final sp = await SharedPreferences.getInstance();
    final key = widget.mode == SetupMode.firstDevice ? 'setup_step' : 'add_step';
    final step = sp.getInt(key) ?? 0;
    if (step < _totalSteps) {
      setState(() => _currentStep = step);
    }
  }

  Future<void> _persistProgress() async {
    final sp = await SharedPreferences.getInstance();
    final key = widget.mode == SetupMode.firstDevice ? 'setup_step' : 'add_step';
    await sp.setInt(key, _currentStep);
  }

  Future<void> _prefillDefaults() async {
    if (widget.mode == SetupMode.addDevice) {
      final db = await DataBase.get();
      final existing = await TrackerDB.list(db!);
      if (existing.isNotEmpty) {
        final first = existing.first;
        _setupData.apnController.text = first.apn;
        _setupData.useExistingConfig = true;
      }
    }
  }

  Future<void> _next() async {
    final formIndex = _getFormIndex();
    if (formIndex >= 0 && formIndex < _formKeys.length) {
      final form = _formKeys[formIndex].currentState;
      if (form != null && !form.validate()) {
        _showValidationError();
        return;
      }
      form?.save();
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      await _persistProgress();
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      HapticFeedback.lightImpact();
    } else {
      await _finish();
    }
  }

  Future<void> _back() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      await _persistProgress();
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      HapticFeedback.lightImpact();
    }
  }

  int _getFormIndex() {
    if (widget.mode == SetupMode.firstDevice) {
      if (_currentStep == 1) return 0; // Device data
      if (_currentStep == 2) return 1; // Network config
      if (_currentStep == 3) return 2; // Admin number
    } else {
      if (_currentStep == 0) return 0; // Quick device
      if (_currentStep == 1) return 1; // Quick config
      if (_currentStep == 1) return 2; // Quick config
    }
    return -1;
  }

  void _showValidationError() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(localizations?.get('pleaseFixErrors') ?? 'Please fix the errors above'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendCommand(String commandType) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _setupCommands.sendCommand(commandType, context);
      _showSuccessSnackBar('${commandType}Sent');
    } catch (e) {
      _showErrorSnackBar('Failed to send $commandType: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _testConnection() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _setupCommands.testConnection(context);
      _showSuccessSnackBar('testSent');
    } catch (e) {
      _showErrorSnackBar('Test failed: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  void _showSuccessSnackBar(String messageKey) {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(localizations?.get(messageKey) ?? messageKey),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ METODO _FINISH COMPLETAMENTE CORRETTO CON ADMIN_NUMBER
  Future<void> _finish() async {
    setState(() => _sending = true);

    try {
      // ✅ CREA TRACKER con TUTTI i campi necessari incluso adminNumber
      final tracker = Tracker()
        ..name = _setupData.nameController.text.trim()
        ..phoneNumber = _setupData.trackerPhoneController.text.trim()
        ..pin = _setupData.pinController.text.trim()
        ..adminNumber = _setupData.adminPhoneController.text.trim() // ✅ puo essere vuoto
        ..apn = _setupData.apnController.text.trim();

      if (kDebugMode) {
        print('✅ Setup Wizard - Salvando tracker:');
        print('  Nome: ${tracker.name}');
        print('  Phone: ${tracker.phoneNumber}');
        print('  Admin: ${tracker.adminNumber}'); // ✅ Verifichiamo che sia presente
        print('  PIN: ${tracker.pin}');
        print('  APN: ${tracker.apn}');
      }

      final db = await DataBase.get();
      await TrackerDB.add(db!, tracker);

      // ✅ PULISCI SharedPreferences
      final sp = await SharedPreferences.getInstance();
      if (widget.mode == SetupMode.firstDevice) {
        await sp.setBool('setup_done', true);
        await sp.remove('setup_step');
      } else {
        await sp.remove('add_step');
      }

      if (!mounted) return;

      // ✅ FEEDBACK UTENTE
      HapticFeedback.mediumImpact();

      // ✅ NAVIGAZIONE CORRETTA
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Setup Error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attenzione: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );

        // ✅ NAVIGA ALLA HOME anche in caso di errore
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }

    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  List<Widget> _buildSteps() {
    if (widget.mode == SetupMode.firstDevice) {
      return [
        WelcomeStep(),
        DeviceDataStep(
          formKey: _formKeys[0],
          setupData: _setupData,
        ),
        NetworkConfigStep(
          formKey: _formKeys[1],
          setupData: _setupData,
          onSendCommand: _sendCommand,
          isSending: _sending,
        ),
        AdminNumberStep(
          formKey: _formKeys[2],
          setupData: _setupData,
          onSendCommand: _sendCommand,
          isSending: _sending,
        ),
        TestAndFinishStep(
          setupData: _setupData,
          onTest: _testConnection,
          isSending: _sending,
        ),
      ];
    } else {
      return [
        QuickDeviceStep(
          formKey: _formKeys[0],
          setupData: _setupData,
        ),
        QuickConfigStep(
          formKey: _formKeys[1],
          setupData: _setupData,
          onSendCommand: _sendCommand,
          isSending: _sending,
        ),
        AdminNumberStep(
          formKey: _formKeys[2],
          setupData: _setupData,
          onSendCommand: _sendCommand,
          isSending: _sending,
        ),
        QuickFinishStep(
          setupData: _setupData,
          onTest: _testConnection,
          isSending: _sending,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canBack = _currentStep > 0;
    final isLast = _currentStep == _totalSteps - 1;

    final title = widget.mode == SetupMode.firstDevice
        ? localizations?.get('welcomeToTrackMate') ?? 'Welcome to TrackMate'
        : localizations?.get('addTracker') ?? 'Add Tracker';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        leading: canBack
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _sending ? null : _back,
        )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps * _progressAnimation.value,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      minHeight: 4,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${localizations?.get('step') ?? 'Step'} ${_currentStep + 1} ${localizations?.get('of') ?? 'of'} $_totalSteps',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Steps content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildSteps(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (canBack) ...[
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _back,
                    icon: const Icon(Icons.chevron_left),
                    label: Text(localizations?.get('back') ?? 'Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sending ? null : (isLast ? _finish : _next),
                    icon: _sending
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                      ),
                    )
                        : Icon(isLast ? Icons.check : Icons.chevron_right),
                    label: Text(
                      isLast
                          ? localizations?.get('complete') ?? 'Complete'
                          : localizations?.get('next') ?? 'Next',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
