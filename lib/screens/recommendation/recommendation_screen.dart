// lib/screens/recommendation/recommendation_screen.dart
// AI-powered recommendation screen. Ready to connect to FastAPI ML backend.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../api/recommendation_service.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/shimmer_loading.dart';

class RecommendationScreen extends ConsumerStatefulWidget {
  final String? initialMovie;

  const RecommendationScreen({super.key, this.initialMovie});

  @override
  ConsumerState<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _movieController = TextEditingController();
  late AnimationController _pulseController;
  bool _backendChecked = false;
  bool _backendOnline = false;

  // Example movies for quick pick
  static const List<_QuickPick> _quickPicks = [
    _QuickPick('Avengers', '💪'),
    _QuickPick('Inception', '🌀'),
    _QuickPick('The Dark Knight', '🦇'),
    _QuickPick('Interstellar', '🚀'),
    _QuickPick('Parasite', '🏆'),
    _QuickPick('Get Out', '😱'),
    _QuickPick('La La Land', '🎶'),
    _QuickPick('Dune', '🌙'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // If opened from movie details with a pre-filled title
    if (widget.initialMovie != null) {
      _movieController.text = widget.initialMovie!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getRecommendations(widget.initialMovie!);
      });
    }

    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    final online = await RecommendationService().isBackendAvailable();
    if (mounted) setState(() { _backendOnline = online; _backendChecked = true; });
  }

  Future<void> _getRecommendations(String title) async {
    if (title.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(recommendationNotifierProvider.notifier).getRecommendations(title.trim());
  }

  @override
  void dispose() {
    _movieController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader()),

            // Backend Status Badge
            if (_backendChecked)
              SliverToBoxAdapter(child: _buildBackendStatus()),

            // Search Input
            SliverToBoxAdapter(child: _buildSearchSection()),

            // Quick Picks
            if (!state.isLoading && state.recommendations.isEmpty)
              SliverToBoxAdapter(child: _buildQuickPicks()),

            // Loading State
            if (state.isLoading)
              SliverToBoxAdapter(child: _buildLoadingState()),

            // Results
            if (!state.isLoading && state.recommendations.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildResultsHeader(state)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => MovieCard(
                      movie: state.recommendations[i],
                      size: MovieCardSize.medium,
                      showTitle: true,
                      animationIndex: i,
                      onTap: () => context.push(
                        '/movie/${state.recommendations[i].id}',
                        extra: state.recommendations[i],
                      ),
                    ),
                    childCount: state.recommendations.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                ),
              ),
            ],

            // Empty/Error state
            if (!state.isLoading &&
                state.recommendations.isEmpty &&
                state.movieTitle != null)
              SliverToBoxAdapter(child: _buildEmptyState(state)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with AI badge
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C35DE),
                        Color.lerp(
                          const Color(0xFF6C35DE),
                          const Color(0xFFE50914),
                          _pulseController.value,
                        )!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'AI Powered',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Movie\nRecommendations',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a movie you love and our ML engine finds perfect matches for you.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildBackendStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _backendOnline
              ? AppColors.success.withOpacity(0.1)
              : AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _backendOnline
                ? AppColors.success.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _backendOnline ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _backendOnline
                    ? 'ML Backend: Online — Using AI recommendations'
                    : 'ML Backend: Offline — Using TMDB fallback (connect your FastAPI backend at ${RecommendationService.baseUrl})',
                style: TextStyle(
                  color: _backendOnline ? AppColors.success : AppColors.warning,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Config button
            GestureDetector(
              onTap: _showBackendConfig,
              child: const Icon(Icons.settings_outlined,
                  size: 16, color: AppColors.textMuted),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms),
    );
  }

  void _showBackendConfig() {
    final urlController =
        TextEditingController(text: RecommendationService.baseUrl);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ML Backend Configuration',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the URL of your FastAPI recommendation server.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'http://127.0.0.1:8000',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Expected endpoint: GET /recommend?movie={title}\nExpected response: [{"title": "...", "poster": "..."}]',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Save & Test Connection',
              icon: Icons.save_rounded,
              onTap: () {
                RecommendationService.setBaseUrl(urlController.text);
                Navigator.pop(context);
                _checkBackendStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _movieController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Avengers, Inception...',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: _getRecommendations,
                  ),
                ),
                // Get Recommendations button
                GestureDetector(
                  onTap: () => _getRecommendations(_movieController.text),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Recommend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildQuickPicks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Quick Picks',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPicks
                .asMap()
                .entries
                .map(
                  (e) => GestureDetector(
                    onTap: () {
                      _movieController.text = e.value.title;
                      _getRecommendations(e.value.title);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.value.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            e.value.title,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: 0.1),
                )
                .toList(),
          ),
        ),
        // How it works
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
          child: _HowItWorksCard(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // AI animation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C35DE),
                            Color.lerp(
                              const Color(0xFF6C35DE),
                              AppColors.primary,
                              _pulseController.value,
                            )!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C35DE).withOpacity(
                              0.3 + 0.3 * _pulseController.value,
                            ),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 28),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Finding recommendations for\n"${_movieController.text}"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analyzing movie patterns with ML...',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerMovieRow(),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${state.recommendations.length} movies like "${state.movieTitle}"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(recommendationNotifierProvider.notifier).clear();
                  _movieController.clear();
                },
                child: const Text('Clear',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins')),
              ),
            ],
          ),
          if (state.message != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.info, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.message!,
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(state) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No Recommendations',
        subtitle: state.message ?? 'Try a different movie title.',
        buttonLabel: 'Try Again',
        onButtonTap: () {
          ref.read(recommendationNotifierProvider.notifier).clear();
          _movieController.clear();
        },
      ),
    );
  }
}

// Quick pick data class
class _QuickPick {
  final String title;
  final String emoji;
  const _QuickPick(this.title, this.emoji);
}

// How it works info card
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            ('1', 'Enter a movie title you enjoy'),
            ('2', 'ML engine analyzes patterns & themes'),
            ('3', 'Get personalized movie matches'),
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        step.$1,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    step.$2,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}
