import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../notifications/models/notification_model.dart';

class ChatRepository {
  final _db = FirebaseFirestore.instance;

  String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Stream<List<MessageModel>> watchMessages(String chatId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(MessageModel.fromFirestore).toList());

  Stream<List<ChatModel>> watchUserChats(String userId) => _db
      .collection('chats')
      .where('participantIds', arrayContains: userId)
      .orderBy('lastAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ChatModel.fromFirestore).toList());

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
    required String? senderPhoto,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _db.batch();
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final chatRef = _db.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'participantIds': [senderId, otherUserId],
      'participantNames': {senderId: senderName, otherUserId: otherUserName},
      'participantPhotos': {senderId: senderPhoto, otherUserId: otherUserPhoto},
      'lastMessage': trimmed,
      'lastAt': FieldValue.serverTimestamp(),
      'unreadCounts': {otherUserId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    await batch.commit();

    if (otherUserId.isNotEmpty && otherUserId != senderId) {
      await NotificationRepository.create(
        userId: otherUserId,
        title: 'New message',
        body: '$senderName: $trimmed',
        type: NotificationType.system,
        actionId: senderId,
      );
    }
  }

  Future<void> clearUnread(String chatId, String userId) =>
      _db.collection('chats').doc(chatId).update({'unreadCounts.$userId': 0});
}
