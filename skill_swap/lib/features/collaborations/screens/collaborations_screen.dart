import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/collaboration_model.dart';
import '../repositories/collaboration_repository.dart';
import '../../home/providers/home_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class CollaborationsScreen extends ConsumerStatefulWidget {
  const CollaborationsScreen({super.key});
  @override
  ConsumerState<CollaborationsScreen> createState() => _CollaborationsScreenState();
}

class _CollaborationsScreenState extends ConsumerState<CollaborationsScreen>
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

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider).value?.uid ?? '';
    final repo = ref.watch(collaborationRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('My Collaborations'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<CollaborationModel>>(
        stream: repo.watchUserCollaborations(userId),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final all = snap.data!;
          return TabBarView(
            controller: _tab,
            children: [
              _CollabList(items: all.where((c) => c.status == CollaborationStatus.pending).toList(), userId: userId, repo: repo, emptyMsg: 'No pending requests'),
              _CollabList(items: all.where((c) => c.status == CollaborationStatus.accepted).toList(), userId: userId, repo: repo, emptyMsg: 'No accepted collaborations'),
              _CollabList(items: all.where((c) => c.status == CollaborationStatus.inProgress).toList(), userId: userId, repo: repo, emptyMsg: 'No active collaborations'),
              _CollabList(items: all.where((c) => c.status == CollaborationStatus.completed).toList(), userId: userId, repo: repo, emptyMsg: 'No completed collaborations yet'),
              _CollabList(items: all.where((c) => c.status == CollaborationStatus.cancelled).toList(), userId: userId, repo: repo, emptyMsg: 'No history'),
            ],
          );
        },
      ),
    );
  }
}

class _CollabList extends StatelessWidget {
  final List<CollaborationModel> items;
  final String userId;
  final CollaborationRepository repo;
  final String emptyMsg;
  const _CollabList({required this.items, required this.userId, required this.repo, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text(emptyMsg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/discover'), child: const Text('Find people to collaborate with')),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CollabCard(collab: items[i], userId: userId, repo: repo),
    );
  }
}

class _CollabCard extends StatelessWidget {
  final CollaborationModel collab;
  final String userId;
  final CollaborationRepository repo;
  const _CollabCard({required this.collab, required this.userId, required this.repo});

  bool get _isRequester => collab.requesterId == userId;
  String get _otherName => _isRequester ? collab.targetName : collab.requesterName;
  String? get _otherPhoto => _isRequester ? collab.targetPhoto : collab.requesterPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                backgroundImage: avatarImageProvider(_otherPhoto),
                child: _otherPhoto == null ? Text(_otherName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_otherName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('${collab.skillOffered} ↔ ${collab.skillWanted}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StatusChip(status: collab.status),
            ],
          ),
          if (collab.message != null && collab.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
              child: Text(collab.message!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
            ),
          ],
          if (collab.scheduledAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('Scheduled: ${_formatDate(collab.scheduledAt!)}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _ActionButtons(collab: collab, isRequester: _isRequester, repo: repo),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} at ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _ActionButtons extends ConsumerWidget {
  final CollaborationModel collab;
  final bool isRequester;
  final CollaborationRepository repo;
  const _ActionButtons({required this.collab, required this.isRequester, required this.repo});

  void _showAppreciationDialog(BuildContext context, WidgetRef ref) {
    const badges = ['Helpful', 'Professional', 'Patient', 'Creative', 'Reliable', 'Excellent Teacher', 'Supportive'];
    final me = ref.read(currentUserProvider).value;
    if (me == null) return;
    final otherId = isRequester ? collab.targetId : collab.requesterId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Appreciation'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((b) => GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              await FirestoreService.sendAppreciation(
                fromUserId: me.uid,
                toUserId: otherId,
                badge: b,
              );
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Appreciation "$b" sent!')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(20)),
              child: Text(b, style: const TextStyle(fontSize: 13, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500)),
            ),
          )).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (collab.status) {
      CollaborationStatus.pending => !isRequester
          ? Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () => repo.updateStatus(collab.id, CollaborationStatus.accepted),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Accept', style: TextStyle(color: Colors.white)),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: () => repo.updateStatus(collab.id, CollaborationStatus.cancelled),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Decline'),
              )),
            ])
          : Text('Waiting for ${collab.targetName} to respond...', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      CollaborationStatus.accepted => Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => repo.updateStatus(collab.id, CollaborationStatus.inProgress),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0369A1), minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Start', style: TextStyle(color: Colors.white)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Message'),
          )),
        ]),
      CollaborationStatus.inProgress => Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => repo.updateStatus(collab.id, CollaborationStatus.completed),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.matchHigh, minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/chat'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Message'),
          )),
        ]),
      CollaborationStatus.completed => ElevatedButton(
          onPressed: () => _showAppreciationDialog(context, ref),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Leave Appreciation', style: TextStyle(color: Colors.white)),
        ),
      CollaborationStatus.cancelled => const Text('Collaboration cancelled', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    };
  }
}

class _StatusChip extends StatelessWidget {
  final CollaborationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CollaborationStatus.pending => ('Pending', AppColors.matchMed),
      CollaborationStatus.accepted => ('Accepted', AppColors.primary),
      CollaborationStatus.inProgress => ('In Progress', const Color(0xFF0369A1)),
      CollaborationStatus.completed => ('Completed', AppColors.matchHigh),
      CollaborationStatus.cancelled => ('Cancelled', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
