import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/nearo_user.dart';

class UserRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  UserRepository({required this.firebaseReady})
    : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Future<NearoUser?> getUser(String uid) async {
    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return NearoUser.demo(uid: uid);
    }
    final doc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .get();
    final data = doc.data();
    return data == null ? null : NearoUser.fromMap(data, doc.id);
  }

  Future<NearoUser> ensureUserProfile({
    required AppUser appUser,
    int age = 18,
  }) async {
    if (!firebaseReady || _firestore == null || appUser.isDemo) {
      return NearoUser.demo(uid: appUser.uid).copyWith(
        nickname: appUser.displayName,
        phoneNumber: appUser.phoneNumber,
      );
    }

    final ref = _firestore
        .collection(FirebaseCollections.users)
        .doc(appUser.uid);
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.data() != null) {
      return NearoUser.fromMap(snapshot.data()!, snapshot.id);
    }

    final now = DateTime.now();
    final user = NearoUser(
      uid: appUser.uid,
      nickname: '',
      phoneNumber: appUser.phoneNumber,
      photoUrl: '',
      age: age,
      visible: false,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set({
      ...user.toPublicMap(),
      'phoneNumber': '',
      'socials': <String, dynamic>{},
      'onboarded': false,
      'isBanned': false,
    });
    await _writePrivateContact(user);
    return user;
  }

  Future<void> completeOnboarding({
    required String uid,
    required String phoneNumber,
    required String nickname,
    required int age,
    required String photoUrl,
    String? bio,
    String? mood,
    UserSocials socials = const UserSocials(),
  }) async {
    final now = DateTime.now();
    final user = NearoUser(
      uid: uid,
      nickname: nickname.trim(),
      phoneNumber: phoneNumber.trim(),
      photoUrl: photoUrl.trim(),
      age: age,
      bio: bio?.trim().isEmpty ?? true ? null : bio?.trim(),
      mood: mood?.trim().isEmpty ?? true ? 'Open to connect' : mood?.trim(),
      socials: socials,
      visible: true,
      createdAt: now,
      updatedAt: now,
    );

    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return;
    }

    await _firestore.collection(FirebaseCollections.users).doc(uid).set({
      'nickname': user.nickname,
      'photoUrl': user.photoUrl,
      'age': user.age,
      'bio': user.bio,
      'mood': user.mood,
      'visible': user.visible,
      'wifiHash': user.wifiHash,
      'isVerified': user.isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
      'phoneNumber': '',
      'socials': <String, dynamic>{},
      'onboarded': true,
      'blockedUsers': FieldValue.delete(),
      'fcmToken': FieldValue.delete(),
      'isBanned': false,
    }, SetOptions(merge: true));
    await _writePrivateContact(user);
  }

  Stream<NearoUser?> watchUser(String uid) {
    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return Stream<NearoUser?>.value(NearoUser.demo(uid: uid));
    }

    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return data == null ? null : NearoUser.fromMap(data, doc.id);
        });
  }

  Stream<List<NearoUser>> watchNearbyUsers({
    required String currentUserId,
    String? wifiHash,
    List<String> blockedUsers = const [],
  }) {
    if (!firebaseReady || _firestore == null) {
      return Stream<List<NearoUser>>.value(_demoNearbyUsers());
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection(FirebaseCollections.users)
        .where('visible', isEqualTo: true)
        .where('isBanned', isEqualTo: false)
        .limit(25);

    if (wifiHash != null && wifiHash.isNotEmpty) {
      query = query.where('wifiHash', isEqualTo: wifiHash);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .where(
            (doc) => doc.id != currentUserId && !blockedUsers.contains(doc.id),
          )
          .map((doc) => NearoUser.fromMap(doc.data(), doc.id))
          .where((user) => !user.blockedUsers.contains(currentUserId))
          .toList(),
    );
  }

  Future<void> updateVisibility({
    required String uid,
    required bool visible,
  }) async {
    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return;
    }
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'visible': visible,
      'blockedUsers': FieldValue.delete(),
      'fcmToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFcmToken({
    required String uid,
    required String? token,
  }) async {
    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return;
    }
    final userRef = _firestore.collection(FirebaseCollections.users).doc(uid);
    final notificationRef = userRef.collection('private').doc('notification');
    final batch = _firestore.batch();
    batch.set(notificationRef, {
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.update(userRef, {
      'fcmToken': FieldValue.delete(),
      'blockedUsers': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateWifiHash({
    required String uid,
    required String? wifiHash,
  }) async {
    if (!firebaseReady ||
        _firestore == null ||
        uid == 'demo-user' ||
        uid.startsWith('demo-')) {
      return;
    }
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'wifiHash': wifiHash,
      'blockedUsers': FieldValue.delete(),
      'fcmToken': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (!firebaseReady ||
        _firestore == null ||
        currentUserId.startsWith('demo-')) {
      return;
    }
    final blockRef = _firestore
        .collection(FirebaseCollections.blocks)
        .doc('${currentUserId}_$blockedUserId');
    await blockRef.set({
      'blockerId': currentUserId,
      'blockedUserId': blockedUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> watchBlockedUserIds(String currentUserId) {
    if (!firebaseReady ||
        _firestore == null ||
        currentUserId.startsWith('demo-')) {
      return Stream<List<String>>.value(const []);
    }
    return _firestore
        .collection(FirebaseCollections.blocks)
        .where('blockerId', isEqualTo: currentUserId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['blockedUserId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  Future<void> _writePrivateContact(NearoUser user) async {
    if (_firestore == null ||
        user.uid == 'demo-user' ||
        user.uid.startsWith('demo-')) {
      return;
    }
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .collection('private')
        .doc('contact')
        .set({
          'phoneNumber': user.phoneNumber,
          'socials': user.socials.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  List<NearoUser> _demoNearbyUsers() {
    final now = DateTime.now();
    return [
      NearoUser(
        uid: 'demo-nearby-1',
        nickname: 'Lunaaa',
        phoneNumber: '+995555111111',
        age: 23,
        bio: 'Live music, espresso, and deep talks.',
        mood: 'Good vibes only',
        photoUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        wifiHash: 'demo-venue-hash',
        socials: const UserSocials(instagram: 'lunaaa'),
        createdAt: now,
        updatedAt: now,
      ),
      NearoUser(
        uid: 'demo-nearby-2',
        nickname: 'Nika',
        phoneNumber: '+995555222222',
        age: 26,
        bio: 'Jazz bar, wine, spontaneous walks.',
        mood: 'Open to Meet',
        photoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        wifiHash: 'demo-venue-hash',
        socials: const UserSocials(telegram: 'nika'),
        createdAt: now,
        updatedAt: now,
      ),
      NearoUser(
        uid: 'demo-nearby-3',
        nickname: 'Mariam',
        phoneNumber: '+995555333333',
        age: 24,
        bio: 'Coffee, books, calm conversations.',
        mood: 'Easy Start',
        photoUrl:
            'https://images.unsplash.com/photo-1517841905240-472988babdf9',
        wifiHash: 'demo-venue-hash',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
