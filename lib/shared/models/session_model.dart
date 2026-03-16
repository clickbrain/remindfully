/// Represents a completed focus session.
class SessionModel {
  const SessionModel({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.totalPoints,
    required this.successfulTaps,
    required this.missedTaps,
    required this.avgReactionTime,
    required this.completedAt,
  });

  factory SessionModel.fromRecord(Map<String, dynamic> data) {
    return SessionModel(
      id: data['id'] as String? ?? '',
      userId: data['user'] as String? ?? '',
      durationMinutes: (data['duration_minutes'] as num?)?.toInt() ?? 0,
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      successfulTaps: (data['successful_taps'] as num?)?.toInt() ?? 0,
      missedTaps: (data['missed_taps'] as num?)?.toInt() ?? 0,
      avgReactionTime: (data['avg_reaction_time'] as num?)?.toDouble() ?? 0.0,
      completedAt: DateTime.tryParse(
            data['completed_at'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final int durationMinutes;
  final int totalPoints;
  final int successfulTaps;
  final int missedTaps;
  final double avgReactionTime;
  final DateTime completedAt;
}
