import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import 'session_summary_screen.dart';

/// The immersive screen shown during an active focus session.
class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    // Navigate to summary when session ends
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.phase != SessionPhase.summary &&
          next.phase == SessionPhase.summary) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const SessionSummaryScreen(),
          ),
        );
      }
    });

    final isTapPrompt = session.phase == SessionPhase.tapPrompt;
    final isMissed = session.phase == SessionPhase.missed;

    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('End Session?'),
            content: const Text(
              'Your progress will still be saved if you end early.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep Going'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'End Session',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(sessionProvider.notifier).endSessionEarly();
        }
        return false; // Prevent default pop; navigation happens via listener
      },
      child: Scaffold(
        backgroundColor: isTapPrompt
            ? AppTheme.accentGlow.withOpacity(0.15)
            : isMissed
                ? AppTheme.error.withOpacity(0.15)
                : AppTheme.deepNavy,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => ref.read(sessionProvider.notifier).handleTap(),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // Top bar — progress
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(session.elapsedSeconds),
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            _formatTime(session.durationSeconds -
                                session.elapsedSeconds),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: session.progressPercent,
                          minHeight: 6,
                          backgroundColor: AppTheme.navy,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.softPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main tap area
                Expanded(
                  child: Center(
                    child: isTapPrompt
                        ? _TapPromptWidget()
                        : isMissed
                            ? _MissedWidget()
                            : _FocusIndicator(),
                  ),
                ),

                // Bottom stats
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatChip(
                        label: 'Points',
                        value: '${session.totalPoints}',
                        color: AppTheme.gentleGreen,
                      ),
                      _StatChip(
                        label: 'Taps',
                        value: '${session.successfulTaps}',
                        color: AppTheme.softPurple,
                      ),
                      _StatChip(
                        label: 'Missed',
                        value: '${session.missedTaps}',
                        color: AppTheme.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TapPromptWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.touch_app,
          size: 80,
          color: AppTheme.accentGlow,
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.2, 1.2),
              duration: 600.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.2, 1.2),
              end: const Offset(1, 1),
              duration: 600.ms,
            ),
        const SizedBox(height: 16),
        Text(
          'TAP NOW!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.accentGlow,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _MissedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.close_rounded, size: 80, color: AppTheme.error),
        const SizedBox(height: 16),
        Text(
          'Missed!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.error,
              ),
        ),
      ],
    );
  }
}

class _FocusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.softPurple.withOpacity(0.15),
            border: Border.all(
              color: AppTheme.softPurple.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.self_improvement,
            size: 56,
            color: AppTheme.lavender,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Stay focused...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
