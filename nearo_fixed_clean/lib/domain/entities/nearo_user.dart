import 'package:cloud_firestore/cloud_firestore.dart';

class NearoUser {
  final String uid;
  final String displayName;
  final String? email;
  final int age;
  final String bio;
  final String moodStatus;
  final String? photoUrl;
  final String? wifiHash;
  final bool visible;
  final bool isVerified;
  final bool isBanned;
  final int signalsSent;
  final int matchesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NearoUser({
    required this.uid,
    required this.displayName,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.bio = '',
    this.moodStatus = 'Open to meet',
    this.photoUrl,
    this.wifiHash,
    this.visible = true,
    this.isVerified = false,
    this.isBanned = false,
    this.signalsSent = 0,
    this.matchesCount = 0,
  });

  factory NearoUser.demo({String uid = 'demo-user'}) {
    final now = DateTime.now();
    return NearoUser(
      uid: uid,
      displayName: 'Demo User',
      email: 'demo@nearo.app',
      age: 24,
      bio: 'Testing Nearo in demo mode.',
      moodStatus: 'Ready to socialize',
      wifiHash: 'demo-venue-hash',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory NearoUser.fromMap(Map<String, dynamic> map, String id) {
    return NearoUser(
      uid: id,
      displayName: map['displayName'] as String? ?? 'Nearo User',
      email: map['email'] as String?,
      age: (map['age'] as num?)?.toInt() ?? 18,
      bio: map['bio'] as String? ?? '',
      moodStatus: map['moodStatus'] as String? ?? 'Open to meet',
      photoUrl: map['photoUrl'] as String?,
      wifiHash: map['wifiHash'] as String?,
      visible: map['visible'] as bool? ?? true,
      isVerified: map['isVerified'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      signalsSent: (map['signalsSent'] as num?)?.toInt() ?? 0,
      matchesCount: (map['matchesCount'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'age': age,
      'bio': bio,
      'moodStatus': moodStatus,
      'photoUrl': photoUrl,
      'wifiHash': wifiHash,
      'visible': visible,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'signalsSent': signalsSent,
      'matchesCount': matchesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NearoUser copyWith({
    String? displayName,
    String? bio,
    String? moodStatus,
    String? photoUrl,
    String? wifiHash,
    bool? visible,
    int? signalsSent,
    int? matchesCount,
  }) {
    return NearoUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      age: age,
      bio: bio ?? this.bio,
      moodStatus: moodStatus ?? this.moodStatus,
      photoUrl: photoUrl ?? this.photoUrl,
      wifiHash: wifiHash ?? this.wifiHash,
      visible: visible ?? this.visible,
      isVerified: isVerified,
      isBanned: isBanned,
      signalsSent: signalsSent ?? this.signalsSent,
      matchesCount: matchesCount ?? this.matchesCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
