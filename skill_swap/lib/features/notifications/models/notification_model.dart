import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { match, request, community, collaboration, appreciation, system }

extension NotificationTypeX on NotificationType {
  String get value => name;
  static NotificationType from(String v) =>
      NotificationType.values.firstWhere((e) => e.name == v, orElse: () => NotificationType.system);
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final String? actionId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    this.actionId,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      type: NotificationTypeX.from(d['type'] ?? 'system'),
      read: d['read'] ?? false,
      actionId: d['actionId'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.value,
        'read': read,
        'actionId': actionId,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        actionId: actionId,
        createdAt: createdAt,
      );
}
