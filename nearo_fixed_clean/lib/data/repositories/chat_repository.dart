import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/chat_message.dart';

class ChatRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;

  ChatRepository({required this.firebaseReady})
      : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (!firebaseReady || _firestore == null || conversationId == 'demo-conversation') {
      return Stream<List<ChatMessage>>.value([
        ChatMessage(
          id: 'demo-msg-1',
          senderId: 'demo-nearby-1',
          text: 'Hey! Nice to match here.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ]);
    }

    return _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    if (!firebaseReady || _firestore == null || conversationId == 'demo-conversation') return;

    final messageRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .doc();

    await messageRef.set(
      ChatMessage(
        id: messageRef.id,
        senderId: senderId,
        text: text.trim(),
        createdAt: DateTime.now(),
        readBy: [senderId],
      ).toMap(),
    );

    await _firestore.collection(FirebaseCollections.conversations).doc(conversationId).update({
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
