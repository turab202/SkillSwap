import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';
import '../providers/community_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../notifications/providers/notification_providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});
  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  final _categories = [
    'Education',
    'Coding',
    'Music',
    'Creative',
    'Wellness',
    'Local Life',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _showCreateCommunityDialog() async {
    final user = ref.read(authRepositoryProvider).currentFirebaseUser;
    if (user == null) return;

    String category = 'Education';
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Community'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Community name'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What is this community about?',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => category = value ?? 'Education'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();
                if (name.isEmpty || desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a community name and description.'),
                    ),
                  );
                  return;
                }

                try {
                  await ref
                      .read(communityRepositoryProvider)
                      .createCommunity(
                        CommunityModel(
                          id: '',
                          name: name,
                          description: desc,
                          category: category,
                          memberIds: [user.uid],
                          createdBy: user.uid,
                          createdAt: DateTime.now(),
                        ),
                      );

                  ref.invalidate(allCommunitiesProvider);
                  if (mounted) Navigator.pop(dialogContext);
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not create community: $error'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(int i) {
    const routes = [
      '/home',
      '/discover',
      '/create',
      '/community',
      '/profile-view',
    ];
    Navigator.pushReplacementNamed(context, routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);
    return AppScaffold(
      navIndex: 3,
      onNavTap: _navigate,
      fab: FloatingActionButton(
        onPressed: _showCreateCommunityDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/discover'),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Communities'),
            Tab(text: 'Projects'),
            Tab(text: 'Volunteer'),
            Tab(text: 'Events'),
            Tab(text: 'Mentorship'),
            Tab(text: 'Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _CommunitiesTab(),
          _ProjectsTab(),
          _VolunteerTab(),
          _EventsTab(),
          _MentorshipTab(),
          _LibraryTab(),
        ],
      ),
    );
  }
}

// ── Reusable empty state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            child: const Text('Be the first to post'),
          ),
        ],
      ),
    );
  }
}

// ── Communities Tab ────────────────────────────────────────────────────────
class _CommunitiesTab extends ConsumerWidget {
  const _CommunitiesTab();

  static const _colors = [
    Color(0xFF0369A1),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFFB45309),
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.value?.uid ?? '';
    final allAsync = ref.watch(allCommunitiesProvider);
    final repo = ref.watch(communityRepositoryProvider);

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (communities) {
        if (communities.isEmpty) {
          return _EmptyState(
            message: 'No communities yet.\nCreate one to get started!',
            icon: Icons.people_outline,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (_, i) {
            final c = communities[i];
            final color = _colors[i % _colors.length];
            final isMember = c.isMember(userId);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.people_outline,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${c.memberCount} members',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: userId.isEmpty
                        ? null
                        : () async {
                            if (isMember) {
                              await repo.leaveCommunity(c.id, userId);
                            } else {
                              await repo.joinCommunity(c.id, userId);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember ? AppColors.border : color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isMember ? 'Leave' : 'Join',
                      style: TextStyle(
                        fontSize: 13,
                        color: isMember
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Projects Tab ───────────────────────────────────────────────────────────
class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.watch(communityRepositoryProvider).watchCommunityProjects(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return _EmptyState(
            message: 'No community projects yet.\nStart one!',
            icon: Icons.groups_outlined,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _PostCard(
              data: d,
              actionLabel: 'Join Project',
              onAction: () => Navigator.pushNamed(context, '/create'),
            );
          },
        );
      },
    );
  }
}

// ── Volunteer Tab ──────────────────────────────────────────────────────────
class _VolunteerTab extends ConsumerWidget {
  const _VolunteerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.watch(communityRepositoryProvider).watchVolunteerPosts(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return _EmptyState(
            message: 'No volunteer opportunities yet.\nPost one!',
            icon: Icons.volunteer_activism,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _PostCard(
              data: d,
              actionLabel: 'Sign Up',
              onAction: () => Navigator.pushNamed(context, '/create'),
            );
          },
        );
      },
    );
  }
}

// ── Events Tab ─────────────────────────────────────────────────────────────
class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  static const _colors = [
    Color(0xFF0369A1),
    Color(0xFF7C3AED),
    AppColors.primary,
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.value?.uid ?? '';
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final repo = ref.watch(communityRepositoryProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty)
          return _EmptyState(
            message: 'No upcoming events.\nCreate one!',
            icon: Icons.event_outlined,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[i];
            final color = _colors[i % _colors.length];
            final isAttending = e.isAttending(userId);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _monthAbbr(e.eventDate.month),
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${e.eventDate.day}',
                          style: TextStyle(
                            fontSize: 20,
                            color: color,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${e.isVirtual ? "Virtual" : e.location} • ${_formatTime(e.eventDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${e.attendeeCount} attending',
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: userId.isEmpty
                        ? null
                        : () async {
                            if (isAttending) {
                              await repo.unattendEvent(e.id, userId);
                            } else {
                              await repo.attendEvent(e.id, userId);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAttending ? AppColors.border : color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isAttending ? 'Leave' : 'Join',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAttending
                            ? AppColors.textSecondary
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthAbbr(int m) => [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ][m - 1];
  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

// ── Mentorship Tab ─────────────────────────────────────────────────────────
class _MentorshipTab extends ConsumerWidget {
  const _MentorshipTab();

  static const _colors = [
    Color(0xFF7C3AED),
    Color(0xFF0369A1),
    AppColors.primary,
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.watch(communityRepositoryProvider).watchMentorshipPosts(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return _EmptyState(
            message: 'No mentors available yet.\nOffer your expertise!',
            icon: Icons.psychology_outlined,
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final color = _colors[i % _colors.length];
            final name = d['userName'] as String? ?? 'Unknown';
            final photo = d['userPhoto'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: color.withValues(alpha: 0.15),
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? Text(
                            name[0],
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          d['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if ((d['category'] as String? ?? '').isNotEmpty)
                          Text(
                            d['category'],
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/discover'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Connect',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Library Tab ────────────────────────────────────────────────────────────
class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  static const _categoryIcons = <String, IconData>{
    'Education': Icons.school_outlined,
    'Design': Icons.design_services_outlined,
    'Coding': Icons.code_outlined,
    'Gardening': Icons.eco_outlined,
    'Cooking': Icons.restaurant_outlined,
    'Music': Icons.music_note_outlined,
    'Photography': Icons.camera_alt_outlined,
    'Fitness': Icons.fitness_center_outlined,
    'Language': Icons.translate_outlined,
    'Technology': Icons.devices_outlined,
  };

  static const _categoryColors = <String, Color>{
    'Education': AppColors.primary,
    'Design': Color(0xFF7C3AED),
    'Coding': Color(0xFF0369A1),
    'Gardening': Color(0xFF16A34A),
    'Cooking': Color(0xFFDC2626),
    'Music': Color(0xFF7C3AED),
    'Photography': Color(0xFFB45309),
    'Fitness': Color(0xFF16A34A),
    'Language': Color(0xFF0369A1),
    'Technology': Color(0xFF0369A1),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.value?.uid ?? '';
    final selectedCategory = ref.watch(resourceCategoryProvider);
    final resourcesAsync = ref.watch(resourcesProvider);
    final repo = ref.watch(communityRepositoryProvider);

    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: ['All', ..._categoryIcons.keys].map((cat) {
              final active = cat == selectedCategory;
              return GestureDetector(
                onTap: () =>
                    ref.read(resourceCategoryProvider.notifier).state = cat,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: resourcesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (resources) {
              if (resources.isEmpty)
                return _EmptyState(
                  message: 'No resources yet.\nShare your knowledge!',
                  icon: Icons.menu_book_outlined,
                );
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: resources.length,
                itemBuilder: (_, i) {
                  final r = resources[i];
                  final icon =
                      _categoryIcons[r.category] ?? Icons.article_outlined;
                  final color =
                      _categoryColors[r.category] ?? AppColors.primary;
                  final isSaved = r.isSaved(userId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                r.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'by ${r.createdByName}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_outline,
                            color: isSaved
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: userId.isEmpty
                              ? null
                              : () async {
                                  if (isSaved) {
                                    await repo.unsaveResource(r.id, userId);
                                  } else {
                                    await repo.saveResource(r.id, userId);
                                  }
                                },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Shared post card ───────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String actionLabel;
  final VoidCallback onAction;
  const _PostCard({
    required this.data,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final photo = data['userPhoto'] as String?;
    final name = data['userName'] as String? ?? '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(
                        name[0],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if ((data['category'] as String? ?? '').isNotEmpty)
                SkillChip(label: data['category']),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['title'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if ((data['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data['description'],
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: Size.zero,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
