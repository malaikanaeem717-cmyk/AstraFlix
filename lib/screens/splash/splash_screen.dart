// lib/screens/splash/splash_screen.dart
// Modern animated splash screen — layered gradient mesh background, floating
// glow orbs, a rotating-ring logo reveal, letter-by-letter wordmark, and a
// smooth progress indicator that hands off into onboarding/auth/home.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _orbController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 4500));
    if (!mounted) return;

    // Check if onboarding is done.
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;

    // Check auth state.
    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (!onboardingDone) {
          context.go('/onboarding');
        } else if (user != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      },
      loading: () => context.go('/login'),
      error: (_, __) => context.go('/login'),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _orbController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layered mesh-gradient backdrop ──────────────────────────────
          const _MeshBackground(),

          // ── Floating glow orbs (subtle parallax drift) ──────────────────
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, _) {
              final t = _orbController.value;
              return Stack(
                children: [
                  _GlowOrb(
                    color: AppColors.primary,
                    size: size.width * 0.9,
                    left: -size.width * 0.35 + (t * 30),
                    top: -size.width * 0.25 - (t * 20),
                    opacity: 0.28,
                  ),
                  _GlowOrb(
                    color: AppColors.tertiary,
                    size: size.width * 0.75,
                    right: -size.width * 0.3 - (t * 25),
                    bottom: -size.width * 0.2 + (t * 15),
                    opacity: 0.18,
                  ),
                  _GlowOrb(
                    color: AppColors.secondary,
                    size: size.width * 0.5,
                    right: size.width * 0.15,
                    top: size.height * 0.12 + (t * 18),
                    opacity: 0.12,
                  ),
                ],
              );
            },
          ),

          // ── Fine noise/grain overlay for a premium, non-flat feel ───────
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Colors.transparent, Color(0x66000000)],
                ),
              ),
            ),
          ),

          // ── Foreground content ───────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildLogo(),
                const SizedBox(height: 28),
                _buildWordmark(),
                const SizedBox(height: 10),
                _buildTagline(),
                const Spacer(flex: 4),
                _buildProgress(),
                const SizedBox(height: 36),
                _buildFooter(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating dashed-gradient ring
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _ringController.value * 2 * math.pi,
                child: child,
              );
            },
            child: CustomPaint(
              size: const Size(168, 168),
              painter: _OrbitRingPainter(),
            ),
          ),

          // Counter-rotating faint ring for depth
          AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_ringController.value * 2 * math.pi * 0.6,
                child: child,
              );
            },
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1,
                ),
              ),
            ),
          ),

          // Core glass logo tile
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  blurRadius: 48,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
            ),
          )
              .animate()
              .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: 700.ms,
            curve: Curves.elasticOut,
          )
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildWordmark() {
    const letters = ['A', 's', 't', 'r', 'a', 'F', 'l', 'i', 'x'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(letters.length, (i) {
        final isRed = i >= 5; // "Flix" in brand red
        return Text(
          letters[i],
          style: TextStyle(
            color: isRed ? AppColors.primary : Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        )
            .animate(delay: (500 + i * 45).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.6, end: 0, duration: 350.ms, curve: Curves.easeOutCubic);
      }),
    );
  }

  Widget _buildTagline() {
    return const Text(
      'AI-POWERED MOVIE INTELLIGENCE',
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
        letterSpacing: 3,
      ),
    )
        .animate(delay: 950.ms)
        .fadeIn(duration: 500.ms)
        .shimmer(delay: 1400.ms, duration: 1400.ms, color: Colors.white24);
  }

  Widget _buildProgress() {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 3,
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressController.value,
                  minHeight: 3,
                  backgroundColor: AppColors.glassWhite,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              );
            },
          ),
        ),
      ],
    ).animate(delay: 700.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildFooter() {
    return const Text(
      'Built with Flutter · Firebase · Groq AI',
      style: TextStyle(
        color: AppColors.textHint,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        fontFamily: 'Poppins',
        letterSpacing: 0.6,
      ),
    ).animate(delay: 1200.ms).fadeIn(duration: 500.ms);
  }
}

/// Subtle multi-stop dark gradient so the background isn't a flat block.
class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF120404),
            Color(0xFF0A0A0A),
            Color(0xFF060608),
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
    );
  }
}

/// A soft, blurred color orb used to build the layered glow backdrop.
class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed, gradient-colored ring around the logo — an orbit effect.
class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;

    final gradient = SweepGradient(
      colors: [
        AppColors.primary.withValues(alpha: 0),
        AppColors.primary,
        AppColors.tertiary,
        AppColors.primary.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const dashCount = 40;
    const gapFraction = 0.45; // fraction of each segment that's a gap
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (2 * math.pi / dashCount) * i;
      final sweep = (2 * math.pi / dashCount) * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}