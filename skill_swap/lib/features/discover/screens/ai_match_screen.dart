import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/discover_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class AiMatchScreen extends ConsumerWidget {
  const AiMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(currentUserProvider).value;
    final matchesAsync = ref.watch(aiMatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('AI Skill Match'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(aiMatchesProvider))],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary))),
        data: (matches) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Perfect Connections', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Our AI analysed your profile to find your best matches.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              if (matches.isEmpty)
                const Center(child: Text('No matches yet. Complete your profile!', style: TextStyle(color: AppColors.textSecondary)))
              else ...[
                ...matches.take(3).toList().asMap().entries.map((e) => _FullMatchCard(user: e.value, viewer: viewer, isTop: e.key == 0)),
                const SizedBox(height: 20),
                SectionHeader(title: 'More Recommended', action: 'View all', onAction: () => Navigator.pushNamed(context, '/discover')),
                const SizedBox(height: 12),
                ...matches.skip(3).take(4).map((u) => _CompactMatchCard(user: u, viewer: viewer)),
                const SizedBox(height: 20),
                const _InsightsCard(),
                const SizedBox(height: 16),
                _StatsRow(matchCount: matches.length),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full match card ────────────────────────────────────────────────────────
class _FullMatchCard extends StatelessWidget {
  final UserModel user;
  final UserModel? viewer;
  final bool isTop;
  const _FullMatchCard({required this.user, required this.viewer, required this.isTop});

  @override
  Widget build(BuildContext context) {
    final score = viewer != null ? user.matchScore(viewer!) : 75;
    final reason = viewer != null ? user.matchReason(viewer!) : 'has complementary skills.';
    final sharedSkills = viewer != null ? user.skillsOffered.where((s) => viewer!.skillsWanted.contains(s)).toList() : <String>[];
    final theyWant = viewer != null ? user.skillsWanted.where((s) => viewer!.skillsOffered.contains(s)).toList() : <String>[];
    final sameLocation = viewer?.location != null && user.location == viewer!.location;
    final sameAvail = viewer?.availability.isNotEmpty == true && user.availability == viewer!.availability;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTop ? AppColors.primary : AppColors.border, width: isTop ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTop)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                    child: const Text('⭐ TOP MATCH', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      backgroundImage: avatarImageProvider(user.photoUrl),
                      child: user.photoUrl == null ? Text(user.displayName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          if (user.location != null) Text(user.location!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    MatchBadge(percent: score),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.tagBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('We found ${user.displayName.split(' ').first} because they $reason', style: const TextStyle(fontSize: 13, color: AppColors.tagText, height: 1.4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _MatchDetailRow(icon: Icons.school_outlined, label: 'They teach', value: sharedSkills.isEmpty ? 'No direct match' : sharedSkills.take(3).join(', '), highlight: sharedSkills.isNotEmpty),
                const SizedBox(height: 8),
                _MatchDetailRow(icon: Icons.favorite_outline, label: 'They want to learn', value: theyWant.isEmpty ? 'No direct match' : theyWant.take(3).join(', '), highlight: theyWant.isNotEmpty),
                const SizedBox(height: 8),
                _MatchDetailRow(icon: Icons.location_on_outlined, label: 'Location', value: sameLocation ? 'Same area ✓' : (user.location ?? 'Not specified'), highlight: sameLocation),
                const SizedBox(height: 8),
                _MatchDetailRow(icon: Icons.schedule_outlined, label: 'Availability', value: sameAvail ? '${user.availability} ✓' : (user.availability.isEmpty ? 'Not specified' : user.availability), highlight: sameAvail),
              ],
            ),
          ),
          if (sharedSkills.isNotEmpty || theyWant.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 Possible Collaboration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_buildCollabIdea(user, viewer, sharedSkills, theyWant), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/chat', arguments: user), child: const Text('Start Conversation'))),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/user-profile', arguments: user),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildCollabIdea(UserModel user, UserModel? viewer, List<String> sharedSkills, List<String> theyWant) {
    if (viewer == null) return 'You could exchange skills and grow together.';
    final teach = sharedSkills.isNotEmpty ? sharedSkills.first : null;
    final learn = theyWant.isNotEmpty ? theyWant.first : null;
    if (teach != null && learn != null) return '${user.displayName.split(' ').first} could teach you $teach while you teach them $learn — a perfect skill swap!';
    if (teach != null) return '${user.displayName.split(' ').first} could teach you $teach. You could offer something from your skill set in return.';
    if (learn != null) return 'You could teach ${user.displayName.split(' ').first} $learn and explore what they can offer you.';
    return 'You share similar interests — reach out and explore collaboration possibilities!';
  }
}

class _MatchDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  const _MatchDetailRow({required this.icon, required this.label, required this.value, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: highlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 6),
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: highlight ? FontWeight.w600 : FontWeight.normal, color: highlight ? AppColors.primary : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ── Compact match card ─────────────────────────────────────────────────────
class _CompactMatchCard extends StatelessWidget {
  final UserModel user;
  final UserModel? viewer;
  const _CompactMatchCard({required this.user, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final score = viewer != null ? user.matchScore(viewer!) : 70;
    final reason = viewer != null ? user.matchReason(viewer!) : 'has complementary skills.';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            backgroundImage: avatarImageProvider(user.photoUrl),
            child: user.photoUrl == null ? Text(user.displayName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  MatchBadge(percent: score),
                ]),
                Text('They $reason', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/user-profile', arguments: user),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), minimumSize: Size.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Insights card ──────────────────────────────────────────────────────────
class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.posts
          .where('type', isEqualTo: 'offer_skill')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (_, snap) {
        String trendingSkill = '';
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final counts = <String, int>{};
          for (final doc in snap.data!.docs) {
            final cat = (doc.data() as Map<String, dynamic>)['category'] as String? ?? '';
            if (cat.isNotEmpty) counts[cat] = (counts[cat] ?? 0) + 1;
          }
          if (counts.isNotEmpty) {
            trendingSkill = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
          }
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF78350F), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                SizedBox(width: 6),
                Text('Skill Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
              const SizedBox(height: 8),
              Text(
                trendingSkill.isNotEmpty
                    ? 'Trending in your community: $trendingSkill. Complete your profile with more skills to unlock personalised AI insights.'
                    : 'Complete your profile with more skills to unlock personalised AI insights about trending skills in your area.',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int matchCount;
  const _StatsRow({required this.matchCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.people, value: '$matchCount', label: 'Potential matches found')),
        const SizedBox(width: 12),
        const Expanded(child: _StatCard(icon: Icons.auto_awesome, value: 'AI', label: 'Powered matching engine')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    );
  }
}
