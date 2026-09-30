// lib/widgets/floating_icons_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FloatingIconsBackground extends StatefulWidget {
  final Widget child;
  const FloatingIconsBackground({super.key, required this.child});

  @override
  State<FloatingIconsBackground> createState() => _FloatingIconsBackgroundState();
}

class _FloatingIconsBackgroundState extends State<FloatingIconsBackground>
    with TickerProviderStateMixin {
  late final AnimationController _driftController;
  late final AnimationController _orbController;
  late final List<_FloatingIconSpec> _icons;

  static const _iconPool = [
    Icons.movie_creation_outlined, Icons.local_movies_outlined, Icons.theaters_outlined,
    Icons.star_rounded, Icons.favorite_rounded, Icons.person_outline_rounded,
    Icons.people_outline_rounded, Icons.play_circle_outline_rounded, Icons.live_tv_outlined,
    Icons.bookmark_outline_rounded, Icons.auto_awesome_rounded, Icons.movie_filter_outlined,
    Icons.smart_display_outlined, Icons.chat_bubble_outline_rounded, Icons.mode_comment_outlined,
    Icons.emoji_emotions_outlined, Icons.mood_outlined, Icons.sentiment_satisfied_alt_rounded,
    Icons.thumb_up_outlined, Icons.headset_outlined, Icons.camera_alt_outlined, Icons.music_note_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);

    final rnd = math.Random(11);
    _icons = List.generate(26, (i) {
      return _FloatingIconSpec(
        icon: _iconPool[i % _iconPool.length],
        left: rnd.nextDouble(),
        top: rnd.nextDouble(),
        size: 16 + rnd.nextDouble() * 24,
        opacity: 0.06 + rnd.nextDouble() * 0.1,
        speed: 0.35 + rnd.nextDouble() * 0.55,
        phase: rnd.nextDouble() * 2 * math.pi,
        radius: 22 + rnd.nextDouble() * 26,
      );
    });
  }

  @override
  void dispose() {
    _driftController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const [Color(0xFF120404), Color(0xFF0A0A0A), Color(0xFF060608), Color(0xFF0A0A0A)]
        : const [Color(0xFFFFF3F3), Color(0xFFF7F7F9), Color(0xFFFFFFFF), Color(0xFFF5F5F7)];

    final iconColor = isDark ? Colors.white : Colors.black;
    final scaffoldBg = isDark ? AppColors.background : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: bgGradient, stops: const [0.0, 0.35, 0.7, 1.0]),
            ),
          ),
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_orbController.value);
              return Stack(
                children: [
                  Positioned(
                    left: -size.width * 0.3 + (t * 36),
                    top: -size.width * 0.25 - (t * 14),
                    child: _glowOrb(AppColors.primary, size.width * 0.9, isDark ? 0.22 : 0.14),
                  ),
                  Positioned(
                    right: -size.width * 0.3 - (t * 30),
                    bottom: -size.width * 0.2 + (t * 14),
                    child: _glowOrb(AppColors.tertiary, size.width * 0.75, isDark ? 0.16 : 0.10),
                  ),
                ],
              );
            },
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _driftController,
              builder: (context, _) {
                return Stack(
                  children: _icons.map((spec) {
                    final t = (_driftController.value * spec.speed + spec.phase) % 1.0;
                    final angle = t * 2 * math.pi;
                    final dy = math.sin(angle) * spec.radius;
                    final dx = math.cos(angle * 0.8) * spec.radius * 0.7;
                    return Positioned(
                      left: spec.left * size.width + dx,
                      top: spec.top * size.height + dy,
                      child: Icon(spec.icon, size: spec.size, color: iconColor.withValues(alpha: spec.opacity)),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)])),
      ),
    );
  }
}

class _FloatingIconSpec {
  final IconData icon;
  final double left, top, size, opacity, speed, phase, radius;
  _FloatingIconSpec({
    required this.icon, required this.left, required this.top, required this.size,
    required this.opacity, required this.speed, required this.phase, required this.radius,
  });
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const GlassCard({super.key, required this.child, this.maxWidth = 420, this.padding = const EdgeInsets.fromLTRB(28, 32, 28, 28)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? AppColors.glassBorder : const Color(0x14000000), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 40, offset: const Offset(0, 16))],
        ),
        child: child,
      ),
    );
  }
}