import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/connection.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/signal.dart';

class SignalSendResult {
  final bool success;
  final String message;
  final String? signalId;

  const SignalSendResult({
    required this.success,
    required this.message,
    this.signalId,
  });
}

class SignalRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  SignalRepository({required this.firebaseReady})
    : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Future<SignalSendResult> sendSignal({
    required String senderId,
    required String receiverId,
    String? venueId,
    String? venueWifiHash,
    String? message,
  }) async {
    if (senderId == receiverId) {
      return const SignalSendResult(
        success: false,
        message: 'You cannot signal yourself.',
      );
    }
    if (!firebaseReady ||
        _firestore == null ||
        senderId == 'demo-user' ||
        senderId.startsWith('demo-')) {
      return const SignalSendResult(
        success: true,
        message: 'Spark sent in demo mode.',
        signalId: 'demo-signal',
      );
    }

    final now = DateTime.now();
    final existing = await _firestore
        .collection(FirebaseCollections.signals)
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where(
          'status',
          whereIn: [SignalStatus.pending.name, SignalStatus.matched.name],
        )
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final signal = Signal.fromMap(
        existing.docs.first.data(),
        existing.docs.first.id,
      );
      if (signal.isExpired) {
        await existing.docs.first.reference.update({
          'status': SignalStatus.expired.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (signal.status == SignalStatus.matched) {
        return const SignalSendResult(
          success: false,
          message: 'You already matched. Open your match hub.',
        );
      } else {
        if (signal.cooldownUntil != null &&
            signal.cooldownUntil!.isAfter(now)) {
          return const SignalSendResult(
            success: false,
            message: 'Cooldown active. Try again soon.',
          );
        }
        return const SignalSendResult(
          success: false,
          message: 'Spark already sent.',
        );
      }
    }

    final receiverDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(receiverId)
        .get();
    final receiver = receiverDoc.data();
    if (receiver == null ||
        receiver['visible'] != true ||
        receiver['isBanned'] == true) {
      return const SignalSendResult(
        success: false,
        message: 'This person is not available right now.',
      );
    }
    final ownBlock = await _firestore
        .collection(FirebaseCollections.blocks)
        .where('blockerId', isEqualTo: senderId)
        .where('blockedUserId', isEqualTo: receiverId)
        .limit(1)
        .get();
    if (ownBlock.docs.isNotEmpty) {
      return const SignalSendResult(
        success: false,
        message: 'You blocked this person.',
      );
    }

    final doc = _firestore.collection(FirebaseCollections.signals).doc();
    final signal = Signal(
      id: doc.id,
      senderId: senderId,
      receiverId: receiverId,
      status: SignalStatus.pending,
      message: message,
      venueId: venueId,
      venueWifiHash: venueWifiHash,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 30)),
      cooldownUntil: now.add(const Duration(minutes: 5)),
    );

    await doc.set(signal.toCreateMap());
    return SignalSendResult(
      success: true,
      message: 'Spark sent.',
      signalId: doc.id,
    );
  }

  Stream<List<Signal>> watchIncomingSignals(String userId) {
    if (!firebaseReady ||
        _firestore == null ||
        userId == 'demo-user' ||
        userId.startsWith('demo-')) {
      return Stream<List<Signal>>.value(const []);
    }

    return _firestore
        .collection(FirebaseCollections.signals)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: SignalStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Signal.fromMap(doc.data(), doc.id))
              .where((signal) => !signal.isExpired)
              .toList(),
        );
  }

  Future<void> respondToSignal({
    required String signalId,
    required SignalStatus status,
  }) async {
    if (!firebaseReady || _firestore == null) return;
    if (status != SignalStatus.accepted && status != SignalStatus.declined) {
      return;
    }

    await _firestore
        .collection(FirebaseCollections.signals)
        .doc(signalId)
        .update({
          'status': status.name,
          'respondedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<Match?> waitForMatchBetween({
    required String currentUserId,
    required String otherUserId,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (!firebaseReady ||
        _firestore == null ||
        currentUserId.startsWith('demo-')) {
      return Match.demo();
    }
    final ids = [currentUserId, otherUserId]..sort();
    final matchId = '${ids[0]}_${ids[1]}';
    try {
      return await _firestore
          .collection(FirebaseCollections.matches)
          .doc(matchId)
          .snapshots()
          .map((doc) {
            final data = doc.data();
            if (data == null) return null;
            final match = Match.fromMap(data, doc.id);
            return match.status == MatchStatus.active ? match : null;
          })
          .where((match) => match != null)
          .cast<Match>()
          .first
          .timeout(timeout);
    } on Object {
      return null;
    }
  }

  Stream<List<Match>> watchMatches(String userId) {
    if (!firebaseReady ||
        _firestore == null ||
        userId == 'demo-user' ||
        userId.startsWith('demo-')) {
      return Stream<List<Match>>.value([Match.demo()]);
    }

    return _firestore
        .collection(FirebaseCollections.matches)
        .where('userIds', arrayContains: userId)
        .where('status', isEqualTo: MatchStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Match.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<Connection?> watchConnection(String connectionId) {
    if (!firebaseReady || _firestore == null || connectionId == 'demo-match') {
      return Stream<Connection?>.value(Connection.demo());
    }
    return _firestore
        .collection(FirebaseCollections.connections)
        .doc(connectionId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return data == null ? null : Connection.fromMap(data, doc.id);
        });
  }

  Future<void> selectInteractionOption({
    required String connectionId,
    required String optionId,
  }) async {
    if (!firebaseReady || _firestore == null || connectionId == 'demo-match') {
      return;
    }
    await _firestore
        .collection(FirebaseCollections.connections)
        .doc(connectionId)
        .update({
          'selectedOptions': FieldValue.arrayUnion([optionId]),
          'lastInteractionAt': FieldValue.serverTimestamp(),
          if (optionId == 'meet_now')
            'temporaryTimerEndsAt': Timestamp.fromDate(
              DateTime.now().add(const Duration(minutes: 30)),
            ),
        });
  }
}
