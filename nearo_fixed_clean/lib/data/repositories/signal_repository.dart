import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/signal.dart';

class SignalRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  SignalRepository({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Future<void> sendSignal({
    required String senderId,
    required String receiverId,
    String? venueWifiHash,
    String? message,
  }) async {
    if (!firebaseReady || _firestore == null || senderId == 'demo-user') return;

    final now = DateTime.now();
    final doc = _firestore.collection(FirebaseCollections.signals).doc();
    final signal = Signal(
      id: doc.id,
      senderId: senderId,
      receiverId: receiverId,
      status: SignalStatus.pending,
      message: message,
      venueWifiHash: venueWifiHash,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
    );

    await doc.set(signal.toCreateMap());
  }

  Stream<List<Signal>> watchIncomingSignals(String userId) {
    if (!firebaseReady || _firestore == null || userId == 'demo-user') {
      return Stream<List<Signal>>.value(const []);
    }

    return _firestore
        .collection(FirebaseCollections.signals)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SignalStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Signal.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> respondToSignal({
    required String signalId,
    required SignalStatus status,
  }) async {
    if (!firebaseReady || _firestore == null) return;
    if (status != SignalStatus.accepted && status != SignalStatus.declined) return;

    await _firestore.collection(FirebaseCollections.signals).doc(signalId).update({
      'status': status.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Match>> watchMatches(String userId) {
    if (!firebaseReady || _firestore == null || userId == 'demo-user') {
      return Stream<List<Match>>.value([Match.demo()]);
    }

    return _firestore
        .collection(FirebaseCollections.matches)
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: MatchStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Match.fromMap(doc.data(), doc.id))
            .toList());
  }
}
