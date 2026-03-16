import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../../../shared/models/session_model.dart';

/// Summary screen shown at the end of a session.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final completed = session.completedSession;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trophy icon
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 16),

              Text(
                'Great session!',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _SummaryRow(
                        icon: Icons.star,
                        label: 'Points Earned',
                        value: '${completed?.totalPoints ?? session.totalPoints}',
                        color: AppTheme.warning,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.check_circle,
                        label: 'Successful Taps',
                        value:
                            '${completed?.successfulTaps ?? session.successfulTaps}',
                        color: AppTheme.success,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.cancel,
                        label: 'Missed Taps',
                        value:
                            '${completed?.missedTaps ?? session.missedTaps}',
                        color: AppTheme.error,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.speed,
                        label: 'Avg Reaction Time',
                        value: completed != null
                            ? '${completed.avgReactionTime.toStringAsFixed(0)} ms'
                            : '${session.avgReactionTime.toStringAsFixed(0)} ms',
                        color: AppTheme.softPurple,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        icon: Icons.timer,
                        label: 'Duration',
                        value:
                            '${completed?.durationMinutes ?? session.durationMinutes} min',
                        color: AppTheme.gentleGreen,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).resetSession();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  ref.read(sessionProvider.notifier).resetSession();
                  await ref.read(sessionProvider.notifier).startSession();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/session');
                  }
                },
                child: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
