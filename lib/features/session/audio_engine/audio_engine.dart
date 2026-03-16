import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_constants.dart';

/// The state of an ongoing tap challenge.
enum ChallengeState {
  idle,
  active,
  missed,
}

/// Audio engine that:
/// 1. Plays looping focus music
/// 2. Randomly injects silence gaps
/// 3. Fires callbacks for the tap mechanic
class AudioEngine {
  AudioEngine();

  final _player = AudioPlayer();
  final _random = Random();
  final _log = Logger();

  Timer? _silenceTimer;
  Timer? _tapWindowTimer;
  Timer? _resumeTimer;

  ChallengeState _challengeState = ChallengeState.idle;
  DateTime? _challengeStartedAt;

  // Callbacks
  void Function()? onChallengeStarted;
  void Function(int reactionTimeMs)? onSuccessfulTap;
  void Function()? onMissedTap;

  bool _isRunning = false;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  bool get isRunning => _isRunning;
  ChallengeState get challengeState => _challengeState;

  /// Start the audio engine with the given asset path.
  /// Pass null to use a placeholder silence track (no actual audio file yet).
  Future<void> start({String? audioAssetPath}) async {
    _isRunning = true;
    try {
      if (audioAssetPath != null) {
        await _player.setAsset(audioAssetPath);
        await _player.setLoopMode(LoopMode.one);
        await _player.play();
      }
    } catch (e) {
      // No audio file available — that's OK for now, the tap mechanic still works
      _log.w('Audio file not loaded: $e');
    }
    _scheduleNextSilence();
  }

  /// Stop the engine and release resources.
  Future<void> stop() async {
    _isRunning = false;
    _cancelTimers();
    _challengeState = ChallengeState.idle;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Call this when the user taps during a challenge.
  /// Returns the reaction time in ms, or null if no challenge is active.
  int? handleTap() {
    if (_challengeState != ChallengeState.active) return null;
    final start = _challengeStartedAt;
    if (start == null) return null;

    _tapWindowTimer?.cancel();
    _challengeState = ChallengeState.idle;
    final reactionMs =
        DateTime.now().difference(start).inMilliseconds;
    onSuccessfulTap?.call(reactionMs);
    _resumeAudio();
    _scheduleNextSilence();
    return reactionMs;
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _scheduleNextSilence() {
    if (!_isRunning) return;
    final delaySeconds = _randomBetween(
      AppConstants.minGapInterval,
      AppConstants.maxGapInterval,
    );
    _silenceTimer = Timer(
      Duration(milliseconds: (delaySeconds * 1000).toInt()),
      _startSilence,
    );
  }

  void _startSilence() {
    if (!_isRunning) return;
    _muteAudio();
    _challengeState = ChallengeState.active;
    _challengeStartedAt = DateTime.now();
    onChallengeStarted?.call();

    // Start the tap window timer
    _tapWindowTimer = Timer(
      Duration(
        milliseconds:
            (AppConstants.tapWindowSeconds * 1000).toInt(),
      ),
      _handleMissedTap,
    );
  }

  void _handleMissedTap() {
    if (_challengeState != ChallengeState.active) return;
    _challengeState = ChallengeState.missed;
    onMissedTap?.call();
    _resumeAudio();
    _scheduleNextSilence();
  }

  void _muteAudio() {
    try {
      _player.setVolume(0);
    } catch (_) {}
  }

  void _resumeAudio() {
    try {
      _player.setVolume(1.0);
    } catch (_) {}
  }

  void _cancelTimers() {
    _silenceTimer?.cancel();
    _tapWindowTimer?.cancel();
    _resumeTimer?.cancel();
  }

  double _randomBetween(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }
}
