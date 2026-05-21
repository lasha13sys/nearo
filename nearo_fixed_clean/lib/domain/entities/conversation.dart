import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String matchId;
  final List<String> userIds;
  final String? venueId;
  final String? venueName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.matchId,
    required this.userIds,
    required this.createdAt,
    this.venueId,
    this.venueName,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.demo() {
    return Conversation(
      id: 'demo-conversation',
      matchId: 'demo-match',
      userIds: const ['demo-user', 'demo-nearby-1'],
      venueName: 'Mono Lounge',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    );
  }

  factory Conversation.fromMap(Map<String, dynamic> map, String id) {
    return Conversation(
      id: id,
      matchId: map['matchId'] as String? ?? id,
      userIds: List<String>.from(map['userIds'] as List? ?? map['participants'] as List? ?? const []),
      venueId: map['venueId'] as String?,
      venueName: map['venueName'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: map['lastMessageAt'] == null ? null : _readDate(map['lastMessageAt']),
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
