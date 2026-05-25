import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_collections.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/icebreaker.dart';

class ChatRepository {
  final bool firebaseReady;
  final FirebaseFirestore? _firestore;
  static final Map<String, List<ChatMessage>> _demoMessages = {};
  static final Map<String, StreamController<List<ChatMessage>>>
  _demoMessageControllers = {};

  ChatRepository({required this.firebaseReady})
    : _firestore = firebaseReady ? FirebaseFirestore.instance : null;

  Stream<Conversation?> watchConversation(String conversationId) {
    if (!firebaseReady ||
        _firestore == null ||
        conversationId == 'demo-conversation') {
      return Stream<Conversation?>.value(Conversation.demo());
    }
    return _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          return data == null ? null : Conversation.fromMap(data, doc.id);
        });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    if (!firebaseReady ||
        _firestore == null ||
        conversationId == 'demo-conversation') {
      return _watchDemoMessages(conversationId);
    }

    return _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Icebreaker>> watchIcebreakers({required int currentUserAge}) {
    if (!firebaseReady || _firestore == null) {
      return Stream<List<Icebreaker>>.value(
        Icebreaker.defaultsForAge(currentUserAge),
      );
    }
    return _firestore
        .collection(FirebaseCollections.icebreakers)
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => Icebreaker.fromMap(doc.data(), doc.id))
              .toList();
          final filtered = items
              .where((item) => currentUserAge >= 18 || !item.adultOnly)
              .toList();
          return filtered.isEmpty
              ? Icebreaker.defaultsForAge(currentUserAge)
              : filtered;
        });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    if (!firebaseReady ||
        _firestore == null ||
        conversationId == 'demo-conversation') {
      _appendDemoMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text.trim(),
      );
      return;
    }

    final messageRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId)
        .collection(FirebaseCollections.messages)
        .doc();

    final conversationRef = _firestore
        .collection(FirebaseCollections.conversations)
        .doc(conversationId);
    await _firestore.runTransaction((transaction) async {
      transaction.set(
        messageRef,
        ChatMessage(
          id: messageRef.id,
          senderId: senderId,
          text: text.trim(),
          createdAt: DateTime.now(),
          readBy: [senderId],
        ).toMap(),
      );
      transaction.set(conversationRef, {
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Stream<List<ChatMessage>> _watchDemoMessages(String conversationId) async* {
    _ensureDemoConversation(conversationId);
    yield List<ChatMessage>.unmodifiable(_demoMessages[conversationId]!);
    yield* _demoMessageControllers[conversationId]!.stream;
  }

  void _appendDemoMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    _ensureDemoConversation(conversationId);
    final items = _demoMessages[conversationId]!;
    items.add(
      ChatMessage(
        id: 'demo-msg-${items.length + 1}',
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
        readBy: [senderId],
      ),
    );
    _demoMessageControllers[conversationId]!.add(
      List<ChatMessage>.unmodifiable(items),
    );
  }

  void _ensureDemoConversation(String conversationId) {
    _demoMessages.putIfAbsent(
      conversationId,
      () => [
        ChatMessage(
          id: 'demo-msg-1',
          senderId: 'demo-nearby-1',
          text: 'Hey... so we actually matched',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );
    _demoMessageControllers.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
  }
}
