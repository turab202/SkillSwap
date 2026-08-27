import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (_) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _loggingOut = false);
        final msg = e.toString().isNotEmpty
            ? e.toString()
            : 'Failed to sign out. Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      body: _loggingOut
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Row(
                      children: [
                        UserAvatar(
                          photoUrl: user?.photoUrl,
                          displayName: user?.displayName ?? '?',
                          radius: 28,
                          bgColor: AppColors.accent.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/profile-setup'),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _section([
                    _tile(Icons.manage_accounts_outlined, 'Account Settings'),
                    _tile(Icons.security_outlined, 'Privacy & Safety'),
                    _tile(
                      Icons.notifications_outlined,
                      'Notification Preferences',
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _section([
                    _tile(
                      Icons.language_outlined,
                      'Language',
                      trailing: 'English (US)',
                    ),
                    _tile(Icons.help_outline, 'Help & Support'),
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: AppColors.error,
                        size: 22,
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 14, color: AppColors.error),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: _logout,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Skill Swap v1.0.0\nMade with love for the community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _section(List<Widget> tiles) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, {String? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
