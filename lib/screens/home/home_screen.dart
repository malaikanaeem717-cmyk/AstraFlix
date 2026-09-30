// lib/screens/home/home_screen.dart
// Main home screen — Netflix-style hero banner + categorised movie rows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/movie_model.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  bool _darkenAppBar = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final darken = _scroll.offset > 80;
      if (darken != _darkenAppBar) setState(() => _darkenAppBar = darken);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openDetails(Movie movie) =>
      context.push('/movie/${movie.id}', extra: movie);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _appBar(user?.firstName ?? ''),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ── Hero banner
            SliverToBoxAdapter(child: _heroBanner()),
            // ── Top Rated
            SliverToBoxAdapter(child: _section('⭐ Top Rated', topRatedMoviesProvider)),
            // ── Action
            SliverToBoxAdapter(child: _section('💥 Action', actionMoviesProvider)),
            // ── Comedy
            SliverToBoxAdapter(child: _section('😂 Comedy', comedyMoviesProvider)),
            // ── Horror
            SliverToBoxAdapter(child: _section('👻 Horror', horrorMoviesProvider)),
            // ── Romance
            SliverToBoxAdapter(child: _section('❤️ Romance', romanceMoviesProvider)),
            // ── Sci-Fi
            SliverToBoxAdapter(child: _section('🚀 Sci-Fi', scifiMoviesProvider)),
            // Spacer for bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
            SliverToBoxAdapter(child: _section('🎬 Hollywood', hollywoodMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇮🇳 Bollywood', bollywoodMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇵🇰 Pakistani Cinema', pakistaniMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇰🇷 Korean Movies', koreanMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇹🇷 Turkish Movies', turkishMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇯🇵 Japanese Movies', japaneseMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇨🇳 Chinese Movies', chineseMoviesProvider)),
            SliverToBoxAdapter(child: _section('🇮🇩 Indonesian Movies', indonesianMoviesProvider)),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {


    ref.invalidate(topRatedMoviesProvider);
    ref.invalidate(actionMoviesProvider);
    ref.invalidate(comedyMoviesProvider);
    ref.invalidate(horrorMoviesProvider);
    ref.invalidate(romanceMoviesProvider);
    ref.invalidate(scifiMoviesProvider);
    ref.invalidate(hollywoodMoviesProvider);
    ref.invalidate(bollywoodMoviesProvider);
    ref.invalidate(pakistaniMoviesProvider);
    ref.invalidate(koreanMoviesProvider);
    ref.invalidate(turkishMoviesProvider);
    ref.invalidate(japaneseMoviesProvider);
    ref.invalidate(chineseMoviesProvider);
    ref.invalidate(indonesianMoviesProvider);

    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar(String firstName) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _darkenAppBar
            ? AppColors.background.withOpacity(0.95)
            : Colors.transparent,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: _logo(),
          actions: [
            if (firstName.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    'Hi $firstName 👋',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: Stack(children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ),
              ]),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _logo() => Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Center(
            child: Text('A',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins')),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(children: [
            TextSpan(
                text: 'Astra',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins')),
            TextSpan(
                text: 'Flix',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins')),
          ]),
        ),
      ]);

  // ── Hero banner ────────────────────────────────────────────────────────────
  Widget _heroBanner() {
    final trending = ref.watch(trendingMoviesProvider);
    return trending.when(
      data: (movies) => movies.isEmpty
          ? const ShimmerHeroBanner()
          : _HeroBanner(movies: movies.take(5).toList(), onTap: _openDetails),
      loading: () => const ShimmerHeroBanner(),
      error: (_, __) => const ShimmerHeroBanner(),
    );
  }

  // ── Generic horizontal section ─────────────────────────────────────────────
  Widget _section(
    String title,
    AutoDisposeFutureProvider<List<Movie>> provider, [
    MovieCardSize size = MovieCardSize.medium,
  ]) {
    final async = ref.watch(provider);
    return async.when(
      data: (movies) => MovieRow(
        title: title,
        movies: movies,
        onMovieTap: _openDetails,
        cardSize: size,
      ),
      loading: () => ShimmerMovieRow(
        cardWidth: size == MovieCardSize.large ? 160 : 130,
        cardHeight: size == MovieCardSize.large ? 240 : 195,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie) onTap;
  const _HeroBanner({required this.movies, required this.onTap});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  final PageController _page = PageController();
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _autoScroll();
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || widget.movies.length < 2) return;
      final next = (_idx + 1) % widget.movies.length;
      _page.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      _autoScroll();
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 520,
      child: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: widget.movies.length,
            onPageChanged: (i) => setState(() => _idx = i),
            itemBuilder: (_, i) => _BannerSlide(
              movie: widget.movies[i],
              onTap: () => widget.onTap(widget.movies[i]),
            ),
          ),
          // Page dots
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.movies.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _idx ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _idx ? AppColors.primary : Colors.white30,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  const _BannerSlide({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          movie.backdropUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: movie.backdropUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.surfaceVariant),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

          // Bottom gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x800A0A0A),
                  Color(0xCC0A0A0A),
                  Color(0xFF0A0A0A),
                ],
                stops: [0, 0.45, 0.72, 1],
              ),
            ),
          ),

          // Left-fade gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x880A0A0A), Colors.transparent],
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 34,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Row(children: [
                  if (movie.voteAverage > 0) ...[
                    RatingBadge(rating: movie.voteAverage),
                    const SizedBox(width: 8),
                  ],
                  if (movie.year.isNotEmpty)
                    _pill(movie.year),
                ]),
                const SizedBox(height: 8),
                // Title
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                    height: 1.1,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 6),
                // Overview
                if (movie.overview != null)
                  Text(
                    movie.overview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 16),
                // CTA buttons
                Row(children: [
                  _ctaButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Play',
                    dark: false,
                    onTap: onTap,
                  ),
                  const SizedBox(width: 10),
                  _ctaButton(
                    icon: Icons.info_outline_rounded,
                    label: 'More Info',
                    dark: true,
                    onTap: onTap,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.glassBlack,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins')),
      );

  Widget _ctaButton({
    required IconData icon,
    required String label,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? Colors.white24 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: dark ? Border.all(color: Colors.white30) : null,
        ),
        child: Row(children: [
          Icon(icon, color: dark ? Colors.white : Colors.black, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                color: dark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              )),
        ]),
      ),
    );
  }
}
