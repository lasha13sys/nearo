import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/contact_reveal.dart';

class ContactRevealRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  ContactRevealRepository({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Stream<List<ContactReveal>> watchMatchReveals(String matchId) {
    if (!firebaseReady || _firestore == null || matchId == 'demo-match') {
      return Stream<List<ContactReveal>>.value(const []);
    }
    return _firestore
        .collection(FirebaseCollections.contactReveals)
        .where('matchId', isEqualTo: matchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ContactReveal.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> requestReveal({
    required String matchId,
    required String requesterId,
    required String receiverId,
    required ContactRevealType contactType,
  }) async {
    if (!firebaseReady || _firestore == null || requesterId.startsWith('demo-')) return;
    await _firestore.collection(FirebaseCollections.contactReveals).add({
      'matchId': matchId,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'contactType': contactType.name,
      'status': ContactRevealStatus.requested.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
    });
  }

  Future<void> respond({
    required String revealId,
    required ContactRevealStatus status,
  }) async {
    if (!firebaseReady || _firestore == null) return;
    if (status != ContactRevealStatus.approved && status != ContactRevealStatus.declined) return;
    await _firestore.collection(FirebaseCollections.contactReveals).doc(revealId).update({
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
