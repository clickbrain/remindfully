import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

/// User profile screen.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);
    final theme = Theme.of(context);

    final user = profile.user ?? auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditUsernameDialog(context, ref, user?.username ?? ''),
            ),
        ],
      ),
      body: SafeArea(
        child: profile.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.softPurple.withOpacity(0.3),
                        child: Text(
                          (user?.username ?? 'G')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppTheme.softPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      user?.username ?? 'Guest',
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (!auth.isGuest)
                      Text(
                        auth.user?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    if (auth.isGuest)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.warning),
                        ),
                        child: const Text(
                          'You are in guest mode. Sign up to save progress and compete!',
                          style: TextStyle(color: AppTheme.warning),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Stats
                    Row(
                      children: [
                        _StatCard(
                          label: 'Total Points',
                          value: '${user?.totalPoints ?? 0}',
                          icon: Icons.star,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          label: 'Sessions',
                          value: '${user?.sessionsCompleted ?? 0}',
                          icon: Icons.timer,
                          color: AppTheme.gentleGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      label: 'Avg Reaction Time',
                      value:
                          '${(user?.averageReactionTime ?? 0).toStringAsFixed(0)} ms',
                      icon: Icons.speed,
                      color: AppTheme.softPurple,
                    ),

                    const SizedBox(height: 32),

                    // Sign out
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showEditUsernameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUsername,
  ) {
    final controller = TextEditingController(text: currentUsername);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(profileProvider.notifier)
                  .updateUsername(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
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
          ),
        ),
      ),
    );
  }
}
