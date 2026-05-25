import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/contact_reveal.dart';

class ContactRevealRequestResult {
  final bool created;
  final String message;

  const ContactRevealRequestResult({
    required this.created,
    required this.message,
  });
}

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

  Future<ContactRevealRequestResult> requestReveal({
    required String matchId,
    required String requesterId,
    required String receiverId,
    required ContactRevealType contactType,
  }) async {
    if (requesterId == receiverId || receiverId.isEmpty) {
      return const ContactRevealRequestResult(created: false, message: 'Contact reveal needs another matched person.');
    }
    if (!firebaseReady || _firestore == null || requesterId.startsWith('demo-')) {
      return const ContactRevealRequestResult(created: true, message: 'Reveal request saved in demo mode.');
    }

    final existing = await _firestore
        .collection(FirebaseCollections.contactReveals)
        .where('matchId', isEqualTo: matchId)
        .where('requesterId', isEqualTo: requesterId)
        .where('receiverId', isEqualTo: receiverId)
        .where('contactType', isEqualTo: contactType.name)
        .where('status', whereIn: [ContactRevealStatus.requested.name, ContactRevealStatus.approved.name])
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final reveal = ContactReveal.fromMap(existing.docs.first.data(), existing.docs.first.id);
      if (reveal.status == ContactRevealStatus.approved) {
        return const ContactRevealRequestResult(created: false, message: 'This contact is already approved.');
      }
      return const ContactRevealRequestResult(created: false, message: 'Reveal request is already pending.');
    }

    await _firestore.collection(FirebaseCollections.contactReveals).add({
      'matchId': matchId,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'contactType': contactType.name,
      'status': ContactRevealStatus.requested.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
    });
    return const ContactRevealRequestResult(created: true, message: 'Reveal requested. It unlocks only after approval.');
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
