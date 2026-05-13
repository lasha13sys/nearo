import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/nearo_user.dart';

class UserRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  UserRepository({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Future<NearoUser> ensureUserProfile({
    required AppUser appUser,
    int age = 18,
  }) async {
    if (!firebaseReady || _firestore == null || appUser.isDemo) {
      return NearoUser.demo(uid: appUser.uid).copyWith(
        displayName: appUser.displayName,
      );
    }

    final ref = _firestore.collection(FirebaseCollections.users).doc(appUser.uid);
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.data() != null) {
      return NearoUser.fromMap(snapshot.data()!, snapshot.id);
    }

    final now = DateTime.now();
    final user = NearoUser(
      uid: appUser.uid,
      displayName: appUser.displayName,
      email: appUser.email,
      age: age,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(user.toMap());
    return user;
  }

  Stream<NearoUser?> watchUser(String uid) {
    if (!firebaseReady || _firestore == null || uid == 'demo-user') {
      return Stream<NearoUser?>.value(NearoUser.demo(uid: uid));
    }

    return _firestore.collection(FirebaseCollections.users).doc(uid).snapshots().map(
      (doc) {
        final data = doc.data();
        return data == null ? null : NearoUser.fromMap(data, doc.id);
      },
    );
  }

  Stream<List<NearoUser>> watchNearbyUsers({
    required String currentUserId,
    String? wifiHash,
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
          .where((doc) => doc.id != currentUserId)
          .map((doc) => NearoUser.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<void> updateVisibility({required String uid, required bool visible}) async {
    if (!firebaseReady || _firestore == null || uid == 'demo-user') return;
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'visible': visible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWifiHash({required String uid, required String? wifiHash}) async {
    if (!firebaseReady || _firestore == null || uid == 'demo-user') return;
    await _firestore.collection(FirebaseCollections.users).doc(uid).update({
      'wifiHash': wifiHash,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<NearoUser> _demoNearbyUsers() {
    final now = DateTime.now();
    return [
      NearoUser(
        uid: 'demo-nearby-1',
        displayName: 'Mariam',
        age: 23,
        bio: 'Jazz, rooftop views, and good espresso.',
        moodStatus: 'At Velvet Lounge',
        wifiHash: 'demo-venue-hash',
        createdAt: now,
        updatedAt: now,
      ),
      NearoUser(
        uid: 'demo-nearby-2',
        displayName: 'Giorgi',
        age: 26,
        bio: 'Here for EDM and meeting new people.',
        moodStatus: 'Open to talk',
        wifiHash: 'demo-venue-hash',
        createdAt: now,
        updatedAt: now,
      ),
      NearoUser(
        uid: 'demo-nearby-3',
        displayName: 'Nino',
        age: 24,
        bio: 'Social but shy — send a signal first.',
        moodStatus: 'Looking for friends',
        wifiHash: 'demo-venue-hash',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
