import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../collaborations/models/collaboration_model.dart';
import '../../collaborations/repositories/collaboration_repository.dart';
import '../providers/chat_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgC = TextEditingController();
  final _scroll = ScrollController();
  final _collabRepo = CollaborationRepository();
  late String _chatId;
  UserModel? _other;
  String? _initialPreset;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final me = ref.read(currentUserProvider).value?.uid;
    if (me == null) return;

    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is Map) {
      final user = arg['user'];
      final preset = arg['preset'] as String?;
      if (user is UserModel) {
        _other = user;
        _initialPreset = preset;
        final ids = [me, _other!.uid]..sort();
        _chatId = ids.join('_');
        return;
      }
    }

    if (arg is UserModel) {
      _other = arg;
      final ids = [me, _other!.uid]..sort();
      _chatId = ids.join('_');
      return;
    }

    if (arg is String && arg.isNotEmpty) {
      final ids = [me, arg]..sort();
      _chatId = ids.join('_');

      Future.microtask(() async {
        final fetched = await ref.read(profileRepositoryProvider).getUser(arg);
        if (!mounted) return;
        setState(() {
          _other = fetched;
        });
      });
      return;
    }

    _chatId = '${me}_unknown';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialPreset != null && _initialPreset!.trim().isNotEmpty) {
        _msgC.text = _initialPreset!;
      }
    });
  }

  @override
  void dispose() {
    _msgC.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    final me = ref.read(currentUserProvider).value!;
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(
          chatId: _chatId,
          senderId: me.uid,
          senderName: me.displayName,
          senderPhoto: me.photoUrl,
          text: text,
          otherUserId: _other?.uid ?? '',
          otherUserName: _other?.displayName ?? '',
          otherUserPhoto: _other?.photoUrl,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients)
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
    });
  }

  void _showQuickActions() {
    final me = ref.read(currentUserProvider).value!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickActionsSheet(
        onScheduleMeeting: () {
          Navigator.pop(context);
          _send('📅 I\'d like to schedule a meeting. When are you available?');
        },
        onStartCollab: () async {
          Navigator.pop(context);
          if (_other == null) return;
          final collab = CollaborationModel(
            id: '',
            requesterId: me.uid,
            requesterName: me.displayName,
            requesterPhoto: me.photoUrl,
            targetId: _other!.uid,
            targetName: _other!.displayName,
            targetPhoto: _other!.photoUrl,
            skillOffered: me.skillsOffered.isNotEmpty
                ? me.skillsOffered.first
                : 'Skill',
            skillWanted: _other!.skillsOffered.isNotEmpty
                ? _other!.skillsOffered.first
                : 'Skill',
            status: CollaborationStatus.pending,
            createdAt: DateTime.now(),
          );
          await _collabRepo.createCollaboration(collab);
          await _send(
            '🤝 I\'ve sent you a collaboration request! Let\'s work together.',
          );
        },
        onCompleteCollab: () {
          Navigator.pop(context);
          _send(
            '✅ I\'d like to mark our collaboration as complete. Thank you for the exchange!',
          );
        },
        onAppreciate: () {
          Navigator.pop(context);
          _showAppreciationDialog(me);
        },
        onCreateTask: () {
          Navigator.pop(context);
          _send('📋 Let\'s create a shared task list for our collaboration.');
        },
      ),
    );
  }

  void _showAppreciationDialog(UserModel me) {
    const badges = [
      'Helpful',
      'Professional',
      'Patient',
      'Creative',
      'Reliable',
      'Excellent Teacher',
      'Supportive',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Appreciation'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges
              .map(
                (b) => GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (_other == null) return;
                    await FirestoreService.sendAppreciation(
                      fromUserId: me.uid,
                      toUserId: _other!.uid,
                      badge: b,
                    );
                    await _send(
                      '🏅 I left you an appreciation badge: "$b". Thank you!',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.tagText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider).value!.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              backgroundImage: avatarImageProvider(_other?.photoUrl),
              child: _other?.photoUrl == null
                  ? Text(
                      _other?.displayName[0] ?? '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _other?.displayName ?? 'Chat',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Active now',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined),
            onPressed: _showQuickActions,
            tooltip: 'Quick Actions',
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!.docs;
                if (msgs.isEmpty)
                  return _EmptyChat(otherName: _other?.displayName ?? '');
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final d = msgs[i].data() as Map<String, dynamic>;
                    final isMe = d['senderId'] == me;
                    return _Bubble(
                      text: d['text'] ?? '',
                      isMe: isMe,
                      time: d['createdAt'] != null
                          ? (d['createdAt'] as Timestamp).toDate()
                          : DateTime.now(),
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _msgC,
            onSend: () => _send(),
            onQuickActions: _showQuickActions,
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String otherName;
  const _EmptyChat({required this.otherName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation with $otherName',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use ⚡ Quick Actions to schedule a meeting\nor start a collaboration.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime time;
  const _Bubble({required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onQuickActions;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onQuickActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined, color: AppColors.primary),
            onPressed: onQuickActions,
            tooltip: 'Quick Actions',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  final VoidCallback onScheduleMeeting;
  final VoidCallback onStartCollab;
  final VoidCallback onCompleteCollab;
  final VoidCallback onAppreciate;
  final VoidCallback onCreateTask;

  const _QuickActionsSheet({
    required this.onScheduleMeeting,
    required this.onStartCollab,
    required this.onCompleteCollab,
    required this.onAppreciate,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.calendar_today_outlined,
        'Schedule Meeting',
        'Pick a time to meet',
        AppColors.primary,
        onScheduleMeeting,
      ),
      (
        Icons.handshake_outlined,
        'Start Collaboration',
        'Send a collaboration request',
        const Color(0xFF0369A1),
        onStartCollab,
      ),
      (
        Icons.check_circle_outline,
        'Complete Collaboration',
        'Mark as done',
        const Color(0xFF16A34A),
        onCompleteCollab,
      ),
      (
        Icons.favorite_outline,
        'Leave Appreciation',
        'Send an appreciation badge',
        const Color(0xFF7C3AED),
        onAppreciate,
      ),
      (
        Icons.checklist_outlined,
        'Create Shared Task',
        'Build a task list together',
        const Color(0xFFB45309),
        onCreateTask,
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...actions.map(
            (a) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: a.$4.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.$1, color: a.$4, size: 20),
              ),
              title: Text(
                a.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                a.$3,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: a.$5,
            ),
          ),
        ],
      ),
    );
  }
}
