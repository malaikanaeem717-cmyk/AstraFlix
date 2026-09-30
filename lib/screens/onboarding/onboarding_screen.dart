// lib/screens/onboarding/onboarding_screen.dart
// 3-page onboarding flow explaining app features

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.movie_filter_rounded,
      gradient: [Color(0xFFE50914), Color(0xFF8B0000)],
      title: 'Discover Movies',
      subtitle: 'Curated for You',
      description:
          'Explore thousands of movies across every genre. From blockbusters to hidden gems — AstraFlix finds what you\'ll love.',
      features: ['🎬 Browse 500K+ movies', '🌍 Multiple genres', '⭐ Curated lists'],
    ),
    OnboardingPage(
      icon: Icons.psychology_rounded,
      gradient: [Color(0xFF6C35DE), Color(0xFF3A1B7A)],
      title: 'AI Recommendations',
      subtitle: 'Powered by Machine Learning',
      description:
          'Our AI learns your taste and delivers hyper-personalized recommendations. The more you watch, the smarter it gets.',
      features: ['🤖 ML-powered engine', '🎯 Personalized picks', '📊 Taste analytics'],
    ),
    OnboardingPage(
      icon: Icons.collections_bookmark_rounded,
      gradient: [Color(0xFF00B4DB), Color(0xFF0056A3)],
      title: 'Your Collection',
      subtitle: 'Track & Organize',
      description:
          'Save favorites, build your watchlist, rate movies, and track your viewing history — all in one place.',
      features: ['❤️ Favorites list', '📌 Watchlist', '⭐ Rate & review'],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) =>
                _OnboardingPageWidget(page: _pages[index]),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Page Indicator
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotColor: AppColors.textMuted,
                        activeDotColor: AppColors.primary,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Buttons
                    Row(
                      children: [
                        // Skip
                        if (_currentPage < _pages.length - 1)
                          TextButton(
                            onPressed: _completeOnboarding,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Next / Get Started
                        GradientButton(
                          label: _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          width: _currentPage == _pages.length - 1 ? 160 : 120,
                          height: 48,
                          icon: _currentPage == _pages.length - 1
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          onTap: () {
                            if (_currentPage < _pages.length - 1) {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _completeOnboarding();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
      child: Column(
        children: [
          // Hero Illustration
          SizedBox(
            height: size.height * 0.45,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow rings
                  ...List.generate(3, (i) {
                    final size = 120.0 + i * 60;
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: page.gradient[0]
                              .withOpacity(0.15 - i * 0.04),
                          width: 1,
                        ),
                      ),
                    );
                  }),
                  // Main icon container
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: page.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: page.gradient[0].withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(page.icon, size: 52, color: Colors.white),
                  ),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
          ),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 6),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              color: page.gradient[0],
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Features
          ...page.features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(f, style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;

  const OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}
