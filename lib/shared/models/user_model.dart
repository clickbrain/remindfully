/// Represents a user in the Remindfully app.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.totalPoints,
    required this.sessionsCompleted,
    required this.averageReactionTime,
    this.avatarUrl,
    this.isGuest = false,
  });

  factory UserModel.fromRecord(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? 'Unknown',
      totalPoints: (data['total_points'] as num?)?.toInt() ?? 0,
      sessionsCompleted: (data['sessions_completed'] as num?)?.toInt() ?? 0,
      averageReactionTime:
          (data['average_reaction_time'] as num?)?.toDouble() ?? 0.0,
      avatarUrl: data['avatar_url'] as String?,
    );
  }

  factory UserModel.guest() {
    return const UserModel(
      id: 'guest',
      email: '',
      username: 'Guest',
      totalPoints: 0,
      sessionsCompleted: 0,
      averageReactionTime: 0,
      isGuest: true,
    );
  }

  final String id;
  final String email;
  final String username;
  final int totalPoints;
  final int sessionsCompleted;
  final double averageReactionTime;
  final String? avatarUrl;
  final bool isGuest;

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    int? totalPoints,
    int? sessionsCompleted,
    double? averageReactionTime,
    String? avatarUrl,
    bool? isGuest,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      totalPoints: totalPoints ?? this.totalPoints,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      averageReactionTime: averageReactionTime ?? this.averageReactionTime,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
