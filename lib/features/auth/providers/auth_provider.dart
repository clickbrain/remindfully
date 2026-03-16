import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../../shared/models/user_model.dart';

/// Auth state — wraps the currently logged-in user (or null).
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null && !user!.isGuest;
  bool get isGuest => user?.isGuest ?? false;
  bool get isSignedIn => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Notifier that manages authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  final _pb = PocketBaseService.instance;

  /// Attempt to restore an existing auth session.
  Future<void> _restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(AppConstants.prefIsGuest) ?? false;

      if (isGuest) {
        final guestPoints = prefs.getInt(AppConstants.prefGuestPoints) ?? 0;
        final guestSessions =
            prefs.getInt(AppConstants.prefGuestSessions) ?? 0;
        state = state.copyWith(
          isLoading: false,
          user: UserModel.guest().copyWith(
            totalPoints: guestPoints,
            sessionsCompleted: guestSessions,
          ),
        );
        return;
      }

      if (_pb.isAuthenticated) {
        final currentUser = _pb.currentUser;
        if (currentUser != null) {
          state = state.copyWith(
            isLoading: false,
            user: UserModel.fromRecord(currentUser.data
              ..['id'] = currentUser.id),
          );
          return;
        }
      }
    } catch (_) {
      // Ignore errors during restore; user will need to sign in again
    }
    state = state.copyWith(isLoading: false, clearUser: true);
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final auth = await _pb.signInWithEmail(email, password);
      final record = auth.record;
      if (record == null) throw Exception('Authentication failed');
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromRecord(record.data..['id'] = record.id),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  /// Register a new account.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final record = await _pb.registerWithEmail(
        email: email,
        password: password,
        username: username,
      );
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromRecord(record.data..['id'] = record.id),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  /// Sign in via OAuth2 (Google or Apple).
  Future<void> signInWithOAuth2(String provider) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final auth = await _pb.signInWithOAuth2(provider);
      final record = auth.record;
      if (record == null) throw Exception('Authentication failed');
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromRecord(record.data..['id'] = record.id),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(e),
      );
    }
  }

  /// Continue as guest — data persists locally only.
  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefIsGuest, true);
    state = state.copyWith(
      isLoading: false,
      user: UserModel.guest(),
      clearError: true,
    );
  }

  /// Update guest points and sessions after a session completes.
  Future<void> updateGuestStats({
    required int points,
    required int sessions,
  }) async {
    if (!state.isGuest) return;
    final prefs = await SharedPreferences.getInstance();
    final newPoints = (state.user?.totalPoints ?? 0) + points;
    final newSessions = (state.user?.sessionsCompleted ?? 0) + sessions;
    await prefs.setInt(AppConstants.prefGuestPoints, newPoints);
    await prefs.setInt(AppConstants.prefGuestSessions, newSessions);
    state = state.copyWith(
      user: state.user?.copyWith(
        totalPoints: newPoints,
        sessionsCompleted: newSessions,
      ),
    );
  }

  /// Sign out and clear all local state.
  Future<void> signOut() async {
    _pb.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefIsGuest);
    await prefs.remove(AppConstants.prefGuestPoints);
    await prefs.remove(AppConstants.prefGuestSessions);
    state = const AuthState();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('400') || msg.contains('invalid')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('Failed host lookup') ||
        msg.contains('SocketException')) {
      return 'Cannot reach the server. Check your connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Convenience provider — currently signed-in user (or null).
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
