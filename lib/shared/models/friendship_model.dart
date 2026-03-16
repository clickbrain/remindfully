import '../constants/app_constants.dart';

/// Represents a friendship between two users.
class FriendshipModel {
  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.requesterUsername,
    this.receiverUsername,
  });

  factory FriendshipModel.fromRecord(Map<String, dynamic> data) {
    final expand = data['expand'] as Map<String, dynamic>?;
    final requester = expand?['requester'] as Map<String, dynamic>?;
    final receiver = expand?['receiver'] as Map<String, dynamic>?;

    return FriendshipModel(
      id: data['id'] as String? ?? '',
      requesterId: data['requester'] as String? ?? '',
      receiverId: data['receiver'] as String? ?? '',
      status: data['status'] as String? ?? AppConstants.statusPending,
      createdAt: DateTime.tryParse(
            data['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      requesterUsername: requester?['username'] as String?,
      receiverUsername: receiver?['username'] as String?,
    );
  }

  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  final String? requesterUsername;
  final String? receiverUsername;

  bool get isPending => status == AppConstants.statusPending;
  bool get isAccepted => status == AppConstants.statusAccepted;
}
