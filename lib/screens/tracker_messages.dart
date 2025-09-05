import 'package:trackmate/data/tracker.dart';
import 'package:trackmate/data/tracker_message.dart';
import 'package:trackmate/database/database.dart';
import 'package:trackmate/database/tracker_db.dart';
import 'package:trackmate/database/tracker_message_db.dart';
import 'package:trackmate/locale/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TrackerMessageListScreen extends StatefulWidget {
  final Tracker tracker;

  const TrackerMessageListScreen(this.tracker, {super.key});

  @override
  State<TrackerMessageListScreen> createState() => TrackerMessageListScreenState();
}

class TrackerMessageListScreenState extends State<TrackerMessageListScreen> {
  List<TrackerMessage>? _messages;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    TrackerDB.changeNotifier.addListener(_onTrackerDataChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    TrackerDB.changeNotifier.removeListener(_onTrackerDataChanged);
    super.dispose();
  }

  void _onTrackerDataChanged() {
    if (mounted) {
      _loadMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final db = await DataBase.get();
      final messages = await TrackerMessageDB.list(db!, widget.tracker.uuid);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refreshMessages() async {
    HapticFeedback.lightImpact();
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations?.get('messages') ?? 'Messages'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshMessages,
            tooltip: localizations?.get('refresh') ?? 'Refresh',
          ),
        ],
      ),
      body: Consumer<TrackerNotifier>(
        builder: (context, trackerNotifier, child) {
          if (_isLoading) {
            return _buildLoadingState(localizations, theme, colorScheme);
          }

          if (_error != null) {
            return _buildErrorState(localizations, theme, colorScheme);
          }

          if (_messages == null || _messages!.isEmpty) {
            return _buildEmptyState(localizations, theme, colorScheme);
          }

          return _buildMessagesList(localizations, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.get('loadingMessages') ?? 'Loading messages...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('errorLoadingMessages') ?? 'Error Loading Messages',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error ?? 'Unknown error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: _refreshMessages,
              child: Text(localizations?.get('retry') ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.sms,
                size: 80,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations?.get('noMessages') ?? 'No messages available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('messagesAppearHere') ?? 'Messages from your tracker will appear here',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _refreshMessages,
              icon: const Icon(Icons.refresh),
              label: Text(localizations?.get('refresh') ?? 'Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    final sentCount = _messages!.where((m) => m.direction == MessageDirection.SENT).length;
    final receivedCount = _messages!.where((m) => m.direction == MessageDirection.RECEIVED).length;

    return Column(
      children: [
        // Header con statistiche
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.secondaryContainer.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sms,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_messages!.length} ${localizations?.get('messages') ?? 'Messages'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${localizations?.get('sent') ?? 'Sent'}: $sentCount • ${localizations?.get('received') ?? 'Received'}: $receivedCount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista messaggi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshMessages,
            color: colorScheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              itemCount: _messages!.length,
              itemBuilder: (context, index) {
                final message = _messages![index];
                return _buildMessageItem(message, index, localizations, theme, colorScheme);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(TrackerMessage message, int index, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    final isSent = message.direction == MessageDirection.SENT;
    final isRecent = _isRecentMessage(message.timestamp);
    final messageIcon = _getMessageTypeIcon(message.data);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSent
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.secondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSent
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSent
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              isSent ? Icons.call_made : Icons.call_received,
              color: isSent ? colorScheme.primary : colorScheme.secondary,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateTime(message.timestamp),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSent
                      ? colorScheme.primary.withOpacity(0.2)
                      : colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSent
                      ? localizations?.get('sent') ?? 'SENT'
                      : localizations?.get('received') ?? 'RECEIVED',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSent ? colorScheme.primary : colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.data,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatFullDateTime(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                messageIcon,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              if (isRecent) ...[
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showMessageDetails(message, localizations, theme, colorScheme),
        ),
      ),
    );
  }

  void _showMessageDetails(TrackerMessage message, AppLocalizations? localizations, ThemeData theme, ColorScheme colorScheme) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            message.direction == MessageDirection.SENT ? Icons.call_made : Icons.call_received,
            color: message.direction == MessageDirection.SENT ? colorScheme.primary : colorScheme.secondary,
            size: 32,
          ),
          title: Text(
            message.direction == MessageDirection.SENT
                ? localizations?.get('sentMessage') ?? 'Sent Message'
                : localizations?.get('receivedMessage') ?? 'Received Message',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                child: ListTile(
                  leading: Icon(Icons.access_time, color: colorScheme.primary),
                  title: Text(
                    localizations?.get('timestamp') ?? 'Timestamp',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(_formatFullDateTime(message.timestamp)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localizations?.get('messageContent') ?? 'Message Content:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: colorScheme.surfaceVariant,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    message.data,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message.data));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations?.get('copiedToClipboard') ?? 'Copied to clipboard'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(localizations?.get('copy') ?? 'Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.get('close') ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm:ss').format(dateTime);
  }

  bool _isRecentMessage(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 5;
  }

  IconData _getMessageTypeIcon(String messageContent) {
    final content = messageContent.toLowerCase();
    if (content.contains('http') || content.contains('maps.google')) {
      return Icons.location_on;
    } else if (content.contains('bat:') || content.contains('battery')) {
      return Icons.battery_std;
    } else if (content.contains('build:') || content.contains('status')) {
      return Icons.info;
    } else if (content.contains('ok') || content.contains('success')) {
      return Icons.check_circle;
    } else if (content.contains('error') || content.contains('invalid')) {
      return Icons.error;
    } else {
      return Icons.message;
    }
  }
}
