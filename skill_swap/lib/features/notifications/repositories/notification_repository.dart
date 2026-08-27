import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../../../core/services/firestore_service.dart';

class NotificationRepository {
  Stream<List<NotificationModel>> watchNotifications(String userId) =>
      FirestoreService.notifications
          .where('userId', isEqualTo: userId)
          .limit(50)
          .snapshots()
          .map((s) {
            final items = s.docs.map(NotificationModel.fromFirestore).toList();
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return items;
          })
          .handleError((_) => <NotificationModel>[]);

  Future<void> markRead(String notifId) =>
      FirestoreService.notifications.doc(notifId).update({'read': true});

  Future<void> markAllRead(String userId) async {
    final snap = await FirestoreService.notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) =>
      FirestoreService.notifications.doc(notifId).delete();

  /// Called by other features to create notifications for users.
  static Future<void> create({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? actionId,
  }) => FirestoreService.notifications.add({
    'userId': userId,
    'title': title,
    'body': body,
    'type': type.value,
    'read': false,
    'actionId': actionId,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
