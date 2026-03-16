import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../../shared/models/leaderboard_entry.dart';

class LeaderboardState {
  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.period = AppConstants.periodAllTime,
  });

  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;
  final String period;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
    String? period,
    bool clearError = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      period: period ?? this.period,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  LeaderboardNotifier() : super(const LeaderboardState()) {
    load();
  }

  final _pb = PocketBaseService.instance;

  Future<void> load({String? period}) async {
    final p = period ?? state.period;
    state = state.copyWith(isLoading: true, period: p, clearError: true);
    try {
      final result = await _pb.getLeaderboard(period: p);
      final entries = result.items.asMap().entries.map((e) {
        final entry =
            LeaderboardEntry.fromRecord(e.value.data..['id'] = e.value.id);
        return entry.copyWith(rank: e.key + 1);
      }).toList();
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load leaderboard. Check your connection.',
      );
    }
  }

  void setPeriod(String period) {
    load(period: period);
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>(
  (ref) => LeaderboardNotifier(),
);
