import 'package:cloud_firestore/cloud_firestore.dart';

class VenueEvent {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime endsAt;
  final String vibe;
  final String music;
  final int crowdLevel;
  final String waitTime;
  final DateTime createdAt;

  const VenueEvent({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.vibe,
    required this.music,
    required this.crowdLevel,
    required this.waitTime,
    required this.createdAt,
  });

  factory VenueEvent.fromMap(Map<String, dynamic> map, String id) {
    return VenueEvent(
      id: id,
      venueId: map['venueId'] as String? ?? '',
      title: map['title'] as String? ?? 'Tonight at Nearo',
      description: map['description'] as String? ?? '',
      startsAt: _readDate(map['startsAt']),
      endsAt: _readDate(map['endsAt']),
      vibe: map['vibe'] as String? ?? 'Social',
      music: map['music'] as String? ?? 'Mixed',
      crowdLevel: (map['crowdLevel'] as num?)?.toInt() ?? 0,
      waitTime: map['waitTime'] as String? ?? 'No wait',
      createdAt: _readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'venueId': venueId,
        'title': title,
        'description': description,
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'vibe': vibe,
        'music': music,
        'crowdLevel': crowdLevel,
        'waitTime': waitTime,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
