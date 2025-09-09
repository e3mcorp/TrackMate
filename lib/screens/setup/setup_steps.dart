import 'package:flutter/material.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:timezones_list/timezone_model.dart';
import 'setup_models.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.secondaryContainer.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.gps_fixed,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            localizations?.get('welcome') ?? 'Benvenuto!',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            localizations?.get('welcomeDescription') ??
                'TrackMate ti aiuta a monitorare i tuoi veicoli tramite tracker GPS.\n\nRiceverai SMS con posizioni, stato della batteria e altre informazioni utili.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          Card(
            elevation: 0,
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureItem(icon: Icons.location_on, text: 'Posizioni in tempo reale'),
                  _FeatureItem(icon: Icons.battery_std, text: 'Monitoraggio batteria'),
                  _FeatureItem(icon: Icons.route, text: 'Storico percorsi'),
                  _FeatureItem(icon: Icons.notifications, text: 'Notifiche automatiche'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureItem({required this.icon, required this.text, super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceDataStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetupData setupData;
  const DeviceDataStep({required this.formKey, required this.setupData, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        onChanged: () => Form.of(primaryFocus!.context!)?.validate(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.get('trackerData') ?? 'Dati Tracker',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: setupData.nameController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerName') ?? 'Nome Tracker',
                hintText: localizations?.get('trackerNameHint') ?? 'es. La mia Auto',
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterName') ?? 'Inserisci un nome'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: setupData.trackerPhoneController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerSIMNumber') ?? 'Numero SIM Tracker',
                hintText: localizations?.get('trackerPhoneHint') ?? '+39 123 456 7890',
                prefixIcon: const Icon(Icons.sim_card),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: localizations?.get('trackerPhoneHelp') ?? 'Numero della SIM nel tracker',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterNumber') ?? 'Inserisci numero di telefono'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: setupData.pinController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerPIN') ?? 'PIN Tracker',
                hintText: localizations?.get('defaultPIN') ?? 'Default: 123456',
                prefixIcon: const Icon(Icons.lock),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().length < 4)
                  ? localizations?.get('pinMinLength') ?? 'PIN deve essere almeno 4 cifre'
                  : null,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localizations?.get('simCreditTip') ?? 'Assicurati che la SIM abbia credito sufficiente',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
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
}

class NetworkConfigStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetupData setupData;
  final Function(String) onSendCommand;
  final bool isSending;
  const NetworkConfigStep({
    required this.formKey,
    required this.setupData,
    required this.onSendCommand,
    required this.isSending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        onChanged: () => Form.of(primaryFocus!.context!)?.validate(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.get('networkConfig') ?? 'Configurazione Rete',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations?.get('apnConfig') ?? 'Configurazione APN',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: setupData.apnController,
              decoration: InputDecoration(
                labelText: localizations?.get('apn') ?? 'APN',
                hintText: localizations?.get('apnHint') ?? 'es. internet',
                prefixIcon: const Icon(Icons.network_cell),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterAPN') ?? 'Inserisci APN'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: setupData.apnUserController,
                    decoration: InputDecoration(
                      labelText: localizations?.get('usernameOptional') ?? 'Username (Opzionale)',
                      prefixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: setupData.apnPasswordController,
                    decoration: InputDecoration(
                      labelText: localizations?.get('passwordOptional') ?? 'Password (Opzionale)',
                      prefixIcon: const Icon(Icons.key),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              localizations?.get('trackingServer') ?? 'Server Tracking',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: setupData.serverHostController,
                    decoration: InputDecoration(
                      labelText: localizations?.get('serverIPHost') ?? 'Server IP/Host',
                      prefixIcon: const Icon(Icons.dns),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? localizations?.get('enterHostIP') ?? 'Inserisci host/IP'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: setupData.serverPortController,
                    decoration: InputDecoration(
                      labelText: localizations?.get('port') ?? 'Porta',
                      prefixIcon: const Icon(Icons.settings_ethernet),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse(v ?? '') == null)
                        ? localizations?.get('invalidPort') ?? 'Porta non valida'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (setupData.timezonesList.isNotEmpty)
              DropdownButtonFormField<String>(
                value: setupData.selectedTimezone,
                items: setupData.timezonesList.map<DropdownMenuItem<String>>((TimezoneModel tz) {
                  return DropdownMenuItem(
                    value: tz.value,
                    child: Text(
                      '${tz.text} (${tz.abbr})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) setupData.selectedTimezone = value;
                },
                decoration: InputDecoration(
                  labelText: localizations?.get('timezone') ?? 'Fuso Orario',
                  prefixIcon: const Icon(Icons.access_time),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                isExpanded: true,
                menuMaxHeight: 300,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations?.get('selectTimezone') ?? 'Seleziona un fuso orario';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('sendConfigurations') ?? 'Invia Configurazioni',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isSending ? null : () => onSendCommand('apn'),
                  icon: const Icon(Icons.settings_cell, size: 20),
                  label: Text(localizations?.get('sendAPN') ?? 'Invia APN'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSending ? null : () => onSendCommand('server'),
                  icon: const Icon(Icons.dns, size: 20),
                  label: Text(localizations?.get('sendServer') ?? 'Invia Server'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSending ? null : () => onSendCommand('timezone'),
                  icon: const Icon(Icons.schedule, size: 20),
                  label: Text(localizations?.get('sendTimezone') ?? 'Invia Timezone'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  localizations?.get('configurationInstructions') ??
                      'Invia queste configurazioni una alla volta e attendi SMS di conferma',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNumberStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetupData setupData;
  final Function(String) onSendCommand;
  final bool isSending;
  const AdminNumberStep({
    required this.formKey,
    required this.setupData,
    required this.onSendCommand,
    required this.isSending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canSendCenter = setupData.adminPhoneController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.get('adminConfiguration') ?? 'Configurazione Amministratore',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('adminDescription') ??
                  'Imposta il numero di telefono che potrà inviare comandi al tracker.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: setupData.adminPhoneController,
              decoration: InputDecoration(
                labelText: localizations?.get('adminPhoneNumber') ?? 'Numero Amministratore',
                hintText: localizations?.get('adminPhoneHint') ?? '+39 123 456 7890',
                prefixIcon: const Icon(Icons.admin_panel_settings),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: localizations?.get('adminPhoneHelp') ?? 'Il tuo numero di telefono personale',
              ),
              keyboardType: TextInputType.phone,
              validator: null, // opzionale
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          localizations?.get('importantNote') ?? 'Nota Importante',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations?.get('adminExplanation') ??
                          '• Numero SIM Tracker: ${setupData.trackerPhoneController.text.isNotEmpty ? setupData.trackerPhoneController.text : "Non impostato"}\n'
                              '• Numero Amministratore: Il TUO numero personale\n'
                              '• Solo l\'amministratore potrà inviare comandi al tracker',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: isSending || !canSendCenter ? null : () => onSendCommand('center'),
              icon: const Icon(Icons.send),
              label: Text(localizations?.get('configureAdmin') ?? 'Configura Amministratore'),
              style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  localizations?.get('centerCommandNote') ??
                      'Questo comando imposta il numero che potrà controllare il tracker',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestAndFinishStep extends StatelessWidget {
  final SetupData setupData;
  final VoidCallback onTest;
  final bool isSending;
  const TestAndFinishStep({
    required this.setupData,
    required this.onTest,
    required this.isSending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations?.get('testAndComplete') ?? 'Test e Completamento',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.get('configurationSummary') ?? 'Riepilogo Configurazione',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryItem(label: localizations?.get('name') ?? 'Nome', value: setupData.nameController.text),
                  _SummaryItem(label: localizations?.get('trackerPhone') ?? 'SIM Tracker', value: setupData.trackerPhoneController.text),
                  _SummaryItem(label: localizations?.get('adminPhone') ?? 'Admin', value: setupData.adminPhoneController.text),
                  _SummaryItem(label: localizations?.get('apn') ?? 'APN', value: setupData.apnController.text),
                  _SummaryItem(label: localizations?.get('server') ?? 'Server', value: '${setupData.serverHostController.text}:${setupData.serverPortController.text}'),
                  _SummaryItem(label: localizations?.get('timezone') ?? 'Fuso Orario', value: setupData.selectedTimezone ?? ''),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            localizations?.get('connectionTest') ?? 'Test Connessione',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isSending ? null : onTest,
            icon: const Icon(Icons.play_arrow),
            label: Text(localizations?.get('testRequestLocation') ?? 'Test Richiesta Posizione'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                localizations?.get('testInstructions') ??
                    'Questo invierà i comandi WHERE e STATUS per testare la connettività',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            color: Colors.green.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.get('setupComplete') ?? 'Configurazione Completa!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations?.get('setupCompleteDescription') ??
                              'Il tuo tracker è ora configurato e pronto all\'uso',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
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
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

class QuickDeviceStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetupData setupData;
  const QuickDeviceStep({required this.formKey, required this.setupData, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        onChanged: () => Form.of(primaryFocus!.context!)?.validate(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.get('newTracker') ?? 'Nuovo Tracker',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.get('enterDeviceData') ?? 'Inserisci le informazioni di base per il nuovo tracker',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: setupData.nameController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerName') ?? 'Nome Tracker',
                hintText: localizations?.get('newTrackerNameHint') ?? 'es. Seconda Auto',
                prefixIcon: const Icon(Icons.label),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterName') ?? 'Inserisci un nome'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: setupData.trackerPhoneController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerSIMNumber') ?? 'Numero SIM Tracker',
                prefixIcon: const Icon(Icons.sim_card),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterNumber') ?? 'Inserisci numero di telefono'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: setupData.pinController,
              decoration: InputDecoration(
                labelText: localizations?.get('trackerPIN') ?? 'PIN Tracker',
                prefixIcon: const Icon(Icons.lock),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.trim().length < 4)
                  ? localizations?.get('invalidPIN') ?? 'PIN deve essere almeno 4 cifre'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: setupData.adminPhoneController,
              decoration: InputDecoration(
                labelText: localizations?.get('adminPhoneNumber') ?? 'Numero Amministratore',
                hintText: localizations?.get('adminPhoneHint') ?? 'Il tuo numero personale',
                prefixIcon: const Icon(Icons.admin_panel_settings),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? localizations?.get('enterAdminNumber') ?? 'Inserisci il numero amministratore'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class QuickConfigStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SetupData setupData;
  final Function(String) onSendCommand;
  final bool isSending;
  const QuickConfigStep({
    required this.formKey,
    required this.setupData,
    required this.onSendCommand,
    required this.isSending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        onChanged: () => Form.of(primaryFocus!.context!)?.validate(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.get('configuration') ?? 'Configurazione',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(
                localizations?.get('useExistingConfig') ?? 'Usa Configurazione Esistente',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                localizations?.get('reuseSettings') ?? 'Riutilizza impostazioni del primo tracker',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              value: setupData.useExistingConfig,
              onChanged: (value) => setupData.useExistingConfig = value,
              activeColor: colorScheme.primary,
            ),
            if (!setupData.useExistingConfig) ...[
              const SizedBox(height: 24),
              TextFormField(
                controller: setupData.apnController,
                decoration: InputDecoration(
                  labelText: localizations?.get('apn') ?? 'APN',
                  prefixIcon: const Icon(Icons.network_cell),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? localizations?.get('enterAPN') ?? 'Inserisci APN'
                    : null,
              ),
            ] else ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations?.get('existingConfigNote') ??
                              'Userà le impostazioni APN e server esistenti',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuickFinishStep extends StatelessWidget {
  final SetupData setupData;
  final VoidCallback onTest;
  final bool isSending;
  const QuickFinishStep({required this.setupData, required this.onTest, required this.isSending, super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations?.get('confirmation') ?? 'Conferma',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.get('newTrackerLabel') ?? 'Dettagli Nuovo Tracker',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryItem(label: localizations?.get('name') ?? 'Nome', value: setupData.nameController.text),
                  _SummaryItem(label: localizations?.get('trackerPhone') ?? 'SIM Tracker', value: setupData.trackerPhoneController.text),
                  _SummaryItem(label: localizations?.get('adminPhone') ?? 'Admin', value: setupData.adminPhoneController.text),
                  _SummaryItem(
                    label: localizations?.get('configuration') ?? 'Configurazione',
                    value: setupData.useExistingConfig
                        ? localizations?.get('existing') ?? 'Esistente'
                        : localizations?.get('custom') ?? 'Personalizzata',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: isSending ? null : onTest,
            icon: const Icon(Icons.location_searching),
            label: Text(localizations?.get('quickTest') ?? 'Test Veloce'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations?.get('readyToAdd') ?? 'Pronto ad Aggiungere Tracker',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations?.get('readyToAddDescription') ??
                              'Il nuovo tracker verrà aggiunto alla lista dispositivi',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                        ),
                      ],
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
}
