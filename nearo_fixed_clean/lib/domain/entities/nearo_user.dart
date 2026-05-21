import 'package:cloud_firestore/cloud_firestore.dart';

class UserSocials {
  final String? instagram;
  final String? telegram;
  final String? whatsapp;

  const UserSocials({
    this.instagram,
    this.telegram,
    this.whatsapp,
  });

  factory UserSocials.fromMap(Map<String, dynamic>? map) {
    return UserSocials(
      instagram: _cleanHandle(map?['instagram']),
      telegram: _cleanHandle(map?['telegram']),
      whatsapp: _cleanHandle(map?['whatsapp']),
    );
  }

  Map<String, dynamic> toMap() => {
        if (instagram != null && instagram!.isNotEmpty) 'instagram': instagram,
        if (telegram != null && telegram!.isNotEmpty) 'telegram': telegram,
        if (whatsapp != null && whatsapp!.isNotEmpty) 'whatsapp': whatsapp,
      };

  bool get hasAny =>
      (instagram?.isNotEmpty ?? false) ||
      (telegram?.isNotEmpty ?? false) ||
      (whatsapp?.isNotEmpty ?? false);

  String? valueFor(ContactChannel channel, {String? phoneNumber}) {
    return switch (channel) {
      ContactChannel.phone => phoneNumber,
      ContactChannel.instagram => instagram,
      ContactChannel.telegram => telegram,
      ContactChannel.whatsapp => whatsapp,
    };
  }

  static String? _cleanHandle(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum ContactChannel { phone, instagram, telegram, whatsapp }

class NearoUser {
  final String uid;
  final String nickname;
  final String phoneNumber;
  final String photoUrl;
  final int age;
  final String? bio;
  final String? mood;
  final UserSocials socials;
  final String? wifiHash;
  final bool visible;
  final bool isVerified;
  final bool isBanned;
  final List<String> blockedUsers;
  final int signalsSent;
  final int matchesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NearoUser({
    required this.uid,
    required this.nickname,
    required this.phoneNumber,
    required this.photoUrl,
    required this.age,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    this.mood,
    this.socials = const UserSocials(),
    this.wifiHash,
    this.visible = true,
    this.isVerified = false,
    this.isBanned = false,
    this.blockedUsers = const [],
    this.signalsSent = 0,
    this.matchesCount = 0,
  });

  String get displayName => nickname;
  String get moodStatus => mood ?? 'Open to connect';
  bool get isOnboarded => nickname.trim().isNotEmpty && photoUrl.trim().isNotEmpty && age >= 18;

  factory NearoUser.demo({String uid = 'demo-user'}) {
    final now = DateTime.now();
    return NearoUser(
      uid: uid,
      nickname: uid == 'demo-user' ? 'Demo User' : 'Mariam',
      phoneNumber: '+995555000000',
      age: 24,
      bio: 'Live music, espresso, and deep talks.',
      mood: 'Good vibes only',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      wifiHash: 'demo-venue-hash',
      socials: const UserSocials(instagram: 'nearo.demo'),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory NearoUser.fromMap(Map<String, dynamic> map, String id) {
    final fallbackName = map['nickname'] ?? map['displayName'] ?? map['name'];
    final fallbackMood = map['mood'] ?? map['moodStatus'];
    return NearoUser(
      uid: id,
      nickname: fallbackName is String && fallbackName.trim().isNotEmpty ? fallbackName.trim() : 'Nearo User',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['photo'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 18,
      bio: map['bio'] as String?,
      mood: fallbackMood as String?,
      socials: UserSocials.fromMap(map['socials'] as Map<String, dynamic>?),
      wifiHash: map['wifiHash'] as String?,
      visible: map['visible'] as bool? ?? true,
      isVerified: map['isVerified'] as bool? ?? false,
      isBanned: map['isBanned'] as bool? ?? false,
      blockedUsers: List<String>.from(map['blockedUsers'] as List? ?? const []),
      signalsSent: (map['signalsSent'] as num?)?.toInt() ?? 0,
      matchesCount: (map['matchesCount'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'age': age,
      'bio': bio,
      'mood': mood,
      'socials': socials.toMap(),
      'wifiHash': wifiHash,
      'visible': visible,
      'isVerified': isVerified,
      'isBanned': isBanned,
      'blockedUsers': blockedUsers,
      'signalsSent': signalsSent,
      'matchesCount': matchesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toPublicMap() {
    return {
      'nickname': nickname,
      'photoUrl': photoUrl,
      'age': age,
      'bio': bio,
      'mood': mood,
      'visible': visible,
      'wifiHash': wifiHash,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NearoUser copyWith({
    String? nickname,
    String? phoneNumber,
    String? photoUrl,
    int? age,
    String? bio,
    String? mood,
    UserSocials? socials,
    String? wifiHash,
    bool? visible,
    bool? isVerified,
    bool? isBanned,
    List<String>? blockedUsers,
    int? signalsSent,
    int? matchesCount,
  }) {
    return NearoUser(
      uid: uid,
      nickname: nickname ?? this.nickname,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      mood: mood ?? this.mood,
      socials: socials ?? this.socials,
      wifiHash: wifiHash ?? this.wifiHash,
      visible: visible ?? this.visible,
      isVerified: isVerified ?? this.isVerified,
      isBanned: isBanned ?? this.isBanned,
      blockedUsers: blockedUsers ?? this.blockedUsers,
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
