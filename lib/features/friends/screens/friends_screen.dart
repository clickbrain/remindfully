import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/friends_provider.dart';

/// Friends list screen — shows accepted friends, pending requests,
/// and allows searching for new friends.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id ?? '';

    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Sign in to connect with friends.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final friendsState = ref.watch(friendsProviderFamily(userId));
    final notifier = ref.read(friendsProviderFamily(userId).notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Share invite link',
            onPressed: () async {
              final link = await notifier.generateInviteLink();
              if (context.mounted) {
                await Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite link copied to clipboard!'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by username…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) => notifier.searchUsers(q),
            ),
          ),

          Expanded(
            child: friendsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Search results
                      if (friendsState.searchResults.isNotEmpty) ...[
                        Text(
                          'Search Results',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        ...friendsState.searchResults.map(
                          (u) => Card(
                            child: ListTile(
                              title: Text(u.username),
                              trailing: ElevatedButton(
                                onPressed: () =>
                                    notifier.sendFriendRequest(u.id),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(80, 36),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Add'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Pending incoming requests
                      if (friendsState.pendingReceived.isNotEmpty) ...[
                        Text(
                          'Friend Requests',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        ...friendsState.pendingReceived.map(
                          (f) => Card(
                            child: ListTile(
                              title: Text(
                                f.requesterUsername ?? 'Unknown',
                              ),
                              subtitle: const Text('Wants to be friends'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.success,
                                    ),
                                    onPressed: () =>
                                        notifier.acceptRequest(f.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: AppTheme.error,
                                    ),
                                    onPressed: () =>
                                        notifier.declineRequest(f.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Accepted friends
                      Text(
                        'Friends (${friendsState.friends.length})',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (friendsState.friends.isEmpty)
                        Text(
                          'No friends yet — search or share your invite link!',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        )
                      else
                        ...friendsState.friends.map(
                          (f) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.softPurple.withOpacity(0.3),
                                child: Text(
                                  (f.requesterUsername ?? f.receiverUsername ?? '?')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.softPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                userId == f.requesterId
                                    ? (f.receiverUsername ?? 'Unknown')
                                    : (f.requesterUsername ?? 'Unknown'),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
