import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/session_model.dart';
import '../audio_engine/audio_engine.dart';

/// Represents the phase of the session.
enum SessionPhase {
  setup,      // User is choosing duration
  running,    // Session is active
  tapPrompt,  // Silence gap — user must tap
  missed,     // User missed the tap
  summary,    // Session ended — show results
}

/// The full state of a running (or completed) session.
class SessionState {
  const SessionState({
    this.phase = SessionPhase.setup,
    this.durationMinutes = 10,
    this.elapsedSeconds = 0,
    this.totalPoints = 0,
    this.successfulTaps = 0,
    this.missedTaps = 0,
    this.totalReactionTime = 0,
    this.lastReactionTimeMs,
    this.error,
    this.completedSession,
  });

  final SessionPhase phase;
  final int durationMinutes;
  final int elapsedSeconds;
  final int totalPoints;
  final int successfulTaps;
  final int missedTaps;
  final int totalReactionTime;
  final int? lastReactionTimeMs;
  final String? error;
  final SessionModel? completedSession;

  double get avgReactionTime {
    if (successfulTaps == 0) return 0;
    return totalReactionTime / successfulTaps;
  }

  int get totalTaps => successfulTaps + missedTaps;
  int get durationSeconds => durationMinutes * 60;
  double get progressPercent => elapsedSeconds / durationSeconds;

  SessionState copyWith({
    SessionPhase? phase,
    int? durationMinutes,
    int? elapsedSeconds,
    int? totalPoints,
    int? successfulTaps,
    int? missedTaps,
    int? totalReactionTime,
    int? lastReactionTimeMs,
    String? error,
    SessionModel? completedSession,
    bool clearError = false,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalPoints: totalPoints ?? this.totalPoints,
      successfulTaps: successfulTaps ?? this.successfulTaps,
      missedTaps: missedTaps ?? this.missedTaps,
      totalReactionTime: totalReactionTime ?? this.totalReactionTime,
      lastReactionTimeMs: lastReactionTimeMs ?? this.lastReactionTimeMs,
      error: clearError ? null : error ?? this.error,
      completedSession: completedSession ?? this.completedSession,
    );
  }
}

/// Manages the lifecycle of a focus session.
class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._ref) : super(const SessionState());

  final Ref _ref;
  final _audioEngine = AudioEngine();
  Timer? _sessionTimer;

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  // ---------------------------------------------------------------------------
  // Session lifecycle
  // ---------------------------------------------------------------------------

  Future<void> startSession() async {
    state = state.copyWith(
      phase: SessionPhase.running,
      elapsedSeconds: 0,
      totalPoints: 0,
      successfulTaps: 0,
      missedTaps: 0,
      totalReactionTime: 0,
      clearError: true,
    );

    _audioEngine.onChallengeStarted = _onChallengeStarted;
    _audioEngine.onSuccessfulTap = _onSuccessfulTap;
    _audioEngine.onMissedTap = _onMissedTap;

    await _audioEngine.start();

    // Tick every second
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newElapsed = state.elapsedSeconds + 1;
      if (newElapsed >= state.durationSeconds) {
        _endSession();
      } else {
        state = state.copyWith(elapsedSeconds: newElapsed);
      }
    });

    HapticFeedback.mediumImpact();
  }

  /// User tapped the screen.
  void handleTap() {
    final reactionMs = _audioEngine.handleTap();
    if (reactionMs != null) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> endSessionEarly() async {
    await _endSession();
  }

  void resetSession() {
    state = const SessionState();
  }

  // ---------------------------------------------------------------------------
  // Audio engine callbacks
  // ---------------------------------------------------------------------------

  void _onChallengeStarted() {
    if (!mounted) return;
    state = state.copyWith(phase: SessionPhase.tapPrompt);
    HapticFeedback.heavyImpact();
  }

  void _onSuccessfulTap(int reactionMs) {
    if (!mounted) return;
    final points = _calculatePoints(reactionMs);
    state = state.copyWith(
      phase: SessionPhase.running,
      successfulTaps: state.successfulTaps + 1,
      totalPoints: state.totalPoints + points,
      totalReactionTime: state.totalReactionTime + reactionMs,
      lastReactionTimeMs: reactionMs,
    );
  }

  void _onMissedTap() {
    if (!mounted) return;
    final penalty = AppConstants.penaltyPointsPerMiss;
    state = state.copyWith(
      phase: SessionPhase.missed,
      missedTaps: state.missedTaps + 1,
      totalPoints: (state.totalPoints - penalty).clamp(0, double.maxFinite.toInt()),
    );
    HapticFeedback.heavyImpact();

    // Brief "missed" display, then back to running
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && state.phase == SessionPhase.missed) {
        state = state.copyWith(phase: SessionPhase.running);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // End session
  // ---------------------------------------------------------------------------

  Future<void> _endSession() async {
    _sessionTimer?.cancel();
    await _audioEngine.stop();
    HapticFeedback.mediumImpact();

    final auth = _ref.read(authProvider);
    final session = SessionModel(
      id: '',
      userId: auth.user?.id ?? 'guest',
      durationMinutes: state.durationMinutes,
      totalPoints: state.totalPoints,
      successfulTaps: state.successfulTaps,
      missedTaps: state.missedTaps,
      avgReactionTime: state.avgReactionTime,
      completedAt: DateTime.now(),
    );

    // Save session to PocketBase if authenticated, else update guest stats
    if (auth.isAuthenticated && auth.user != null) {
      try {
        final pb = PocketBaseService.instance;
        await pb.createSession({
          'user': auth.user!.id,
          'duration_minutes': session.durationMinutes,
          'total_points': session.totalPoints,
          'successful_taps': session.successfulTaps,
          'missed_taps': session.missedTaps,
          'avg_reaction_time': session.avgReactionTime,
          'completed_at': session.completedAt.toIso8601String(),
        });

        // Update leaderboard entries
        final newTotalPoints =
            (auth.user!.totalPoints) + session.totalPoints;
        final newSessions = auth.user!.sessionsCompleted + 1;
        for (final period in [
          AppConstants.periodAllTime,
          AppConstants.periodWeekly,
          AppConstants.periodDaily,
        ]) {
          await pb.upsertLeaderboardEntry(
            userId: auth.user!.id,
            period: period,
            totalPoints: newTotalPoints,
            sessionsCompleted: newSessions,
          );
        }

        // Update user stats
        await pb.updateUser(auth.user!.id, {
          'total_points': newTotalPoints,
          'sessions_completed': newSessions,
          'average_reaction_time':
              ((auth.user!.averageReactionTime * auth.user!.sessionsCompleted) +
                      session.avgReactionTime) /
                  newSessions,
        });
      } catch (_) {
        // Non-fatal — session summary is still shown
      }
    } else if (auth.isGuest) {
      await _ref.read(authProvider.notifier).updateGuestStats(
            points: session.totalPoints,
            sessions: 1,
          );
    }

    state = state.copyWith(
      phase: SessionPhase.summary,
      completedSession: session,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _calculatePoints(int reactionMs) {
    // Sliding scale: faster = more points
    // Max points at 200ms, min (base) at tapWindowSeconds
    const maxReactionMs = 200;
    final windowMs = AppConstants.tapWindowSeconds * 1000;
    final clamped = reactionMs.clamp(maxReactionMs, windowMs.toInt());
    final factor = 1.0 -
        (clamped - maxReactionMs) / (windowMs - maxReactionMs);
    return (AppConstants.basePointsPerTap * (0.2 + 0.8 * factor)).toInt();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _audioEngine.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final sessionProvider =
    StateNotifierProvider.autoDispose<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref),
);
