import 'package:cloud_firestore/cloud_firestore.dart';

enum VenueAtmosphere { chill, vibrant, intense, cozy, upscale }

class VenueLiveStats {
  final int activeUsers;
  final int socialEnergy;
  final int capacityPercent;
  final int averageAge;

  const VenueLiveStats({
    required this.activeUsers,
    required this.socialEnergy,
    required this.capacityPercent,
    required this.averageAge,
  });

  factory VenueLiveStats.fromMap(Map<String, dynamic>? map) {
    return VenueLiveStats(
      activeUsers: (map?['activeUsers'] as num?)?.toInt() ?? 0,
      socialEnergy: (map?['socialEnergy'] as num?)?.toInt() ?? 0,
      capacityPercent: (map?['capacityPercent'] as num?)?.toInt() ?? 0,
      averageAge: (map?['averageAge'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'activeUsers': activeUsers,
        'socialEnergy': socialEnergy,
        'capacityPercent': capacityPercent,
        'averageAge': averageAge,
      };
}

class Venue {
  final String id;
  final String name;
  final String description;
  final String address;
  final String? coverImageUrl;
  final double latitude;
  final double longitude;
  final List<String> wifiHashes;
  final VenueLiveStats liveStats;
  final VenueAtmosphere atmosphere;
  final String musicType;
  final double rating;
  final int priceTier;
  final String hours;
  final List<String> tags;
  final bool isActive;

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
    this.coverImageUrl,
    this.isActive = true,
  });

  factory Venue.fromMap(Map<String, dynamic> map, String id) {
    return Venue(
      id: id,
      name: map['name'] as String? ?? 'Unknown venue',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      coverImageUrl: map['coverImageUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      wifiHashes: List<String>.from(map['wifiHashes'] as List? ?? const []),
      liveStats: VenueLiveStats.fromMap(map['liveStats'] as Map<String, dynamic>?),
      atmosphere: VenueAtmosphere.values.firstWhere(
        (value) => value.name == (map['atmosphere'] as String? ?? 'chill'),
        orElse: () => VenueAtmosphere.chill,
      ),
      musicType: map['musicType'] as String? ?? 'Mixed',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      priceTier: (map['priceTier'] as num?)?.toInt() ?? 1,
      hours: map['hours'] as String? ?? '',
      tags: List<String>.from(map['tags'] as List? ?? const []),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'address': address,
        'coverImageUrl': coverImageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'wifiHashes': wifiHashes,
        'liveStats': liveStats.toMap(),
        'atmosphere': atmosphere.name,
        'musicType': musicType,
        'rating': rating,
        'priceTier': priceTier,
        'hours': hours,
        'tags': tags,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
