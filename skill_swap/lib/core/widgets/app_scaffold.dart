import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/notifications/providers/notification_providers.dart';

class AppScaffold extends ConsumerWidget {
  final int navIndex;
  final void Function(int) onNavTap;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? fab;

  const AppScaffold({
    super.key,
    required this.navIndex,
    required this.onNavTap,
    this.appBar,
    required this.body,
    this.fab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: AppBottomNav(currentIndex: navIndex, onTap: onNavTap, unreadCount: unread),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final int unreadCount;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Discover'),
        const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Create'),
        const BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), activeIcon: Icon(Icons.groups), label: 'Community'),
        BottomNavigationBarItem(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.person_outline),
              if (unreadCount > 0)
                Positioned(
                  right: -4, top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          activeIcon: const Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
