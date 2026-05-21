import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus { active, expired, blocked, ended }

class Connection {
  final String id;
  final String matchId;
  final List<String> userIds;
  final ConnectionStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> selectedOptions;
  final DateTime? temporaryTimerEndsAt;

  const Connection({
    required this.id,
    required this.matchId,
    required this.userIds,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.selectedOptions = const [],
    this.temporaryTimerEndsAt,
  });

  factory Connection.demo({String id = 'demo-match'}) {
    final now = DateTime.now();
    return Connection(
      id: id,
      matchId: id,
      userIds: const ['demo-user', 'demo-nearby-1'],
      status: ConnectionStatus.active,
      createdAt: now.subtract(const Duration(minutes: 12)),
      expiresAt: now.add(const Duration(hours: 2)),
      temporaryTimerEndsAt: now.add(const Duration(minutes: 30)),
    );
  }

  factory Connection.fromMap(Map<String, dynamic> map, String id) {
    return Connection(
      id: id,
      matchId: map['matchId'] as String? ?? id,
      userIds: List<String>.from(map['userIds'] as List? ?? map['participants'] as List? ?? const []),
      status: ConnectionStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? ConnectionStatus.active.name),
        orElse: () => ConnectionStatus.active,
      ),
      createdAt: _readDate(map['createdAt']),
      expiresAt: _readDate(map['expiresAt']),
      selectedOptions: List<String>.from(map['selectedOptions'] as List? ?? const []),
      temporaryTimerEndsAt: map['temporaryTimerEndsAt'] == null ? null : _readDate(map['temporaryTimerEndsAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'userIds': userIds,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'selectedOptions': selectedOptions,
        if (temporaryTimerEndsAt != null) 'temporaryTimerEndsAt': Timestamp.fromDate(temporaryTimerEndsAt!),
      };

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
