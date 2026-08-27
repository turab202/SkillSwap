import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/utils/validators.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _locationC = TextEditingController();
  final _bioC = TextEditingController();
  final _skillOfferC = TextEditingController();
  final _skillWantC = TextEditingController();

  final List<String> _skillsOffered = [];
  final List<String> _skillsWanted = [];
  String _experience = 'Novice';
  String _availability = 'Weekends, Evenings';
  File? _photo;

  static const _availabilities = [
    'Weekdays',
    'Weekends',
    'Evenings',
    'Weekends, Evenings',
    'Flexible',
  ];

  @override
  void dispose() {
    _nameC.dispose();
    _locationC.dispose();
    _bioC.dispose();
    _skillOfferC.dispose();
    _skillWantC.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameC.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _addSkill(List<String> list, TextEditingController c) {
    final v = c.text.trim();
    if (v.isNotEmpty && !list.contains(v)) {
      setState(() => list.add(v));
      c.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(profileNotifierProvider.notifier)
        .saveProfile(
          name: _nameC.text.trim(),
          location: _locationC.text.trim(),
          skillsOffered: _skillsOffered,
          skillsWanted: _skillsWanted,
          experienceLevel: _experience,
          availability: _availability,
          bio: _bioC.text.trim(),
          photo: _photo,
        );
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Skill Swap')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Let neighbors know who you are and what you bring to the community.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _PhotoPicker(photo: _photo, onTap: _pickPhoto),
              const SizedBox(height: 20),
              AppTextField(
                hint: 'e.g. Alex Rivera',
                label: 'Full Name',
                controller: _nameC,
                validator: (v) => validateRequired(v, 'Name'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                hint: 'Neighborhood, City',
                label: 'Location',
                controller: _locationC,
                prefix: const Icon(Icons.location_on_outlined, size: 18),
              ),
              const SizedBox(height: 20),
              _SkillSection(
                title: 'Skills I Offer',
                skills: _skillsOffered,
                controller: _skillOfferC,
                onAdd: () => _addSkill(_skillsOffered, _skillOfferC),
                onRemove: (s) => setState(() => _skillsOffered.remove(s)),
              ),
              const SizedBox(height: 20),
              _SkillSection(
                title: 'Skills I Want to Learn',
                skills: _skillsWanted,
                controller: _skillWantC,
                onAdd: () => _addSkill(_skillsWanted, _skillWantC),
                onRemove: (s) => setState(() => _skillsWanted.remove(s)),
                wantMode: true,
              ),
              const SizedBox(height: 20),
              _ExperienceSelector(
                selected: _experience,
                onSelect: (v) => setState(() => _experience = v),
              ),
              const SizedBox(height: 20),
              _AvailabilitySelector(
                selected: _availability,
                options: _availabilities,
                onSelect: (v) => setState(() => _availability = v),
              ),
              const SizedBox(height: 20),
              _BioField(controller: _bioC),
              if (profileState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  profileState.error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              AppButton(
                label: 'Save & Continue to Dashboard →',
                loading: profileState.loading,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final File? photo;
  final VoidCallback onTap;
  const _PhotoPicker({required this.photo, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.border,
              backgroundImage: photo != null ? FileImage(photo!) : null,
              child: photo == null
                  ? const Icon(
                      Icons.person,
                      size: 44,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  final String title;
  final List<String> skills;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  final bool wantMode;
  const _SkillSection({
    required this.title,
    required this.skills,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.wantMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: onAdd,
              child: const Text(
                'Add New',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a skill...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        if (skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map(
                  (s) => SkillChip(
                    label: s,
                    removable: true,
                    onRemove: () => onRemove(s),
                    bgColor: wantMode ? const Color(0xFFFEF3C7) : null,
                    textColor: wantMode ? const Color(0xFF92400E) : null,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ExperienceSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _ExperienceSelector({required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Experience Level',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Novice', 'Expert', 'Master'].map((e) {
            final active = e == selected;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(e),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AvailabilitySelector extends StatelessWidget {
  final String selected;
  final List<String> options;
  final void Function(String) onSelect;
  const _AvailabilitySelector({
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => ListView(
              shrinkWrap: true,
              children: options
                  .map(
                    (o) => ListTile(
                      title: Text(o),
                      trailing: o == selected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        onSelect(o);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(selected, style: const TextStyle(fontSize: 14)),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BioField extends StatelessWidget {
  final TextEditingController controller;
  const _BioField({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Short Bio',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI Assisted',
                style: TextStyle(fontSize: 10, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Share a bit about your passions and what you\'d like to achieve through swapping skills.',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
