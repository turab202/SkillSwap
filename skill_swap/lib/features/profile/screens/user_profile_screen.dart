import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final meAsync = ref.watch(currentUserProvider);
    final me = meAsync.value;
    final user = (arg is UserModel) ? arg : me;
    final isOwnProfile = me?.uid == user?.uid;
    final showBottomNav = isOwnProfile && arg == null;

    if (meAsync.isLoading || (user == null && arg == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    void navigate(int i) {
      const routes = ['/home', '/discover', '/create', '/community', '/profile-view'];
      Navigator.pushReplacementNamed(context, routes[i]);
    }

    final body = CustomScrollView(
      slivers: [
        _ProfileAppBar(user: user, isOwnProfile: isOwnProfile),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOwnProfile) _ActionRow(user: user),
                if (!isOwnProfile) const SizedBox(height: 20),
                _CommunityImpactSection(user: user),
                const SizedBox(height: 20),
                _AppreciationSection(userId: user.uid),
                const SizedBox(height: 20),
                if (user.bio.isNotEmpty) ...[
                  const Text('About Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(user.bio, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                ],
                if (user.skillsOffered.isNotEmpty) ...[
                  const Text('SKILLS OFFERED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: user.skillsOffered.map((s) => SkillChip(label: s)).toList()),
                  const SizedBox(height: 16),
                ],
                if (user.skillsWanted.isNotEmpty) ...[
                  const Text('SKILLS WANTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: user.skillsWanted.map((s) => SkillChip(label: s, bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFF92400E))).toList()),
                  const SizedBox(height: 20),
                ],
                _ContributionHistory(userId: user.uid),
                const SizedBox(height: 20),
                _ReviewsSection(userId: user.uid),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );

    if (showBottomNav) {
      return AppScaffold(
        navIndex: 4,
        onNavTap: navigate,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: body,
    );
  }
}

class _ProfileAppBar extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;
  const _ProfileAppBar({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.accent], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            Positioned(
              bottom: 16,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: UserAvatar(
                      photoUrl: user.photoUrl,
                      displayName: user.displayName,
                      radius: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      if (user.location != null) Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Colors.white70), const SizedBox(width: 2), Text(user.location!, style: const TextStyle(color: Colors.white70, fontSize: 12))]),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(user.experienceLevel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isOwnProfile) TextButton(onPressed: () => Navigator.pushNamed(context, '/profile-setup'), child: const Text('Edit', style: TextStyle(color: Colors.white))),
        if (isOwnProfile)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Settings & Logout',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        if (!isOwnProfile)
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final UserModel user;
  const _ActionRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'user': user,
            'preset': 'Hi ${user.displayName}! I’d love to start a skill swap with you. What would you like to teach or learn?',
          },
        );
      },
      icon: const Icon(Icons.swap_horiz_outlined),
      label: const Text('Start Skill Swap'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CommunityImpactSection extends StatelessWidget {
  final UserModel user;
  const _CommunityImpactSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('People Helped', user.peopleHelped, Icons.volunteer_activism, AppColors.primary),
      ('Skills Shared', user.skillsShared, Icons.school_outlined, const Color(0xFF0369A1)),
      ('Projects Joined', user.projectsJoined, Icons.groups_outlined, const Color(0xFF7C3AED)),
      ('Mentorship', user.mentorshipSessions, Icons.psychology_outlined, const Color(0xFFB45309)),
      ('Volunteer', user.volunteerActivities, Icons.favorite_outline, const Color(0xFFDC2626)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Community Impact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: stats.map((s) => Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: s.$4.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: s.$4.withValues(alpha: 0.2))),
              child: Column(
                children: [
                  Icon(s.$3, color: s.$4, size: 18),
                  const SizedBox(height: 4),
                  Text('${s.$2}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: s.$4)),
                  Text(s.$1, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── Appreciation badges — live from Firestore ──────────────────────────────
class _AppreciationSection extends StatelessWidget {
  final String userId;
  const _AppreciationSection({required this.userId});

  static const _badgeIcons = {
    'Helpful': (Icons.volunteer_activism, Color(0xFF16A34A)),
    'Professional': (Icons.workspace_premium_outlined, Color(0xFF0369A1)),
    'Patient': (Icons.self_improvement_outlined, Color(0xFF7C3AED)),
    'Creative': (Icons.palette_outlined, Color(0xFFB45309)),
    'Reliable': (Icons.verified_outlined, Color(0xFF0369A1)),
    'Excellent Teacher': (Icons.school_outlined, AppColors.primary),
    'Supportive': (Icons.favorite_outline, Color(0xFFDC2626)),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Appreciation Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.appreciations.where('toUserId', isEqualTo: userId).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            if (snap.data!.docs.isEmpty) return const Text('No appreciations yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));

            final counts = <String, int>{};
            for (final doc in snap.data!.docs) {
              final badge = (doc.data() as Map<String, dynamic>)['badge'] as String? ?? '';
              counts[badge] = (counts[badge] ?? 0) + 1;
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: counts.entries.map((e) {
                final info = _badgeIcons[e.key] ?? (Icons.star_outline, AppColors.primary);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: info.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: info.$2.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.$1, size: 14, color: info.$2),
                      const SizedBox(width: 4),
                      Text(e.key, style: TextStyle(fontSize: 12, color: info.$2, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: info.$2, borderRadius: BorderRadius.circular(10)),
                        child: Text('${e.value}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
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

class _ContributionHistory extends StatelessWidget {
  final String userId;
  const _ContributionHistory({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contribution History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.posts.where('userId', isEqualTo: userId).limit(10).snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) return const Text('No contributions yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
            final docs = snap.data!.docs.toList()
              ..sort((a, b) {
                final aT = (a.data() as Map)['createdAt'];
                final bT = (b.data() as Map)['createdAt'];
                if (aT == null || bT == null) return 0;
                return (bT as dynamic).compareTo(aT);
              });
            return Column(
              children: docs.take(3).map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.tagBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.post_add_outlined, color: AppColors.primary, size: 18),
                  ),
                  title: Text(d['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text(d['type']?.toString().replaceAll('_', ' ') ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Reviews — live from appreciations with notes ───────────────────────────
class _ReviewsSection extends StatelessWidget {
  final String userId;
  const _ReviewsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService.appreciations
              .where('toUserId', isEqualTo: userId)
              .limit(20)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            final docs = snap.data!.docs.where((d) {
              final note = (d.data() as Map<String, dynamic>)['note'] as String?;
              return note != null && note.trim().isNotEmpty;
            }).toList()
              ..sort((a, b) {
                final aT = (a.data() as Map)['createdAt'];
                final bT = (b.data() as Map)['createdAt'];
                if (aT == null || bT == null) return 0;
                return (bT as dynamic).compareTo(aT);
              });
            final limited = docs.take(5).toList();
            if (limited.isEmpty) return const Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
            return Column(
              children: limited.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final note = d['note'] as String? ?? '';
                final badge = d['badge'] as String? ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('"', style: TextStyle(fontSize: 24, color: AppColors.accent, height: 0.8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(note, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                            if (badge.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              SkillChip(label: badge),
                            ],
                          ],
                        ),
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
