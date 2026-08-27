import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../providers/notification_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsProvider);
    final repo = ref.watch(notificationRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        actions: [
          notifsAsync.when(
            data: (notifs) => notifs.any((n) => !n.read)
                ? TextButton(
                    onPressed: () async {
                      final user = ref.read(currentUserProvider).value;
                      if (user != null) await repo.markAllRead(user.uid);
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        data: (notifs) {
          final all = notifs;
          final matches = notifs
              .where((n) => n.type == NotificationType.match)
              .toList();
          final requests = notifs
              .where((n) => n.type == NotificationType.request)
              .toList();
          final community = notifs
              .where((n) => n.type == NotificationType.community)
              .toList();

          return Column(
            children: [
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'All (${all.length})'),
                  Tab(text: 'Matches (${matches.length})'),
                  Tab(text: 'Requests (${requests.length})'),
                  Tab(text: 'Community (${community.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _NotifList(items: all, repo: repo),
                    _NotifList(items: matches, repo: repo),
                    _NotifList(items: requests, repo: repo),
                    _NotifList(items: community, repo: repo),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  final List<NotificationModel> items;
  final dynamic repo;
  const _NotifList({required this.items, required this.repo});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 48, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final today = items.where((n) => n.createdAt.isAfter(todayStart)).toList();
    final older = items.where((n) => !n.createdAt.isAfter(todayStart)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (today.isNotEmpty) ...[
          const Text(
            'Today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...today.map((n) => _NotifTile(notif: n, repo: repo)),
          const SizedBox(height: 16),
        ],
        if (older.isNotEmpty) ...[
          const Text(
            'Earlier',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...older.map((n) => _NotifTile(notif: n, repo: repo)),
        ],
      ],
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final NotificationModel notif;
  final dynamic repo;
  const _NotifTile({required this.notif, required this.repo});

  IconData get _icon => switch (notif.type) {
    NotificationType.match => Icons.people,
    NotificationType.request => Icons.help_outline,
    NotificationType.community => Icons.location_on_outlined,
    NotificationType.collaboration => Icons.handshake_outlined,
    NotificationType.appreciation => Icons.star,
    NotificationType.system => Icons.notifications,
  };

  Color get _color => switch (notif.type) {
    NotificationType.match => AppColors.primary,
    NotificationType.request => AppColors.matchMed,
    NotificationType.community => const Color(0xFF0369A1),
    NotificationType.collaboration => const Color(0xFF7C3AED),
    NotificationType.appreciation => const Color(0xFFB45309),
    NotificationType.system => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        if (!notif.read) await repo.markRead(notif.id);

        if (notif.type == NotificationType.system &&
            notif.actionId != null &&
            notif.actionId!.isNotEmpty) {
          final otherUser = await ref
              .read(profileRepositoryProvider)
              .getUser(notif.actionId!);
          if (otherUser != null && context.mounted) {
            Navigator.pushNamed(context, '/chat', arguments: otherUser);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.read ? Colors.white : _color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.read
                ? AppColors.border
                : _color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (notif.title.isNotEmpty)
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: notif.read
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notif.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.read)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
