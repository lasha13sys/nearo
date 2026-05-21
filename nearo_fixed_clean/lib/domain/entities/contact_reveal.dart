import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactRevealStatus { requested, approved, declined, expired }
enum ContactRevealType { phone, instagram, telegram, whatsapp }

class ContactReveal {
  final String id;
  final String matchId;
  final String requesterId;
  final String receiverId;
  final ContactRevealType contactType;
  final ContactRevealStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? revealedValue;

  const ContactReveal({
    required this.id,
    required this.matchId,
    required this.requesterId,
    required this.receiverId,
    required this.contactType,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.revealedValue,
  });

  bool canShowTo(String uid) {
    return status == ContactRevealStatus.approved &&
        revealedValue != null &&
        (uid == requesterId || uid == receiverId);
  }

  factory ContactReveal.fromMap(Map<String, dynamic> map, String id) {
    return ContactReveal(
      id: id,
      matchId: map['matchId'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      contactType: ContactRevealType.values.firstWhere(
        (value) => value.name == (map['contactType'] as String? ?? ContactRevealType.instagram.name),
        orElse: () => ContactRevealType.instagram,
      ),
      status: ContactRevealStatus.values.firstWhere(
        (value) => value.name == (map['status'] as String? ?? ContactRevealStatus.requested.name),
        orElse: () => ContactRevealStatus.requested,
      ),
      createdAt: _readDate(map['createdAt']),
      expiresAt: _readDate(map['expiresAt']),
      revealedValue: map['revealedValue'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'requesterId': requesterId,
        'receiverId': receiverId,
        'contactType': contactType.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        if (revealedValue != null) 'revealedValue': revealedValue,
      };

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
