import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/utils/validators.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  final _signupEmailC = TextEditingController();
  final _signupPassC = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureSignup = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailC.dispose();
    _passC.dispose();
    _nameC.dispose();
    _signupEmailC.dispose();
    _signupPassC.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_loginKey.currentState!.validate()) return;
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .signIn(_emailC.text.trim(), _passC.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _signUp() async {
    if (!_signupKey.currentState!.validate()) return;
    final ok = await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          _signupEmailC.text.trim(),
          _signupPassC.text,
          _nameC.text.trim(),
        );
    if (ok && mounted)
      Navigator.pushReplacementNamed(context, '/profile-setup');
  }

  Future<void> _googleSignIn() async {
    final ok = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _appleSignIn() async {
    final ok = await ref.read(authNotifierProvider.notifier).signInWithApple();
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Logo
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SkillSwap',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Learn, share, and grow together.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Login'),
                    Tab(text: 'Create Account'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _tab.index == 0 ? 330 : 360,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _LoginForm(
                      formKey: _loginKey,
                      emailC: _emailC,
                      passC: _passC,
                      obscure: _obscureLogin,
                      onToggle: () =>
                          setState(() => _obscureLogin = !_obscureLogin),
                      onSubmit: _signIn,
                      loading: isLoading,
                    ),
                    _SignupForm(
                      formKey: _signupKey,
                      nameC: _nameC,
                      emailC: _signupEmailC,
                      passC: _signupPassC,
                      obscure: _obscureSignup,
                      onToggle: () =>
                          setState(() => _obscureSignup = !_obscureSignup),
                      onSubmit: _signUp,
                      loading: isLoading,
                    ),
                  ],
                ),
              ),
              // Error banner
              if (authState.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(authNotifierProvider.notifier)
                            .clearError(),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      onTap: isLoading ? null : _googleSignIn,
                      icon: _GoogleIcon(),
                      label: 'Google',
                    ),
                  ),
                  if (isIOS) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        onTap: isLoading ? null : _appleSignIn,
                        icon: const Icon(
                          Icons.apple,
                          size: 22,
                          color: Colors.black,
                        ),
                        label: 'Apple',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: 'By joining, you agree to our '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: icon),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_g.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

class _LoginForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailC, passC;
  final bool obscure, loading;
  final VoidCallback onToggle, onSubmit;
  const _LoginForm({
    required this.formKey,
    required this.emailC,
    required this.passC,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
    required this.loading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            hint: 'hello@example.com',
            label: 'Email Address',
            controller: emailC,
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined, size: 18),
            validator: validateEmail,
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: '••••••••',
            label: 'Password',
            controller: passC,
            obscure: obscure,
            prefix: const Icon(Icons.lock_outline, size: 18),
            suffix: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: onToggle,
            ),
            validator: validatePassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPassword(context, ref),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Sign In',
            loading: loading,
            onPressed: onSubmit,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showForgotPassword(BuildContext context, WidgetRef ref) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your email and we'll send a reset link.",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            AppTextField(
              hint: 'you@example.com',
              controller: c,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = c.text.trim();
              final err = validateEmail(email);
              if (err != null) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              final ok = await ref
                  .read(authNotifierProvider.notifier)
                  .resetPassword(email);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Reset link sent! Check your inbox.'
                          : 'Unable to send reset email.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameC, emailC, passC;
  final bool obscure, loading;
  final VoidCallback onToggle, onSubmit;
  const _SignupForm({
    required this.formKey,
    required this.nameC,
    required this.emailC,
    required this.passC,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppTextField(
              hint: 'Your full name',
              label: 'Full Name',
              controller: nameC,
              prefix: const Icon(Icons.person_outline, size: 18),
              validator: (v) => validateRequired(v, 'Name'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              hint: 'hello@example.com',
              label: 'Email Address',
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email_outlined, size: 18),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            AppTextField(
              hint: '••••••••',
              label: 'Password',
              controller: passC,
              obscure: obscure,
              prefix: const Icon(Icons.lock_outline, size: 18),
              suffix: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: onToggle,
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: 'Create Account',
              loading: loading,
              onPressed: onSubmit,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
