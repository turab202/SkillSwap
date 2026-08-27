import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../community/providers/community_providers.dart';
import '../providers/discover_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../notifications/providers/notification_providers.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
      navIndex: 1,
      onNavTap: _navigate,
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
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
            Tab(text: 'People'),
            Tab(text: 'Skills'),
            Tab(text: 'Services'),
            Tab(text: 'Projects'),
            Tab(text: 'Communities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _PeopleTab(),
          _SkillsTab(),
          _ServicesTab(),
          _ProjectsTab(),
          _CommunitiesTab(),
        ],
      ),
    );
  }
}

// ── Shared filter bar ──────────────────────────────────────────────────────
class _SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSearch;
  final List<_FilterOption> filters;

  const _SearchFilterBar({
    required this.controller,
    required this.hint,
    required this.onSearch,
    this.filters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        controller.clear();
                        onSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _FilterPill(option: filters[i]),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FilterOption {
  final String label;
  final VoidCallback onTap;
  const _FilterOption(this.label, this.onTap);
}

class _FilterPill extends StatelessWidget {
  final _FilterOption option;
  const _FilterPill({required this.option});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          option.label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── People Tab ─────────────────────────────────────────────────────────────
class _PeopleTab extends ConsumerStatefulWidget {
  const _PeopleTab();
  @override
  ConsumerState<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends ConsumerState<_PeopleTab> {
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(discoverSearchQueryProvider.notifier).state = _searchC.text.trim();
    ref.read(discoverSkillFilterProvider.notifier).state = 'All';
  }

  @override
  Widget build(BuildContext context) {
    final viewer = ref.watch(currentUserProvider).value;
    final usersAsync = ref.watch(discoverPeopleProvider);

    return Column(
      children: [
        _SearchFilterBar(
          controller: _searchC,
          hint: 'Search people by skill or name...',
          onSearch: _search,
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            data: (users) {
              final filtered = viewer != null
                  ? users.where((u) => u.uid != viewer.uid).toList()
                  : users;
              if (filtered.isEmpty)
                return const Center(
                  child: Text(
                    'No people found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _PersonCard(user: filtered[i], viewer: viewer),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final UserModel user;
  final UserModel? viewer;
  const _PersonCard({required this.user, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final score = viewer != null ? user.matchScore(viewer!) : 0;
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/user-profile', arguments: user),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              backgroundImage: user.photoUrl != null
                  ? avatarImageProvider(user.photoUrl)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.displayName[0],
                      style: const TextStyle(
                        color: AppColors.primary,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (score > 0) MatchBadge(percent: score),
                    ],
                  ),
                  if (user.location != null)
                    Text(
                      user.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (user.skillsOffered.isNotEmpty) ...[
                    const Text(
                      'Teaches',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: user.skillsOffered
                          .take(3)
                          .map((s) => SkillChip(label: s))
                          .toList(),
                    ),
                  ],
                  if (user.skillsWanted.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Wants to learn',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Wrap(
                      spacing: 4,
                      children: user.skillsWanted
                          .take(2)
                          .map(
                            (s) => SkillChip(
                              label: s,
                              bgColor: const Color(0xFFFEF3C7),
                              textColor: const Color(0xFF92400E),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: user,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Connect',
                            style: TextStyle(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: user,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Message',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skills Tab — live from posts collection ────────────────────────────────
class _SkillsTab extends ConsumerStatefulWidget {
  const _SkillsTab();
  @override
  ConsumerState<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends ConsumerState<_SkillsTab> {
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  static const _categoryColors = <String, Color>{
    'Design': Color(0xFF7C3AED),
    'Coding': Color(0xFF0369A1),
    'Photography': Color(0xFFB45309),
    'Cooking': Color(0xFFDC2626),
    'Gardening': Color(0xFF16A34A),
    'Music': Color(0xFF7C3AED),
    'Language': Color(0xFF0369A1),
    'Fitness': Color(0xFF16A34A),
    'Technology': Color(0xFF0369A1),
    'Education': AppColors.primary,
  };

  static const _categoryIcons = <String, IconData>{
    'Design': Icons.design_services,
    'Coding': Icons.phone_android,
    'Photography': Icons.camera_alt_outlined,
    'Cooking': Icons.restaurant_outlined,
    'Gardening': Icons.eco_outlined,
    'Music': Icons.music_note_outlined,
    'Language': Icons.translate_outlined,
    'Fitness': Icons.self_improvement_outlined,
    'Technology': Icons.devices_outlined,
    'Education': Icons.school_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.posts
          .where('type', isEqualTo: 'offer_skill')
          .limit(30)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;

        // Aggregate unique categories from real posts
        final categoryMap = <String, int>{};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final cat = d['category'] as String? ?? 'Other';
          categoryMap[cat] = (categoryMap[cat] ?? 0) + 1;
        }

        if (categoryMap.isEmpty) {
          return const Center(
            child: Text(
              'No skills posted yet.\nBe the first!',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        final categories = categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          children: [
            _SearchFilterBar(
              controller: _searchC,
              hint: 'Search skills...',
              onSearch: () {},
              filters: [
                _FilterOption('Category ▾', () {}),
                _FilterOption('Level ▾', () {}),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final cat = categories[i].key;
                  final count = categories[i].value;
                  final color = _categoryColors[cat] ?? AppColors.primary;
                  final icon = _categoryIcons[cat] ?? Icons.star_outline;
                  return GestureDetector(
                    onTap: () {
                      ref.read(discoverSkillFilterProvider.notifier).state =
                          cat;
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color, size: 28),
                          const Spacer(),
                          Text(
                            cat,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                          Text(
                            '$count offer${count == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Services Tab ───────────────────────────────────────────────────────────
class _ServicesTab extends ConsumerStatefulWidget {
  const _ServicesTab();
  @override
  ConsumerState<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<_ServicesTab> {
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchFilterBar(
          controller: _searchC,
          hint: 'Search services...',
          onSearch: () {},
          filters: [
            _FilterOption('Location ▾', () {}),
            _FilterOption('Availability ▾', () {}),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.posts
                .where('type', isEqualTo: 'offer_service')
                .limit(20)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty)
                return const Center(
                  child: Text(
                    'No services posted yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _PostCard(data: docs[i].data() as Map<String, dynamic>),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Projects Tab ───────────────────────────────────────────────────────────
class _ProjectsTab extends ConsumerStatefulWidget {
  const _ProjectsTab();
  @override
  ConsumerState<_ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends ConsumerState<_ProjectsTab> {
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchFilterBar(
          controller: _searchC,
          hint: 'Search community projects...',
          onSearch: () {},
          filters: [
            _FilterOption('Category ▾', () {}),
            _FilterOption('Status ▾', () {}),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.posts
                .where('type', isEqualTo: 'community_project')
                .limit(20)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty)
                return const Center(
                  child: Text(
                    'No projects yet. Create one!',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _PostCard(
                  id: docs[i].id,
                  data: docs[i].data() as Map<String, dynamic>,
                  isProject: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Communities Tab — live from Firestore ──────────────────────────────────
class _CommunitiesTab extends ConsumerStatefulWidget {
  const _CommunitiesTab();
  @override
  ConsumerState<_CommunitiesTab> createState() => _CommunitiesTabState();
}

class _CommunitiesTabState extends ConsumerState<_CommunitiesTab> {
  final _searchC = TextEditingController();

  static const _colors = [
    Color(0xFF0369A1),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFFB45309),
    AppColors.primary,
  ];

  static const _icons = [
    Icons.phone_android,
    Icons.eco_outlined,
    Icons.edit_outlined,
    Icons.restaurant_outlined,
    Icons.translate_outlined,
    Icons.people_outline,
  ];

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final userId = userAsync.value?.uid ?? '';
    final allAsync = ref.watch(allCommunitiesProvider);
    final repo = ref.watch(communityRepositoryProvider);

    return Column(
      children: [
        _SearchFilterBar(
          controller: _searchC,
          hint: 'Search communities...',
          onSearch: () {},
        ),
        Expanded(
          child: allAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (communities) {
              if (communities.isEmpty) {
                return const Center(
                  child: Text(
                    'No communities yet.\nCreate one!',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: communities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = communities[i];
                  final color = _colors[i % _colors.length];
                  final icon = _icons[i % _icons.length];
                  final isMember = c.isMember(userId);
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${c.memberCount} members',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                            backgroundColor: isMember
                                ? AppColors.border
                                : AppColors.primary,
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
          ),
        ),
      ],
    );
  }
}

// ── Shared post card ───────────────────────────────────────────────────────
class _PostCard extends ConsumerWidget {
  final String? id;
  final Map<String, dynamic> data;
  final bool isProject;
  const _PostCard({this.id, required this.data, this.isProject = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = data['userPhoto'] as String?;
    final name = data['userName'] as String? ?? '?';
    final userId = ref.watch(authRepositoryProvider).currentFirebaseUser?.uid;
    final participants = List<String>.from(data['participantIds'] ?? const []);
    final isJoined = userId != null && participants.contains(userId);
    return Container(
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
                backgroundImage: avatarImageProvider(photo),
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
          SizedBox(
            width: isProject ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: isProject && id != null && userId != null && !isJoined
                  ? () async {
                      await FirestoreService.posts.doc(id).update({
                        'participantIds': FieldValue.arrayUnion([userId]),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You joined this project.'),
                          ),
                        );
                      }
                    }
                  : isProject
                  ? null
                  : () {},
              icon: Icon(
                isProject && isJoined
                    ? Icons.check_circle_outline
                    : isProject
                    ? Icons.group_add_outlined
                    : Icons.chat_bubble_outline,
                size: 18,
              ),
              label: Text(
                isProject ? (isJoined ? 'Joined' : 'Join Project') : 'Connect',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isJoined ? AppColors.tagBg : AppColors.primary,
                foregroundColor: isJoined ? AppColors.tagText : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: isJoined ? 0 : 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
