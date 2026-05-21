import 'package:cloud_firestore/cloud_firestore.dart';

enum IcebreakerCategory { coffee, fun, easyStart, venue, custom }

class Icebreaker {
  final String id;
  final IcebreakerCategory category;
  final String text;
  final bool enabled;
  final DateTime createdAt;
  final bool adultOnly;

  const Icebreaker({
    required this.id,
    required this.category,
    required this.text,
    required this.createdAt,
    this.enabled = true,
    this.adultOnly = false,
  });

  factory Icebreaker.fromMap(Map<String, dynamic> map, String id) {
    return Icebreaker(
      id: id,
      category: IcebreakerCategory.values.firstWhere(
        (value) => value.name == (map['category'] as String? ?? IcebreakerCategory.easyStart.name),
        orElse: () => IcebreakerCategory.easyStart,
      ),
      text: map['text'] as String? ?? 'Say something fun',
      enabled: map['enabled'] as bool? ?? true,
      adultOnly: map['adultOnly'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category.name,
        'text': text,
        'enabled': enabled,
        'adultOnly': adultOnly,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static List<Icebreaker> defaultsForAge(int age) {
    final now = DateTime.now();
    final defaults = [
      Icebreaker(id: 'coffee', category: IcebreakerCategory.coffee, text: 'Coffee?', createdAt: now),
      Icebreaker(id: 'fun', category: IcebreakerCategory.fun, text: 'Say something fun', createdAt: now),
      Icebreaker(id: 'easy_start', category: IcebreakerCategory.easyStart, text: 'What caught your attention first?', createdAt: now),
      Icebreaker(id: 'venue', category: IcebreakerCategory.venue, text: 'What is the vibe here tonight?', createdAt: now),
      Icebreaker(id: 'wine', category: IcebreakerCategory.venue, text: 'Wine or jazz?', createdAt: now, adultOnly: true),
    ];
    return defaults.where((item) => age >= 18 || !item.adultOnly).toList();
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
