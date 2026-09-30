// lib/utils/app_router.dart
// GoRouter configuration — auth-aware routing for AstraFlix

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/movie_model.dart';
import '../screens/genre/genre_movies_screen.dart';
import '../providers/app_providers.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../models/user_model.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/details/movie_details_screen.dart';
import '../screens/recommendation/recommendation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),

      // ── Onboarding ──────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const RegisterScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Main App (Bottom Nav Shell) ─────────────────────────────────────
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: MainShell(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => NoTransitionPage(
          child: MainShell(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: '/recommendations',
        pageBuilder: (context, state) {
          final movieTitle = state.extra as String?;
          return CustomTransitionPage(
            child: movieTitle != null
                ? RecommendationScreen(initialMovie: movieTitle)
                : MainShell(initialIndex: 2),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) => NoTransitionPage(
          child: MainShell(initialIndex: 3),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => NoTransitionPage(
          child: MainShell(initialIndex: 4),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) {
          final user = state.extra as UserModel?;
          return CustomTransitionPage(
            child: user != null
                ? EditProfileScreen(user: user)
                : const _RedirectToProfile(),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),
      GoRoute(
        path: '/change-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ChangePasswordScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      // ── Movie Details ───────────────────────────────────────────────────
      GoRoute(
        path: '/movie/:id',
        pageBuilder: (context, state) {
          final movieId =
              int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final preloadedMovie = state.extra as Movie?;
          return CustomTransitionPage(
            child: MovieDetailsScreen(
              movieId: movieId,
              preloadedMovie: preloadedMovie,
            ),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),
      GoRoute(
        path: '/genre/:id',
        pageBuilder: (context, state) {
          final genreId = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final genreName = state.extra as String? ?? 'Movies';
          return CustomTransitionPage(
            child: GenreMoviesScreen(genreId: genreId, genreName: genreName),
            transitionsBuilder: _slideUpTransition,
          );
        },
      ),
    ],

    // ── 404 Page ──────────────────────────────────────────────────────────
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFE50914), size: 56),
              const SizedBox(height: 16),
              const Text('Page not found',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home',
                    style: TextStyle(
                        color: Color(0xFFE50914),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
class _RedirectToProfile extends StatefulWidget {
  const _RedirectToProfile();
  @override
  State<_RedirectToProfile> createState() => _RedirectToProfileState();
}

class _RedirectToProfileState extends State<_RedirectToProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) GoRouter.of(context).go('/profile');
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0A0A0A),
    body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
  );
}
// ── Transition helpers ──────────────────────────────────────────────────────
Widget _fadeTransition(
    BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
    BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: FadeTransition(opacity: animation, child: child),
  );
}
