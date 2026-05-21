import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchStatus { active, expired, blocked, completed }

class Match {
  final String id;
  final List<String> userIds;
  final MatchStatus status;
  final String? conversationId;
  final String? connectionId;
  final String? venueId;
  final String? venueWifiHash;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastInteractionAt;

  const Match({
    required this.id,
    required this.userIds,
    required this.status,
    required this.createdAt,
    this.conversationId,
    this.connectionId,
    this.venueId,
    this.venueWifiHash,
    this.expiresAt,
    this.lastInteractionAt,
  });

  String get user1Id => userIds.isNotEmpty ? userIds.first : '';
  String get user2Id => userIds.length > 1 ? userIds[1] : '';

  factory Match.demo() {
    return Match(
      id: 'demo-match',
      userIds: const ['demo-user', 'demo-nearby-1'],
      status: MatchStatus.active,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      conversationId: 'demo-conversation',
      connectionId: 'demo-match',
      venueId: 'venue-1',
      venueWifiHash: 'demo-venue-hash',
    );
  }

  factory Match.fromMap(Map<String, dynamic> map, String id) {
    final userIds = List<String>.from(
      map['userIds'] as List? ??
          map['participants'] as List? ??
          [map['user1Id'] as String? ?? '', map['user2Id'] as String? ?? ''],
    ).where((value) => value.isNotEmpty).toList();

    return Match(
      id: id,
      userIds: userIds,
      status: MatchStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? MatchStatus.active.name),
        orElse: () => MatchStatus.active,
      ),
      conversationId: map['conversationId'] as String?,
      connectionId: map['connectionId'] as String?,
      venueId: map['venueId'] as String?,
      venueWifiHash: map['venueWifiHash'] as String?,
      createdAt: _readDate(map['createdAt']),
      expiresAt: map['expiresAt'] == null ? null : _readDate(map['expiresAt']),
      lastInteractionAt: map['lastInteractionAt'] == null ? null : _readDate(map['lastInteractionAt']),
    );
  }

  String otherUserId(String currentUserId) {
    return userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
