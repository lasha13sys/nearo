import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firebase_collections.dart';

class ReportService {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  ReportService({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    if (!firebaseReady || _firestore == null) return;
    await _firestore.collection(FirebaseCollections.reports).add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'details': details,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
