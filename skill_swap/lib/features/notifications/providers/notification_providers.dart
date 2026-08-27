import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../../auth/providers/auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (_) => NotificationRepository(),
);

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.read).length;
});
