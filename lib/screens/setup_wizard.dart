import 'package:flutter/material.dart';
import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:trackmate/utils/sms.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum SetupMode { firstDevice, addOrEdit }

class SetupWizardScreen extends StatefulWidget {
  final SetupMode mode;
  final Tracker? initial;
  final VoidCallback? onComplete;

  const SetupWizardScreen({
    super.key,
    required this.mode,
    this.initial,
    this.onComplete,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  final _formKeys = List.generate(6, (_) => GlobalKey<FormState>());
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSendingSMS = false;
  bool _timezoneInitialized = false;
  late Tracker tracker;

  // Controllers
  late final TextEditingController nameCtrl;
  late final TextEditingController plateCtrl;
  late final TextEditingController modelCtrl;
  late Color color;
  late final TextEditingController phoneCtrl;
  late final TextEditingController adminCtrl;
  late final TextEditingController pinCtrl;
  late final TextEditingController apnCtrl;
  late final TextEditingController apnUserCtrl;
  late final TextEditingController apnPassCtrl;
  late final TextEditingController speedCtrl;
  bool ignitionAlarm = false;
  bool powerAlarmSMS = false;
  bool powerAlarmCall = false;

  // Timezone management
  String _selectedTimezone = 'Europe/Rome';
  List<Map<String, String>> _allTimezones = [];
  List<Map<String, String>> _filteredTimezones = [];
  final TextEditingController _timezoneSearchCtrl = TextEditingController();

  // SMS Configuration
  final List<String> _configurationSteps = [];
  final Map<String, bool> _smsStatus = {};

  @override
  void initState() {
    super.initState();
    tracker = widget.initial != null ? Tracker.fromMap(widget.initial!.toMap()) : Tracker();
    _initializeControllers();
    _initializeTimezone();
    _timezoneSearchCtrl.addListener(() {
      _filterTimezones(_timezoneSearchCtrl.text);
    });
  }

  void _initializeControllers() {
    nameCtrl = TextEditingController(text: tracker.name);
    plateCtrl = TextEditingController(text: tracker.licensePlate);
    modelCtrl = TextEditingController(text: tracker.model);
    color = Color(tracker.color);
    phoneCtrl = TextEditingController(text: tracker.phoneNumber);
    adminCtrl = TextEditingController(text: tracker.adminNumber);
    pinCtrl = TextEditingController(text: tracker.pin.isEmpty ? '123456' : tracker.pin);
    apnCtrl = TextEditingController(text: tracker.apn);
    apnUserCtrl = TextEditingController();
    apnPassCtrl = TextEditingController();
    speedCtrl = TextEditingController(text: tracker.speedLimit > 0 ? tracker.speedLimit.toString() : '');
    ignitionAlarm = tracker.ignitionAlarm;
    powerAlarmSMS = tracker.powerAlarmSMS;
    powerAlarmCall = tracker.powerAlarmCall;
  }

  @override
  void dispose() {
    _pageController.dispose();
    nameCtrl.dispose();
    plateCtrl.dispose();
    modelCtrl.dispose();
    phoneCtrl.dispose();
    adminCtrl.dispose();
    pinCtrl.dispose();
    apnCtrl.dispose();
    apnUserCtrl.dispose();
    apnPassCtrl.dispose();
    speedCtrl.dispose();
    _timezoneSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeTimezone() async {
    try {
      tz.initializeTimeZones();
      final locations = tz.timeZoneDatabase.locations;
      _allTimezones = locations.entries.map((entry) {
        final location = entry.value;
        final now = tz.TZDateTime.now(location);
        final offset = now.timeZoneOffset;
        final offsetHours = offset.inHours;
        final offsetMinutes = (offset.inMinutes % 60).abs();
        String offsetString;
        if (offsetMinutes == 0) {
          offsetString = 'GMT${offsetHours >= 0 ? '+' : ''}$offsetHours';
        } else {
          offsetString = 'GMT${offsetHours >= 0 ? '+' : ''}$offsetHours:${offsetMinutes.toString().padLeft(2, '0')}';
        }
        return {'name': '${entry.key} ($offsetString)', 'value': entry.key};
      }).toList();

      _allTimezones.sort((a, b) {
        final aIsEurope = a['value']!.startsWith('Europe/');
        final bIsEurope = b['value']!.startsWith('Europe/');
        if (aIsEurope && !bIsEurope) return -1;
        if (!aIsEurope && bIsEurope) return 1;
        final aIsRome = a['value'] == 'Europe/Rome';
        final bIsRome = b['value'] == 'Europe/Rome';
        if (aIsRome && !bIsRome) return -1;
        if (!aIsRome && bIsRome) return 1;
        return a['value']!.compareTo(b['value']!);
      });

      _filteredTimezones = List.from(_allTimezones);

      try {
        final deviceTimezone = DateTime.now().timeZoneName;
        if (deviceTimezone.contains('CEST') || deviceTimezone.contains('CET')) {
          _selectedTimezone = 'Europe/Rome';
        }
      } catch (_) {}

      setState(() => _timezoneInitialized = true);
    } catch (e) {
      _selectedTimezone = 'UTC';
      _allTimezones = [
        {'name': 'Europe/Rome (GMT+1)', 'value': 'Europe/Rome'},
        {'name': 'UTC (GMT+0)', 'value': 'UTC'}
      ];
      _filteredTimezones = List.from(_allTimezones);
      setState(() => _timezoneInitialized = true);
    }
  }

  void _filterTimezones(String query) {
    setState(() {
      _filteredTimezones = query.isEmpty
          ? List.from(_allTimezones)
          : _allTimezones.where((tz) => tz['name']!.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  String _generateTimezoneCommand(String timezoneName) {
    try {
      final location = tz.getLocation(timezoneName);
      final offset = tz.TZDateTime.now(location).timeZoneOffset;
      final direction = !offset.isNegative ? 'E' : 'W';
      final totalMinutes = offset.inMinutes.abs();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      int validMinutes = [0, 15, 30, 45].reduce((a, b) => (minutes - a).abs() < (minutes - b).abs() ? a : b);
      return 'GMT,$direction,$hours${validMinutes > 0 ? ',$validMinutes' : ''}#';
    } catch (e) {
      return 'GMT,E,1#';
    }
  }

  void _prepareConfigurationSteps() {
    _configurationSteps.clear();
    _smsStatus.clear();

    final currentApn = apnCtrl.text.trim();
    final currentApnUser = apnUserCtrl.text.trim();
    final currentApnPass = apnPassCtrl.text.trim();
    final currentAdmin = adminCtrl.text.trim();
    final currentPin = pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim();
    final currentSpeed = speedCtrl.text.trim();

    if (currentApn.isNotEmpty) {
      _configurationSteps.add(currentApnUser.isNotEmpty && currentApnPass.isNotEmpty
          ? 'APN,$currentApn,$currentApnUser,$currentApnPass#'
          : 'APN,$currentApn#');
    }

    if (currentAdmin.isNotEmpty) {
      _configurationSteps.add('CENTER,$currentPin,A,$currentAdmin#');
    }

    if (currentSpeed.isNotEmpty) {
      final int speedLimit = int.tryParse(currentSpeed) ?? 0;
      if (speedLimit > 0) {
        _configurationSteps.add('SPEED,ON,$speedLimit,1#');
      }
    }

    if (ignitionAlarm) {
      _configurationSteps.add('ACCALM,ON,2,1#');
    }

    if (powerAlarmSMS || powerAlarmCall) {
      _configurationSteps.add('PWRALM,ON,${powerAlarmCall ? 2 : 1}#');
    }

    _configurationSteps.add(_generateTimezoneCommand(_selectedTimezone));

    for (String step in _configurationSteps) {
      _smsStatus[step] = false;
    }
  }

  bool _validateCurrentStep() => _formKeys[_currentStep].currentState?.validate() ?? false;

  Future<void> _persist() async {
    setState(() => _isLoading = true);
    try {
      tracker
        ..name = nameCtrl.text.trim().isEmpty ? 'Tracker' : nameCtrl.text.trim()
        ..licensePlate = plateCtrl.text.trim()
        ..model = modelCtrl.text.trim()
        ..color = color.value
        ..phoneNumber = phoneCtrl.text.trim()
        ..adminNumber = adminCtrl.text.trim()
        ..pin = (pinCtrl.text.trim().isEmpty ? '123456' : pinCtrl.text.trim())
        ..apn = apnCtrl.text.trim()
        ..ignitionAlarm = ignitionAlarm
        ..powerAlarmSMS = powerAlarmSMS
        ..powerAlarmCall = powerAlarmCall
        ..speedLimit = int.tryParse(speedCtrl.text.trim()) ?? 0
        ..timestamp = DateTime.now();

      final db = await DataBase.get();
      if (widget.initial == null) {
        await TrackerDB.add(db!, tracker);
      } else {
        await TrackerDB.update(db!, tracker);
      }

      TrackerDB.changeNotifier.notifyListeners();
    } catch (e) {
      if (mounted) _showError('Errore nel salvataggio: $e');
      return;
    } finally {
      setState(() => _isLoading = false);
    }

    widget.onComplete?.call();
    if (mounted) Navigator.of(context).pop(tracker);
  }

  void _nextStep() async {
    if (!_validateCurrentStep()) return;

    if (_currentStep == 3) {
      _prepareConfigurationSteps();
    }

    if (_currentStep < 5) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      await _persist();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  void _onStepTapped(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _sendConfigurationSMS(String command) async {
    if (phoneCtrl.text.trim().isEmpty) {
      _showError('Numero SIM del tracker non configurato');
      return;
    }

    setState(() => _isSendingSMS = true);
    try {
      if (!await SMSUtils.hasPermissions()) {
        if (!await SMSUtils.requestPermissions()) {
          _showError('Permessi SMS necessari');
          return;
        }
      }

      await SMSUtils.send(command, phoneCtrl.text.trim(), context: context);
      setState(() => _smsStatus[command] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Comando inviato: ${command.substring(0, command.indexOf('#'))}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      _showError('Errore invio SMS: $e');
    } finally {
      setState(() => _isSendingSMS = false);
    }
  }

  Future<void> _sendAllConfigurationSMS() async {
    for (String command in _configurationSteps) {
      if (!(_smsStatus[command] ?? false)) {
        await _sendConfigurationSMS(command);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _showTimezonePicker() async {
    _timezoneSearchCtrl.clear();
    _filterTimezones('');

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalState) {
            void filter(String query) {
              modalState(() {
                _filteredTimezones = query.isEmpty
                    ? List.from(_allTimezones)
                    : _allTimezones.where((tz) => tz['name']!.toLowerCase().contains(query.toLowerCase())).toList();
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              maxChildSize: 0.9,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _timezoneSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cerca per città o regione...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: _timezoneSearchCtrl.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _timezoneSearchCtrl.clear();
                              filter('');
                            },
                          )
                              : null,
                        ),
                        onChanged: filter,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredTimezones.length,
                        itemBuilder: (context, index) {
                          final timezone = _filteredTimezones[index];
                          return ListTile(
                            title: Text(timezone['name']!),
                            onTap: () => Navigator.of(context).pop(timezone['value']),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selected != null) setState(() => _selectedTimezone = selected);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? localizations?.addTracker ?? 'Aggiungi Tracker' : localizations?.editTracker ?? 'Modifica Tracker'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(
                6,
                    (index) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepLabel('Base', 0),
                _buildStepLabel('SIM', 1),
                _buildStepLabel('Fuso', 2),
                _buildStepLabel('Allarmi', 3),
                _buildStepLabel('SMS', 4),
                _buildStepLabel('Fine', 5),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (step) => setState(() => _currentStep = step),
              children: [
                _buildStepOne(),
                _buildStepTwo(),
                _buildTimezoneStep(),
                _buildStepThree(),
                _buildStepFour(),
                _buildStepFive(),
              ],
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (_isLoading || _isSendingSMS) ? null : _previousStep,
                        child: Text(localizations?.back ?? 'Indietro'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isLoading || _isSendingSMS) ? null : _nextStep,
                      child: (_isLoading || _isSendingSMS)
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_currentStep == 5 ? localizations?.save ?? 'Salva' : localizations?.next ?? 'Avanti'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String text, int stepIndex) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = stepIndex == _currentStep;
    final isCompleted = stepIndex < _currentStep;

    return InkWell(
      onTap: () => _onStepTapped(stepIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive || isCompleted ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.baseInfo ?? 'Informazioni Base',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.basicInfoDesc ?? 'Inserisci le informazioni di base del tracker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: localizations?.trackerName ?? 'Nome tracker',
                hintText: localizations?.trackerNameHint ?? 'es. Auto Marco',
                prefixIcon: const Icon(Icons.label_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserire un nome' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: plateCtrl,
              decoration: InputDecoration(
                labelText: localizations?.licensePlate ?? 'Targa (opzionale)',
                hintText: localizations?.licensePlateHint ?? 'es. AB123CD',
                prefixIcon: const Icon(Icons.directions_car_outlined),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: modelCtrl,
              decoration: InputDecoration(
                labelText: localizations?.vehicleModel ?? 'Modello veicolo (opzionale)',
                hintText: localizations?.vehicleModelHint ?? 'es. Fiat Panda',
                prefixIcon: const Icon(Icons.info_outline),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.colorIdentification ?? 'Colore identificativo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.brown,
              ]
                  .map((c) => GestureDetector(
                onTap: () => setState(() => color = c),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: color.value == c.value ? Border.all(color: Colors.black, width: 3) : null,
                  ),
                  child: color.value == c.value ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTwo() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.simConfig ?? 'Configurazione SIM',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.simConfigDesc ?? 'Configura la SIM card e i parametri di connessione',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: localizations?.trackerSimNumber ?? 'Numero SIM del tracker *',
                hintText: localizations?.simNumberHint ?? '+39 123 456 7890',
                prefixIcon: const Icon(Icons.sim_card_outlined),
                helperText: 'Necessario per inviare comandi SMS',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserire numero SIM' : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: adminCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: localizations?.adminNumber ?? 'Numero amministratore (opzionale)',
                hintText: localizations?.adminNumberHint ?? '+39 987 654 3210',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                helperText: 'Numero che può inviare comandi al tracker',
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: pinCtrl,
              decoration: InputDecoration(
                labelText: localizations?.commandPin ?? 'PIN comandi',
                hintText: localizations?.commandPinHint ?? '123456',
                prefixIcon: const Icon(Icons.lock_outline),
                helperText: localizations?.commandPinHelp ?? 'PIN per i comandi (default: 123456)',
              ),
              validator: (v) => (v?.trim() ?? '').isNotEmpty && (v!.length != 6 || int.tryParse(v) == null)
                  ? 'PIN deve essere 6 cifre'
                  : null,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.apnConfig ?? 'Configurazione APN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: apnCtrl,
                      decoration: InputDecoration(
                        labelText: localizations?.apn ?? 'APN',
                        hintText: 'internet.it, mobile.vodafone.it',
                        prefixIcon: const Icon(Icons.network_cell_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: apnUserCtrl,
                            decoration: InputDecoration(
                              labelText: localizations?.usernameOptional ?? 'Username (opzionale)',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: apnPassCtrl,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: localizations?.passwordOptional ?? 'Password (opzionale)',
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneStep() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.timezone ?? 'Fuso Orario',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.timezoneSelect ?? 'Seleziona il fuso orario del tracker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            ListTile(
              title: Text(_selectedTimezone, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(localizations?.timezoneSelected ?? 'Fuso Orario Selezionato'),
              leading: Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
              trailing: const Icon(Icons.arrow_drop_down),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: _timezoneInitialized ? _showTimezonePicker : null,
            ),
            const SizedBox(height: 24),
            if (_timezoneInitialized)
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comando SMS che verrà inviato:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Text(
                          _generateTimezoneCommand(_selectedTimezone),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepThree() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.alarmConfig ?? 'Configurazione Allarmi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.alarmConfigDesc ?? 'Configura gli allarmi e le notifiche del tracker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: speedCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations?.speedLimit ?? 'Limite velocità (km/h)',
                hintText: localizations?.speedLimitHint ?? 'Vuoto per disattivare',
                prefixIcon: const Icon(Icons.speed_outlined),
                suffixText: 'km/h',
              ),
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty) return null;
                if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Inserire numero valido';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(localizations?.ignitionAlarm ?? 'Allarme accensione (ACC)'),
                      subtitle: Text(localizations?.ignitionAlarmDesc ?? 'Notifica all\'accensione/spegnimento'),
                      value: ignitionAlarm,
                      onChanged: (val) => setState(() => ignitionAlarm = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(localizations?.powerAlarmSMS ?? 'Allarme alimentazione (SMS)'),
                      subtitle: const Text('SMS se si stacca la batteria'),
                      value: powerAlarmSMS,
                      onChanged: (val) => setState(() => powerAlarmSMS = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(localizations?.powerAlarmCall ?? 'Allarme alimentazione (Chiamata)'),
                      subtitle: const Text('Chiamata se si stacca la batteria'),
                      value: powerAlarmCall,
                      onChanged: (val) => setState(() => powerAlarmCall = val),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepFour() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[4],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.smsConfig ?? 'Configurazione via SMS',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.smsConfigDesc ?? 'Invia i comandi per configurare il tracker',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            if (_configurationSteps.isEmpty)
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        localizations?.noConfigNeeded ?? 'Nessuna configurazione necessaria',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations?.defaultSettingsDesc ?? 'Il tracker può essere utilizzato con le impostazioni di default',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.commandsToSend ?? 'Comandi da inviare:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._configurationSteps.map((command) {
                        final isCompleted = _smsStatus[command] ?? false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isCompleted ? Colors.green : Theme.of(context).colorScheme.outline,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getCommandDescription(command),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, size: 20),
                                onPressed: (_isSendingSMS || isCompleted) ? null : () => _sendConfigurationSMS(command),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_configurationSteps.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: (_isSendingSMS || _configurationSteps.every((cmd) => _smsStatus[cmd] == true))
                      ? null
                      : _sendAllConfigurationSMS,
                  icon: _isSendingSMS
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_isSendingSMS
                      ? localizations?.sendingInProgress ?? 'Invio in corso...'
                      : localizations?.allCommandsSent ?? 'Invia tutti i comandi'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepFive() {
    final localizations = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[5],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.configurationComplete ?? 'Configurazione Completata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.green.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.trackerReady ?? 'Tracker pronto!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations?.pressSaveToComplete ?? 'Premi "Salva" per completare la configurazione.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.configurationSummary ?? 'Riepilogo Configurazione',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(localizations?.name ?? 'Nome', nameCtrl.text.trim().isEmpty ? 'Tracker' : nameCtrl.text.trim()),
                    _buildSummaryRow('Numero SIM', phoneCtrl.text.trim()),
                    _buildSummaryRow(localizations?.timezone ?? 'Fuso orario', _selectedTimezone),
                    if (apnCtrl.text.trim().isNotEmpty) _buildSummaryRow(localizations?.apn ?? 'APN', apnCtrl.text.trim()),
                    _buildSummaryRow(
                      localizations?.smsCommandsSent ?? 'Comandi SMS inviati',
                      '${_smsStatus.values.where((v) => v).length}/${_configurationSteps.length}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _getCommandDescription(String command) {
    if (command.startsWith('APN,')) return 'Configurazione APN';
    if (command.startsWith('CENTER,')) return 'Impostazione numero admin';
    if (command.startsWith('SPEED,')) return 'Impostazione limite velocità';
    if (command.startsWith('ACCALM,')) return 'Attivazione allarme accensione';
    if (command.startsWith('PWRALM,')) return 'Attivazione allarme alimentazione';
    if (command.startsWith('GMT,')) return 'Impostazione fuso orario';
    return command;
  }
}
