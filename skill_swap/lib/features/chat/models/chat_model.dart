import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      senderName: d['senderName'] ?? '',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class ChatModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final DateTime lastAt;
  final Map<String, int> unreadCounts;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastAt,
    required this.unreadCounts,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(d['participantIds'] ?? []),
      participantNames: Map<String, String>.from(d['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(d['participantPhotos'] ?? {}),
      lastMessage: d['lastMessage'] ?? '',
      lastAt: (d['lastAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(d['unreadCounts'] ?? {}),
    );
  }

  String otherUserId(String myId) =>
      participantIds.firstWhere((id) => id != myId, orElse: () => '');

  String otherUserName(String myId) =>
      participantNames[otherUserId(myId)] ?? 'Unknown';

  String? otherUserPhoto(String myId) =>
      participantPhotos[otherUserId(myId)];

  int unreadFor(String userId) => unreadCounts[userId] ?? 0;
}
