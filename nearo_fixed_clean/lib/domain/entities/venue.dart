import 'package:cloud_firestore/cloud_firestore.dart';

enum VenueAtmosphere { quiet, social, party, chill, lively, romantic, upscale }

class VenueLiveStats {
  final int activeUsers;
  final int socialEnergy;
  final int capacityPercent;
  final int averageAge;
  final int openUsersCount;
  final int matchesTonight;
  final int crowdLevel;
  final String waitTime;

  const VenueLiveStats({
    required this.activeUsers,
    required this.socialEnergy,
    required this.capacityPercent,
    required this.averageAge,
    this.openUsersCount = 0,
    this.matchesTonight = 0,
    this.crowdLevel = 0,
    this.waitTime = 'No wait',
  });

  factory VenueLiveStats.fromMap(Map<String, dynamic>? map) {
    return VenueLiveStats(
      activeUsers: (map?['activeUsers'] as num?)?.toInt() ?? (map?['openUsersCount'] as num?)?.toInt() ?? 0,
      socialEnergy: (map?['socialEnergy'] as num?)?.toInt() ?? 0,
      capacityPercent: (map?['capacityPercent'] as num?)?.toInt() ?? (map?['crowdLevel'] as num?)?.toInt() ?? 0,
      averageAge: (map?['averageAge'] as num?)?.toInt() ?? 0,
      openUsersCount: (map?['openUsersCount'] as num?)?.toInt() ?? (map?['activeUsers'] as num?)?.toInt() ?? 0,
      matchesTonight: (map?['matchesTonight'] as num?)?.toInt() ?? 0,
      crowdLevel: (map?['crowdLevel'] as num?)?.toInt() ?? 0,
      waitTime: map?['waitTime'] as String? ?? 'No wait',
    );
  }

  Map<String, dynamic> toMap() => {
        'activeUsers': activeUsers,
        'socialEnergy': socialEnergy,
        'capacityPercent': capacityPercent,
        'averageAge': averageAge,
        'openUsersCount': openUsersCount,
        'matchesTonight': matchesTonight,
        'crowdLevel': crowdLevel,
        'waitTime': waitTime,
      };
}

class Venue {
  final String id;
  final String name;
  final String description;
  final String address;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final List<String> wifiHashes;
  final VenueLiveStats liveStats;
  final VenueAtmosphere atmosphere;
  final String vibe;
  final String musicType;
  final double rating;
  final int priceTier;
  final String hours;
  final List<String> tags;
  final List<String> activeEventIds;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.wifiHashes,
    required this.liveStats,
    required this.atmosphere,
    required this.musicType,
    required this.rating,
    required this.priceTier,
    required this.hours,
    required this.tags,
    this.vibe = 'Social',
    this.photoUrl,
    this.activeEventIds = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String? get coverImageUrl => photoUrl;

  factory Venue.fromMap(Map<String, dynamic> map, String id) {
    final atmosphereName = map['atmosphere'] as String? ?? map['vibe'] as String? ?? 'chill';
    return Venue(
      id: id,
      name: map['name'] as String? ?? 'Unknown venue',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['coverImageUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      wifiHashes: List<String>.from(map['wifiHashes'] as List? ?? const []),
      liveStats: VenueLiveStats.fromMap(map['liveStats'] as Map<String, dynamic>? ?? map),
      atmosphere: VenueAtmosphere.values.firstWhere(
        (value) => value.name == atmosphereName.toLowerCase(),
        orElse: () => VenueAtmosphere.chill,
      ),
      vibe: map['vibe'] as String? ?? atmosphereName,
      musicType: map['musicType'] as String? ?? map['music'] as String? ?? 'Mixed',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      priceTier: (map['priceTier'] as num?)?.toInt() ?? 1,
      hours: map['hours'] as String? ?? '',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      activeEventIds: List<String>.from(map['activeEventIds'] as List? ?? const []),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] == null ? null : _readDate(map['createdAt']),
      updatedAt: map['updatedAt'] == null ? null : _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'address': address,
        'photoUrl': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'wifiHashes': wifiHashes,
        'liveStats': liveStats.toMap(),
        'atmosphere': atmosphere.name,
        'vibe': vibe,
        'musicType': musicType,
        'rating': rating,
        'priceTier': priceTier,
        'hours': hours,
        'tags': tags,
        'activeEventIds': activeEventIds,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
