// lib/screens/profile/profile_screen.dart
// User profile with stats, account settings, and logout — sections stay
// separate (not one big card), just width-constrained and centered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_badge.dart';
import '../../widgets/floating_icons_background.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);

    return FloatingIconsBackground(
      child: authState.when(
        data: (firebaseUser) {
          if (firebaseUser == null) return _buildSignedOutState(context);
          return userAsync.when(
            data: (user) => user != null ? _ProfileBody(user: user) : _buildLoadingState(),
            loading: () => _buildLoadingState(),
            error: (_, __) => _buildLoadingState(),
          );
        },
        loading: () => _buildLoadingState(),
        error: (_, __) => _buildSignedOutState(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: AstraLoadingIndicator());
  }

  Widget _buildSignedOutState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline, size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Text('Not signed in',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              const Text('Sign in to access your profile and sync your data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontFamily: 'Poppins')),
              const SizedBox(height: 24),
              GradientButton(label: 'Sign In', icon: Icons.login_rounded, width: 180, onTap: () => context.go('/login')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out of AstraFlix?', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins', fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authServiceProvider).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _AvatarHeader(user: user).animate().fadeIn()),
                SliverToBoxAdapter(child: _StatsSection(user: user).animate().fadeIn(delay: 100.ms)),
                SliverToBoxAdapter(
                  child: _SettingsSection(
                    user: user,
                    onLogout: () => _handleLogout(context, ref),
                  ).animate().fadeIn(delay: 200.ms),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final UserModel user;
  const _AvatarHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => context.push('/edit-profile', extra: user),
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: AppColors.primaryGradient),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: user.photoUrl != null
                      ? ClipOval(child: CachedNetworkImage(imageUrl: user.photoUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _initialsAvatar()))
                      : _initialsAvatar(),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 2)),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(user.displayName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins')),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  user.createdAt != null ? 'Member since ${user.createdAt!.year}' : 'AstraFlix Member',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final UserModel user;
  const _StatsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Your Stats', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
          Row(
            children: [
              Expanded(child: _statCard('Movies Watched', user.stats.moviesWatched.toString(), Icons.movie_rounded, AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Favorites', user.stats.moviesFavorited.toString(), Icons.favorite_rounded, AppColors.error)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _statCard('Movies Rated', user.stats.moviesRated.toString(), Icons.star_rounded, AppColors.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Watchlist', user.watchlistIds.length.toString(), Icons.bookmark_rounded, AppColors.tertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onLogout;
  const _SettingsSection({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final darkModeEnabled = ref.watch(darkModeEnabledProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Account', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              children: [
                _settingTile(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => context.push('/edit-profile', extra: user)),
                _divider(),
                _settingTile(icon: Icons.lock_outline_rounded, label: 'Change Password', onTap: () => context.push('/change-password')),
                _divider(),
                _settingTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  trailing: Switch(value: notificationsEnabled, onChanged: (v) => ref.read(notificationsEnabledProvider.notifier).set(v), activeColor: AppColors.primary),
                  onTap: () => ref.read(notificationsEnabledProvider.notifier).set(!notificationsEnabled),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark Mode',
                  trailing: Switch(value: darkModeEnabled, onChanged: (v) => ref.read(darkModeEnabledProvider.notifier).set(v), activeColor: AppColors.primary),
                  onTap: () => ref.read(darkModeEnabledProvider.notifier).set(!darkModeEnabled),
                ),
                _divider(),
                _settingTile(icon: Icons.info_outline_rounded, label: 'About AstraFlix', onTap: () => _showAbout(context)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 10),
                  Text('Sign Out', style: TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('AstraFlix v1.0.0 • Made with ❤️', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'Poppins'))),
        ],
      ),
    );
  }

  Widget _settingTile({required IconData icon, required String label, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFF2A2A2A), indent: 56);

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About AstraFlix', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'AstraFlix v1.0.0\n\nAn AI-powered movie recommendation app built with Flutter and FastAPI.\n\nMovie data provided by TMDB.',
          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.6),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins')))],
      ),
    );
  }
}