/// App-wide constants for Remindfully.
class AppConstants {
  AppConstants._();

  // TODO: Replace with your PocketBase URL if self-hosting on a different server
  static const String pocketbaseUrl = 'http://178.156.225.241:8090';

  static const String appName = 'Remindfully';

  // Session duration options in minutes
  static const List<int> sessionDurations = [5, 10, 15, 20, 30, 45, 60];

  // Tap challenge window in seconds
  static const double tapWindowSeconds = 4.0;

  // Points awarded per successful tap (multiplied by reaction speed factor)
  static const int basePointsPerTap = 100;

  // Points deducted for missed tap
  static const int penaltyPointsPerMiss = 50;

  // Silence gap duration range (seconds)
  static const double minSilenceDuration = 2.0;
  static const double maxSilenceDuration = 6.0;

  // Interval between silence gaps (seconds)
  static const double minGapInterval = 15.0;
  static const double maxGapInterval = 45.0;

  // Leaderboard period keys
  static const String periodAllTime = 'all_time';
  static const String periodWeekly = 'weekly';
  static const String periodDaily = 'daily';

  // Friendship status values
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';

  // SharedPreferences keys
  static const String prefAuthToken = 'auth_token';
  static const String prefAuthModel = 'auth_model';
  static const String prefIsGuest = 'is_guest';
  static const String prefGuestPoints = 'guest_points';
  static const String prefGuestSessions = 'guest_sessions';
}
