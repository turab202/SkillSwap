import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../collaborations/models/collaboration_model.dart';
import '../providers/home_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../notifications/providers/notification_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final impactAsync = ref.watch(dailyImpactProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return AppScaffold(
      navIndex: 0,
      onNavTap: _navigate,
      appBar: AppBar(
        title: const Text('Skill Swap'),
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
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dailyImpactProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(user: user),
              const SizedBox(height: 16),
              _CommunityImpactSection(impactAsync: impactAsync),
              const SizedBox(height: 20),
              _ContinueCollaboratingSection(userId: user?.uid ?? ''),
              const SizedBox(height: 20),
              _RecommendedSection(viewer: user),
              const SizedBox(height: 20),
              const _HelpRequestsSection(),
              const SizedBox(height: 20),
              const _CommunityPulse(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      fab: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Welcome ────────────────────────────────────────────────────────────────
class _WelcomeHeader extends StatelessWidget {
  final UserModel? user;
  const _WelcomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${user?.displayName.split(' ').first ?? 'there'}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ready to grow your skills?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/collaborations'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tagBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                SizedBox(width: 4),
                Text(
                  'My Collabs',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Community Impact ───────────────────────────────────────────────────────
class _CommunityImpactSection extends StatelessWidget {
  final AsyncValue<Map<String, int>> impactAsync;
  const _CommunityImpactSection({required this.impactAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMUNITY IMPACT TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        impactAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (impact) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _ImpactTile(
                icon: Icons.volunteer_activism,
                label: 'People Helped',
                value: impact['peopleHelped'] ?? 0,
                color: AppColors.primary,
              ),
              _ImpactTile(
                icon: Icons.school_outlined,
                label: 'Skills Shared',
                value: impact['skillsShared'] ?? 0,
                color: const Color(0xFF0369A1),
              ),
              _ImpactTile(
                icon: Icons.handshake_outlined,
                label: 'Active Collabs',
                value: impact['activeCollaborations'] ?? 0,
                color: const Color(0xFF7C3AED),
              ),
              _ImpactTile(
                icon: Icons.groups_outlined,
                label: 'Projects',
                value: impact['communityProjects'] ?? 0,
                color: const Color(0xFFB45309),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _ImpactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Continue Collaborating ─────────────────────────────────────────────────
class _ContinueCollaboratingSection extends ConsumerWidget {
  final String userId;
  const _ContinueCollaboratingSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();
    final repo = ref.watch(collaborationRepositoryProvider);
    return StreamBuilder<List<CollaborationModel>>(
      stream: repo.watchUserCollaborations(userId),
      builder: (_, snap) {
        final active = (snap.data ?? [])
            .where(
              (c) =>
                  c.status == CollaborationStatus.inProgress ||
                  c.status == CollaborationStatus.accepted,
            )
            .take(3)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Continue Collaborating',
              action: 'View all',
              onAction: () => Navigator.pushNamed(context, '/collaborations'),
            ),
            const SizedBox(height: 10),
            ...active.map((c) => _CollabTile(collab: c, userId: userId)),
          ],
        );
      },
    );
  }
}

class _CollabTile extends StatelessWidget {
  final CollaborationModel collab;
  final String userId;
  const _CollabTile({required this.collab, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isRequester = collab.requesterId == userId;
    final otherName = isRequester ? collab.targetName : collab.requesterName;
    final otherPhoto = isRequester ? collab.targetPhoto : collab.requesterPhoto;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            backgroundImage: otherPhoto != null
                ? avatarImageProvider(otherPhoto)
                : null,
            child: otherPhoto == null
                ? Text(
                    otherName[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${collab.skillOffered} ↔ ${collab.skillWanted}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: collab.status),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/collaborations'),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CollaborationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CollaborationStatus.pending => ('Pending', AppColors.matchMed),
      CollaborationStatus.accepted => ('Accepted', AppColors.primary),
      CollaborationStatus.inProgress => (
        'In Progress',
        const Color(0xFF0369A1),
      ),
      CollaborationStatus.completed => ('Done', AppColors.matchHigh),
      CollaborationStatus.cancelled => ('Cancelled', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Recommended ────────────────────────────────────────────────────────────
class _RecommendedSection extends ConsumerWidget {
  final UserModel? viewer;
  const _RecommendedSection({required this.viewer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(recommendedMatchesProvider);
    return Column(
      children: [
        SectionHeader(
          title: 'Recommended for You',
          action: 'See all',
          onAction: () => Navigator.pushNamed(context, '/discover'),
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (matches) {
            if (matches.isEmpty) {
              return const Text(
                'No matches yet. Complete your profile!',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            final filtered = viewer != null
                ? matches.where((u) => u.uid != viewer!.uid).toList()
                : matches;
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filtered.take(6).length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _RecommendCard(user: filtered[i], viewer: viewer),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final UserModel user;
  final UserModel? viewer;
  const _RecommendCard({required this.user, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final score = viewer != null ? user.matchScore(viewer!) : 75;
    final reason = viewer != null
        ? user.matchReason(viewer!)
        : 'has complementary skills.';
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/user-profile', arguments: user),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  backgroundImage: user.photoUrl != null
                      ? avatarImageProvider(user.photoUrl)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName[0],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                MatchBadge(percent: score),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.location != null)
              Text(
                user.location!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.tagBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'We found ${user.displayName.split(' ').first} because they $reason',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.tagText,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
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

// ── Help Requests ──────────────────────────────────────────────────────────
class _HelpRequestsSection extends ConsumerWidget {
  const _HelpRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(helpRequestsProvider);
    return Column(
      children: [
        SectionHeader(
          title: 'Help Requests nearby',
          action: 'View map',
          onAction: () => Navigator.pushNamed(context, '/discover'),
        ),
        const SizedBox(height: 12),
        snap.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const SizedBox.shrink(),
          data: (snapshot) {
            final docs = snapshot.docs;
            if (docs.isEmpty) {
              return const Text(
                'No help requests nearby yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final createdAt = (d['createdAt'] as Timestamp?)?.toDate();
                final dateLabel = createdAt != null
                    ? timeago.format(createdAt, locale: 'en_short')
                    : '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tagBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              d['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Community Pulse ────────────────────────────────────────────────────────
class _CommunityPulse extends ConsumerWidget {
  const _CommunityPulse();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulseSnap = ref.watch(communityPulseProvider);
    final newMembersAsync = ref.watch(newMembersTodayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Pulse',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        pulseSnap.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (snapshot) {
            if (snapshot.docs.isEmpty) return const SizedBox.shrink();
            final d = snapshot.docs.first.data() as Map<String, dynamic>;
            final title = d['title'] as String? ?? '';
            final desc = d['description'] as String? ?? '';
            final userName = d['userName'] as String? ?? 'Community';
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LATEST FROM $userName'.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    newMembersAsync.when(
                      loading: () => const Text(
                        '...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      error: (_, __) => const Text(
                        '0',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      data: (count) => Text(
                        '$count New Members',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Text(
                      'joined the community today.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tagBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Consumer(
                      builder: (_, ref, __) {
                        final latestAsync = ref.watch(
                          latestCompletedCollabProvider,
                        );
                        return latestAsync.when(
                          loading: () => const Text(
                            '...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (name) => Text(
                            name.isEmpty ? 'Skill Swap!' : 'Level Up!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (_, ref, __) {
                        final latestAsync = ref.watch(
                          latestCompletedCollabProvider,
                        );
                        return latestAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (name) => Text(
                            name.isEmpty
                                ? 'Be the first to complete a swap!'
                                : '$name just completed a skill swap!',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
