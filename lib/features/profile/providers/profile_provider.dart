import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/pocketbase_service.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isSaving,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._ref) : super(const ProfileState()) {
    _load();
  }

  final Ref _ref;
  final _pb = PocketBaseService.instance;

  Future<void> _load() async {
    final auth = _ref.read(authProvider);
    if (auth.user == null) return;
    if (auth.isGuest) {
      state = state.copyWith(user: auth.user);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final record = await _pb.getUser(auth.user!.id);
      state = state.copyWith(
        isLoading: false,
        user: UserModel.fromRecord(record.data..['id'] = record.id),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        user: auth.user,
        error: 'Failed to load profile.',
      );
    }
  }

  Future<void> updateUsername(String username) async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated || auth.user == null) return;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final record = await _pb.updateUser(auth.user!.id, {
        'username': username,
      });
      state = state.copyWith(
        isSaving: false,
        user: UserModel.fromRecord(record.data..['id'] = record.id),
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update username.',
      );
    }
  }
}

final profileProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref),
);
