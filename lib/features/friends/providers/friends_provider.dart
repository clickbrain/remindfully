import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../../shared/models/friendship_model.dart';
import '../../../shared/models/user_model.dart';

class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.pendingReceived = const [],
    this.pendingSent = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
  });

  final List<FriendshipModel> friends;
  final List<FriendshipModel> pendingReceived;
  final List<FriendshipModel> pendingSent;
  final List<UserModel> searchResults;
  final bool isLoading;
  final String? error;

  FriendsState copyWith({
    List<FriendshipModel>? friends,
    List<FriendshipModel>? pendingReceived,
    List<FriendshipModel>? pendingSent,
    List<UserModel>? searchResults,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSearchResults = false,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      pendingReceived: pendingReceived ?? this.pendingReceived,
      pendingSent: pendingSent ?? this.pendingSent,
      searchResults: clearSearchResults
          ? []
          : searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier(this._userId) : super(const FriendsState()) {
    load();
  }

  final String _userId;
  final _pb = PocketBaseService.instance;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _pb.getFriendships(userId: _userId);

      final accepted = <FriendshipModel>[];
      final pendingIn = <FriendshipModel>[];
      final pendingOut = <FriendshipModel>[];

      for (final item in result.items) {
        final f = FriendshipModel.fromRecord(item.data..['id'] = item.id);
        if (f.isAccepted) {
          accepted.add(f);
        } else if (f.isPending) {
          if (f.receiverId == _userId) {
            pendingIn.add(f);
          } else {
            pendingOut.add(f);
          }
        }
      }

      state = state.copyWith(
        friends: accepted,
        pendingReceived: pendingIn,
        pendingSent: pendingOut,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load friends.',
      );
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(clearSearchResults: true);
      return;
    }
    // Sanitize query to prevent filter injection: keep only alphanumeric, underscores, hyphens, dots
    final sanitized = query.replaceAll(RegExp(r'[^\w.\-]'), '');
    if (sanitized.isEmpty) {
      state = state.copyWith(clearSearchResults: true);
      return;
    }
    try {
      final result = await _pb.client.collection('users').getList(
            filter: 'username ~ "$sanitized"',
            perPage: 10,
          );
      final users = result.items
          .map((r) => UserModel.fromRecord(r.data..['id'] = r.id))
          .toList();
      state = state.copyWith(searchResults: users);
    } catch (_) {
      state = state.copyWith(clearSearchResults: true);
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    try {
      await _pb.sendFriendRequest(
        requesterId: _userId,
        receiverId: receiverId,
      );
      await load();
    } catch (e) {
      state = state.copyWith(error: 'Failed to send friend request.');
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await _pb.updateFriendshipStatus(
        friendshipId,
        AppConstants.statusAccepted,
      );
      await load();
    } catch (_) {
      state = state.copyWith(error: 'Failed to accept request.');
    }
  }

  Future<void> declineRequest(String friendshipId) async {
    try {
      await _pb.updateFriendshipStatus(
        friendshipId,
        AppConstants.statusDeclined,
      );
      await load();
    } catch (_) {
      state = state.copyWith(error: 'Failed to decline request.');
    }
  }

  Future<String> generateInviteLink() async {
    final code = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    final expires = DateTime.now().add(const Duration(days: 7));
    await _pb.createInviteLink(
      userId: _userId,
      code: code,
      expiresAt: expires,
    );
    return '${AppConstants.pocketbaseUrl}/invite/$code';
  }
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  // This provider should only be used when the user is authenticated.
  // The userId is provided at construction via the provider family pattern
  // used in the widget layer.
  return FriendsNotifier('');
});

final friendsProviderFamily =
    StateNotifierProvider.family<FriendsNotifier, FriendsState, String>(
  (ref, userId) => FriendsNotifier(userId),
);
