import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Singleton service that manages the PocketBase client and auth persistence.
class PocketBaseService {
  PocketBaseService._();

  static PocketBaseService? _instance;

  // ignore: prefer_constructors_over_static_methods
  static PocketBaseService get instance {
    _instance ??= PocketBaseService._();
    return _instance!;
  }

  late final PocketBase _client;
  final _log = Logger();

  PocketBase get client => _client;

  /// Initialise the PocketBase client and restore any saved auth session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final store = AsyncAuthStore(
      save: (String data) async {
        await prefs.setString(AppConstants.prefAuthToken, data);
      },
      initial: prefs.getString(AppConstants.prefAuthToken),
    );

    _client = PocketBase(
      // TODO: Replace with your PocketBase URL if self-hosting on a different server
      AppConstants.pocketbaseUrl,
      authStore: store,
    );

    _log.d('PocketBase client initialised → ${AppConstants.pocketbaseUrl}');
  }

  /// Returns true when a user is authenticated (non-guest).
  bool get isAuthenticated => _client.authStore.isValid;

  /// Returns the currently logged-in user record, or null.
  RecordModel? get currentUser {
    final model = _client.authStore.model;
    if (model is RecordModel) return model;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Auth helpers
  // ---------------------------------------------------------------------------

  /// Sign in with email and password.
  Future<RecordAuth> signInWithEmail(String email, String password) async {
    return _client.collection('users').authWithPassword(email, password);
  }

  /// Register a new account with email and password.
  Future<RecordModel> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final record = await _client.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'username': username,
      'total_points': 0,
      'sessions_completed': 0,
      'average_reaction_time': 0,
    });
    // Auto sign in after registration
    await _client.collection('users').authWithPassword(email, password);
    return record;
  }

  /// Sign in via OAuth2 (Google or Apple).
  Future<RecordAuth> signInWithOAuth2(String provider) async {
    return _client.collection('users').authWithOAuth2(
          provider,
          (url) async {
            // This callback is invoked with the OAuth2 redirect URL.
            // In a real app, open this URL in an in-app browser or the system
            // browser and capture the redirect.
            if (kDebugMode) {
              debugPrint('OAuth2 URL: $url');
            }
          },
        );
  }

  /// Sign out and clear the auth store.
  void signOut() {
    _client.authStore.clear();
  }

  // ---------------------------------------------------------------------------
  // User helpers
  // ---------------------------------------------------------------------------

  /// Fetch a user record by ID.
  Future<RecordModel> getUser(String id) async {
    return _client.collection('users').getOne(id);
  }

  /// Update the current user's profile fields.
  Future<RecordModel> updateUser(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _client.collection('users').update(id, body: data);
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  Future<RecordModel> createSession(Map<String, dynamic> data) async {
    return _client.collection('sessions').create(body: data);
  }

  Future<ResultList<RecordModel>> getSessions({
    String? userId,
    int page = 1,
    int perPage = 20,
  }) async {
    String filter = '';
    if (userId != null) filter = 'user = "$userId"';
    return _client.collection('sessions').getList(
          page: page,
          perPage: perPage,
          filter: filter,
          sort: '-completed_at',
        );
  }

  // ---------------------------------------------------------------------------
  // Leaderboard
  // ---------------------------------------------------------------------------

  Future<ResultList<RecordModel>> getLeaderboard({
    String period = AppConstants.periodAllTime,
    int page = 1,
    int perPage = 50,
  }) async {
    return _client.collection('leaderboard_entries').getList(
          page: page,
          perPage: perPage,
          filter: 'period = "$period"',
          sort: '-total_points',
          expand: 'user',
        );
  }

  Future<RecordModel> upsertLeaderboardEntry({
    required String userId,
    required String period,
    required int totalPoints,
    required int sessionsCompleted,
  }) async {
    // Try to find an existing entry first
    try {
      final existing = await _client.collection('leaderboard_entries').getFirstListItem(
            'user = "$userId" && period = "$period"',
          );
      return _client.collection('leaderboard_entries').update(
        existing.id,
        body: {
          'total_points': totalPoints,
          'sessions_completed': sessionsCompleted,
        },
      );
    } catch (_) {
      return _client.collection('leaderboard_entries').create(body: {
        'user': userId,
        'period': period,
        'total_points': totalPoints,
        'sessions_completed': sessionsCompleted,
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Friends
  // ---------------------------------------------------------------------------

  Future<ResultList<RecordModel>> getFriendships({
    String? userId,
    String? status,
  }) async {
    String filter = '';
    if (userId != null) {
      filter = '(requester = "$userId" || receiver = "$userId")';
    }
    if (status != null) {
      final statusFilter = 'status = "$status"';
      filter = filter.isEmpty ? statusFilter : '$filter && $statusFilter';
    }
    return _client.collection('friendships').getList(
          filter: filter,
          expand: 'requester,receiver',
        );
  }

  Future<RecordModel> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    return _client.collection('friendships').create(body: {
      'requester': requesterId,
      'receiver': receiverId,
      'status': AppConstants.statusPending,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<RecordModel> updateFriendshipStatus(
    String friendshipId,
    String status,
  ) async {
    return _client
        .collection('friendships')
        .update(friendshipId, body: {'status': status});
  }

  // ---------------------------------------------------------------------------
  // Invite links
  // ---------------------------------------------------------------------------

  Future<RecordModel> createInviteLink({
    required String userId,
    required String code,
    required DateTime expiresAt,
  }) async {
    return _client.collection('invite_links').create(body: {
      'user': userId,
      'code': code,
      'expires_at': expiresAt.toIso8601String(),
      'uses': 0,
    });
  }

  Future<RecordModel?> resolveInviteLink(String code) async {
    try {
      return await _client
          .collection('invite_links')
          .getFirstListItem('code = "$code"', expand: 'user');
    } catch (_) {
      return null;
    }
  }
}
