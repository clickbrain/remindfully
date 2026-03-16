import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';

/// Leaderboard screen showing global rankings.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  static const _periods = [
    (AppConstants.periodAllTime, 'All Time'),
    (AppConstants.periodWeekly, 'This Week'),
    (AppConstants.periodDaily, 'Today'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Prompt guest to sign up
    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Leaderboard')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.leaderboard_outlined,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to access the leaderboard',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(authProvider.notifier).signOut(),
                  child: const Text('Sign In / Create Account'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(leaderboardProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _periods.map((p) {
                final isSelected = leaderboard.period == p.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(leaderboardProvider.notifier)
                          .setPeriod(p.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.softPurple
                              : AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: leaderboard.isLoading
                ? const Center(child: CircularProgressIndicator())
                : leaderboard.error != null
                    ? Center(
                        child: Text(
                          leaderboard.error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : leaderboard.entries.isEmpty
                        ? Center(
                            child: Text(
                              'No entries yet. Complete a session to be first!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: leaderboard.entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final entry = leaderboard.entries[index];
                              final isCurrentUser =
                                  entry.userId == auth.user?.id;
                              return Container(
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AppTheme.softPurple.withOpacity(0.2)
                                      : AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isCurrentUser
                                      ? Border.all(
                                          color: AppTheme.softPurple,
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  leading: _RankBadge(rank: entry.rank),
                                  title: Text(entry.username),
                                  subtitle: Text(
                                    '${entry.sessionsCompleted} sessions',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    '${entry.totalPoints} pts',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.gentleGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;
    if (rank == 1) {
      color = const Color(0xFFFFD700);
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0);
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
      icon = Icons.emoji_events;
    } else {
      color = AppTheme.textSecondary;
      icon = null;
    }

    if (icon != null) {
      return Icon(icon, color: color, size: 32);
    }
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          '#$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
