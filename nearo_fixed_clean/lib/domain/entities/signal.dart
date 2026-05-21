import 'package:cloud_firestore/cloud_firestore.dart';

enum SignalStatus { pending, matched, accepted, declined, expired, blocked }

class Signal {
  final String id;
  final String senderId;
  final String receiverId;
  final SignalStatus status;
  final String? message;
  final String? venueId;
  final String? venueWifiHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? cooldownUntil;
  final DateTime? respondedAt;

  const Signal({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.venueId,
    this.venueWifiHash,
    this.cooldownUntil,
    this.respondedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Signal.fromMap(Map<String, dynamic> map, String id) {
    return Signal(
      id: id,
      senderId: map['senderId'] as String? ?? map['fromUser'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? map['toUser'] as String? ?? '',
      status: SignalStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? SignalStatus.pending.name),
        orElse: () => SignalStatus.pending,
      ),
      message: map['message'] as String?,
      venueId: map['venueId'] as String?,
      venueWifiHash: map['venueWifiHash'] as String? ?? map['wifiHash'] as String?,
      createdAt: _readDate(map['createdAt'] ?? map['timestamp']),
      expiresAt: _readDate(map['expiresAt']),
      cooldownUntil: map['cooldownUntil'] == null ? null : _readDate(map['cooldownUntil']),
      respondedAt: map['respondedAt'] == null ? null : _readDate(map['respondedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'message': message,
      'venueId': venueId,
      'venueWifiHash': venueWifiHash,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'cooldownUntil': cooldownUntil == null ? null : Timestamp.fromDate(cooldownUntil!),
      'updatedAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
