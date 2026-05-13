import 'package:cloud_firestore/cloud_firestore.dart';

enum SignalStatus { pending, accepted, declined, expired }

class Signal {
  final String id;
  final String senderId;
  final String receiverId;
  final SignalStatus status;
  final String? message;
  final String? venueWifiHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;

  const Signal({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.venueWifiHash,
    this.respondedAt,
  });

  factory Signal.fromMap(Map<String, dynamic> map, String id) {
    return Signal(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      status: SignalStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? 'pending'),
        orElse: () => SignalStatus.pending,
      ),
      message: map['message'] as String?,
      venueWifiHash: map['venueWifiHash'] as String?,
      createdAt: _readDate(map['createdAt']),
      expiresAt: _readDate(map['expiresAt']),
      respondedAt: map['respondedAt'] == null ? null : _readDate(map['respondedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'message': message,
      'venueWifiHash': venueWifiHash,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'updatedAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
