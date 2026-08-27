import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_scaffold.dart';

enum PostType { offerSkill, offerService, requestHelp, communityProject, volunteer, mentorship }

extension PostTypeX on PostType {
  String get label => switch (this) {
        PostType.offerSkill => 'Offer a Skill',
        PostType.offerService => 'Offer a Service',
        PostType.requestHelp => 'Request Help',
        PostType.communityProject => 'Community Project',
        PostType.volunteer => 'Volunteer',
        PostType.mentorship => 'Mentorship',
      };
  String get firestoreValue => switch (this) {
        PostType.offerSkill => 'offer_skill',
        PostType.offerService => 'offer_service',
        PostType.requestHelp => 'request_help',
        PostType.communityProject => 'community_project',
        PostType.volunteer => 'volunteer',
        PostType.mentorship => 'mentorship',
      };
  IconData get icon => switch (this) {
        PostType.offerSkill => Icons.school_outlined,
        PostType.offerService => Icons.build_outlined,
        PostType.requestHelp => Icons.help_outline,
        PostType.communityProject => Icons.groups_outlined,
        PostType.volunteer => Icons.volunteer_activism,
        PostType.mentorship => Icons.psychology_outlined,
      };
  Color get color => switch (this) {
        PostType.offerSkill => AppColors.primary,
        PostType.offerService => const Color(0xFF0369A1),
        PostType.requestHelp => const Color(0xFFB45309),
        PostType.communityProject => const Color(0xFF7C3AED),
        PostType.volunteer => const Color(0xFF16A34A),
        PostType.mentorship => const Color(0xFFDC2626),
      };
  String get titleHint => switch (this) {
        PostType.offerSkill => 'e.g., I can teach Flutter development',
        PostType.offerService => 'e.g., I offer graphic design services',
        PostType.requestHelp => 'e.g., Looking for help with my garden',
        PostType.communityProject => 'e.g., Community Garden Cleanup Project',
        PostType.volunteer => 'e.g., Help needed at local food bank',
        PostType.mentorship => 'e.g., Offering mentorship in UX Design',
      };
  String get descHint => switch (this) {
        PostType.offerSkill => 'Describe what you\'ll teach, your experience, and what you\'d like in return...',
        PostType.offerService => 'Describe the service, your experience, and what you\'d like in return...',
        PostType.requestHelp => 'Describe what you need, your timeline, and what you can offer in return...',
        PostType.communityProject => 'Describe the project goals, skills needed, and how people can contribute...',
        PostType.volunteer => 'Describe the volunteer opportunity, time commitment, and impact...',
        PostType.mentorship => 'Describe your expertise, mentorship style, and what mentees can expect...',
      };
}

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});
  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  PostType _type = PostType.offerSkill;
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _locationC = TextEditingController();
  String _category = 'Education';
  bool _loading = false;

  static const _categories = ['Education', 'Design', 'Cooking', 'Gardening', 'Fitness', 'Coding', 'Music', 'Language', 'Crafts', 'Technology'];

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _locationC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider).value!;
    final extra = (_type == PostType.offerService || _type == PostType.communityProject || _type == PostType.volunteer)
        ? {'location': _locationC.text.trim()}
        : <String, dynamic>{};
    await FirestoreService.posts.add({
      'title': _titleC.text.trim(),
      'description': _descC.text.trim(),
      'category': _category,
      'type': _type.firestoreValue,
      'userId': user.uid,
      'userName': user.displayName,
      'userPhoto': user.photoUrl,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      ...extra,
    });
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _navigate(int i) {
    const routes = ['/home', '/discover', '/create', '/community', '/profile-view'];
    Navigator.pushReplacementNamed(context, routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      navIndex: 2,
      onNavTap: _navigate,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text('Create Post'),
        actions: [TextButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Posting...' : 'Post', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('POST TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            _TypeSelector(selected: _type, onSelect: (t) => setState(() { _type = t; _titleC.clear(); _descC.clear(); })),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.tagBg, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(child: Text('AI Tip: Be specific about what you offer and what you\'d like in return to get better matches.', style: TextStyle(fontSize: 12, color: AppColors.tagText, height: 1.4))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('TITLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleC,
              decoration: InputDecoration(hintText: _type.titleHint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
            ),
            const SizedBox(height: 16),
            const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descC,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: _type.descHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            if (_type == PostType.offerService || _type == PostType.communityProject || _type == PostType.volunteer) ...[
              const SizedBox(height: 16),
              const Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationC,
                decoration: InputDecoration(
                  hintText: 'Neighborhood or city',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final active = c == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: active ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? AppColors.primary : AppColors.border)),
                    child: Text(c, style: TextStyle(fontSize: 13, color: active ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            AppButton(label: 'Post', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final PostType selected;
  final void Function(PostType) onSelect;
  const _TypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: PostType.values.map((t) {
        final active = t == selected;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? t.color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? t.color : AppColors.border, width: active ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(t.icon, color: active ? t.color : AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(t.label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: active ? t.color : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
