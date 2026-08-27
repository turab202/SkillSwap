import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Discover people with useful skills',
      highlighted: 'useful skills',
      subtitle:
          'Find neighbors who can teach you anything from gardening to coding.',
      illustration: _Illustration.people,
    ),
    _OnboardingData(
      title: 'Share your knowledge',
      highlighted: 'knowledge',
      subtitle:
          'Help your neighbors grow by sharing your unique skills, from cooking to coding.',
      illustration: _Illustration.knowledge,
    ),
    _OnboardingData(
      title: 'Build community together',
      highlighted: 'community together',
      subtitle:
          'Connect with people around you and create a stronger, more supportive neighborhood.',
      illustration: _Illustration.community,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 18, top: 8),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (_, index) =>
                    _PageContent(data: _pages[index], showBrand: index == 0),
              ),
            ),
            _Dots(current: _page),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _page == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.arrow_forward, size: 23),
                      if (_page == _pages.length - 1) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.auto_awesome, size: 22),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String highlighted;
  final String subtitle;
  final _Illustration illustration;

  const _OnboardingData({
    required this.title,
    required this.highlighted,
    required this.subtitle,
    required this.illustration,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  final bool showBrand;

  const _PageContent({required this.data, required this.showBrand});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final titleParts = data.title.split(data.highlighted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (showBrand) ...[
            const SizedBox(height: 2),
            const _BrandLockup(),
            SizedBox(height: screenHeight < 720 ? 8 : 18),
          ] else
            SizedBox(height: screenHeight < 720 ? 20 : 38),
          Expanded(child: _OnboardingIllustration(type: data.illustration)),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 25,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: titleParts.first),
                TextSpan(
                  text: data.highlighted,
                  style: const TextStyle(color: AppColors.primary),
                ),
                if (titleParts.length > 1) TextSpan(text: titleParts.last),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFE9F8ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sync_alt,
                color: AppColors.primary,
                size: 39,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Skill',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Swap',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Learn • Share • Grow Together',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

enum _Illustration { people, knowledge, community }

class _OnboardingIllustration extends StatelessWidget {
  final _Illustration type;
  const _OnboardingIllustration({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      _Illustration.people => Icons.people_alt,
      _Illustration.knowledge => Icons.lightbulb,
      _Illustration.community => Icons.public,
    };
    final color = switch (type) {
      _Illustration.people => const Color(0xFF76C832),
      _Illustration.knowledge => const Color(0xFFFFC94D),
      _Illustration.community => const Color(0xFF52B788),
    };

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide.clamp(220.0, 330.0);
          return SizedBox(
            width: size,
            height: size * 0.82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.24),
                      width: 2,
                    ),
                  ),
                ),
                Icon(icon, size: size * 0.34, color: color),
                Positioned(
                  top: size * 0.05,
                  left: size * 0.12,
                  child: _Bubble(icon: Icons.school, color: AppColors.primary),
                ),
                Positioned(
                  top: size * 0.13,
                  right: size * 0.08,
                  child: _Bubble(icon: Icons.code, color: AppColors.primary),
                ),
                Positioned(
                  bottom: size * 0.04,
                  left: size * 0.08,
                  child: _Bubble(icon: Icons.lightbulb_outline, color: color),
                ),
                Positioned(
                  bottom: size * 0.02,
                  right: size * 0.10,
                  child: _Bubble(icon: Icons.palette_outlined, color: color),
                ),
                Positioned(
                  bottom: 0,
                  left: size * 0.19,
                  child: Container(
                    width: size * 0.62,
                    height: size * 0.11,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Bubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _Dots extends StatelessWidget {
  final int current;
  const _Dots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: index == current
                ? AppColors.primary
                : const Color(0xFFD8E8DF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
