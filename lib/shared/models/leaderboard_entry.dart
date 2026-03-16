/// Represents a leaderboard entry.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.totalPoints,
    required this.sessionsCompleted,
    required this.period,
    this.avatarUrl,
    this.rank = 0,
  });

  factory LeaderboardEntry.fromRecord(Map<String, dynamic> data) {
    final expandedUser =
        (data['expand'] as Map<String, dynamic>?)?['user'] as Map<String, dynamic>?;

    return LeaderboardEntry(
      id: data['id'] as String? ?? '',
      userId: data['user'] as String? ?? '',
      username: expandedUser?['username'] as String? ?? 'Unknown',
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (data['sessions_completed'] as num?)?.toInt() ?? 0,
      period: data['period'] as String? ?? 'all_time',
      avatarUrl: expandedUser?['avatar_url'] as String?,
    );
  }

  final String id;
  final String userId;
  final String username;
  final int totalPoints;
  final int sessionsCompleted;
  final String period;
  final String? avatarUrl;
  final int rank;

  LeaderboardEntry copyWith({int? rank}) {
    return LeaderboardEntry(
      id: id,
      userId: userId,
      username: username,
      totalPoints: totalPoints,
      sessionsCompleted: sessionsCompleted,
      period: period,
      avatarUrl: avatarUrl,
      rank: rank ?? this.rank,
    );
  }
}
