import 'dart:math';
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
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest.shortestSide.clamp(220.0, 330.0);
          return SizedBox(
            width: size,
            height: size * 0.82,
            child: CustomPaint(painter: _ScenePainter(type)),
          );
        },
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final _Illustration type;
  _ScenePainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 300;
    final center = Offset(size.width / 2, size.height * .44);
    final green = const Color(0xFF168044);
    final lime = const Color(0xFF83C936);
    final accent = type == _Illustration.knowledge
        ? const Color(0xFFFFC94D)
        : const Color(0xFF52B788);
    canvas.drawCircle(
      center,
      103 * s,
      Paint()..color = const Color(0xFFEAF8EE),
    );
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..color = accent.withValues(alpha: .45);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 250 * s, height: 92 * s),
      orbit,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 208 * s, height: 142 * s),
      orbit..color = green.withValues(alpha: .2),
    );
    if (type == _Illustration.knowledge) {
      _books(canvas, center.translate(0, 58 * s), s, green, accent);
      _bulb(canvas, center.translate(0, -28 * s), s, accent);
    } else if (type == _Illustration.community) {
      _globe(canvas, center.translate(0, 2 * s), s, green, accent);
      _person(canvas, center.translate(-73 * s, -55 * s), s, green);
      _person(canvas, center.translate(73 * s, -42 * s), s, green);
    } else {
      _books(canvas, center.translate(0, 56 * s), s, green, lime);
      _person(canvas, center.translate(-48 * s, 0), s, green);
      _person(canvas, center.translate(48 * s, 0), s, green);
    }
    _leaf(canvas, center.translate(-78 * s, 56 * s), s, lime, -.6);
    _leaf(canvas, center.translate(78 * s, 52 * s), s, green, .6);
    for (var i = 0; i < 8; i++) {
      final a = i * .78;
      canvas.drawCircle(
        center + Offset(cos(a) * 126 * s, sin(a) * 82 * s),
        (i.isEven ? 4 : 3) * s,
        Paint()..color = accent.withValues(alpha: .55),
      );
    }
  }

  void _books(Canvas c, Offset p, double s, Color green, Color accent) {
    c.drawOval(
      Rect.fromCenter(
        center: p.translate(0, 25 * s),
        width: 180 * s,
        height: 22 * s,
      ),
      Paint()..color = green.withValues(alpha: .12),
    );
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: p.translate(0, -i * 19 * s),
          width: (150 - i * 12) * s,
          height: 24 * s,
        ),
        Radius.circular(7 * s),
      );
      c.drawRRect(r, Paint()..color = i == 1 ? accent : green);
    }
  }

  void _bulb(Canvas c, Offset p, double s, Color accent) {
    c.drawCircle(
      p.translate(0, -3 * s),
      27 * s,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFF3A8), accent],
        ).createShader(Rect.fromCircle(center: p, radius: 28 * s)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: p.translate(0, 25 * s),
          width: 23 * s,
          height: 15 * s,
        ),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFF168044),
    );
  }

  void _globe(Canvas c, Offset p, double s, Color green, Color accent) {
    c.drawCircle(
      p,
      56 * s,
      Paint()
        ..shader = RadialGradient(
          colors: [accent, green],
        ).createShader(Rect.fromCircle(center: p, radius: 56 * s)),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..color = Colors.white.withValues(alpha: .55);
    c.drawOval(
      Rect.fromCenter(center: p, width: 45 * s, height: 112 * s),
      line,
    );
    c.drawOval(
      Rect.fromCenter(center: p, width: 112 * s, height: 38 * s),
      line,
    );
  }

  void _person(Canvas c, Offset p, double s, Color color) {
    c.drawCircle(p.translate(0, -17 * s), 13 * s, Paint()..color = color);
    final body = Path()
      ..moveTo(p.dx - 25 * s, p.dy + 28 * s)
      ..quadraticBezierTo(p.dx - 23 * s, p.dy - 5 * s, p.dx, p.dy - 2 * s)
      ..quadraticBezierTo(
        p.dx + 23 * s,
        p.dy - 5 * s,
        p.dx + 25 * s,
        p.dy + 28 * s,
      )
      ..close();
    c.drawPath(body, Paint()..color = color);
  }

  void _leaf(Canvas c, Offset p, double s, Color color, double angle) {
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 20 * s)
      ..quadraticBezierTo(-35 * s, -4 * s, 0, -32 * s)
      ..quadraticBezierTo(35 * s, -4 * s, 0, 20 * s)
      ..close();
    c.drawPath(leaf, Paint()..color = color);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.type != type;
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
