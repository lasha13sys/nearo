import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { active, expired, completed }

class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final MatchStatus status;
  final String? conversationId;
  final DateTime createdAt;

  const Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.createdAt,
    this.conversationId,
  });

  factory Match.demo() {
    return Match(
      id: 'demo-match',
      user1Id: 'demo-user',
      user2Id: 'demo-nearby-1',
      status: MatchStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      conversationId: 'demo-conversation',
    );
  }

  factory Match.fromMap(Map<String, dynamic> map, String id) {
    return Match(
      id: id,
      user1Id: map['user1Id'] as String? ?? '',
      user2Id: map['user2Id'] as String? ?? '',
      status: MatchStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? 'active'),
        orElse: () => MatchStatus.active,
      ),
      conversationId: map['conversationId'] as String?,
      createdAt: _readDate(map['createdAt']),
    );
  }

  String otherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
