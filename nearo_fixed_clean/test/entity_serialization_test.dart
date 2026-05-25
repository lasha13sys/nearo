import 'package:flutter_test/flutter_test.dart';
import 'package:nearo/domain/entities/nearo_user.dart';
import 'package:nearo/domain/entities/signal.dart';

void main() {
  test('NearoUser public map does not expose private contact fields', () {
    final now = DateTime(2026, 5, 25);
    final user = NearoUser(
      uid: 'user-1',
      nickname: 'Luna',
      phoneNumber: '+995555000000',
      photoUrl: 'https://example.com/profile.jpg',
      age: 24,
      socials: const UserSocials(instagram: 'luna', telegram: 'luna_t'),
      blockedUsers: const ['blocked-user'],
      createdAt: now,
      updatedAt: now,
    );

    final publicMap = user.toPublicMap();

    expect(publicMap.containsKey('phoneNumber'), isFalse);
    expect(publicMap.containsKey('socials'), isFalse);
    expect(publicMap.containsKey('blockedUsers'), isFalse);
    expect(publicMap['nickname'], 'Luna');
    expect(publicMap['photoUrl'], 'https://example.com/profile.jpg');
  });

  test('Signal create map keeps required Firestore fields', () {
    final now = DateTime(2026, 5, 25, 21);
    final signal = Signal(
      id: 'signal-1',
      senderId: 'sender',
      receiverId: 'receiver',
      status: SignalStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
      cooldownUntil: now.add(const Duration(minutes: 5)),
      venueWifiHash: 'wifi-hash',
    );

    final map = signal.toCreateMap();

    expect(map['senderId'], 'sender');
    expect(map['receiverId'], 'receiver');
    expect(map['status'], SignalStatus.pending.name);
    expect(map['venueWifiHash'], 'wifi-hash');
    expect(map.containsKey('createdAt'), isTrue);
    expect(map.containsKey('expiresAt'), isTrue);
  });
}
