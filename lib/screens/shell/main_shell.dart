// lib/screens/shell/main_shell.dart
// Bottom navigation bar shell — wraps all main screens with IndexedStack.
// Scaffold background + bottom nav bar are theme-aware (light/dark).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../chat/chat_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    ChatScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navIndexProvider.notifier).state = _currentIndex;
    });
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    ref.read(navIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF5F5F7),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AstraBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Bottom Nav Bar ───────────────────────────────────────────────────────────
class _AstraBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _AstraBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItemData(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    _NavItemData(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'AI',
      isCentre: true,
    ),
    _NavItemData(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF111111) : Colors.white;
    final navBorder = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E5E5);
    final inactiveColor = isDark ? AppColors.textMuted : const Color(0xFF9A9A9A);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(color: navBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _items.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              final isActive = currentIndex == index;

              if (item.isCentre) {
                // Special AI centre button
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                        colors: AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isActive ? null : (isDark ? AppColors.surfaceVariant : const Color(0xFFF0F0F0)),
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                          : null,
                    ),
                    child: Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive ? Colors.white : inactiveColor,
                      size: 22,
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          key: ValueKey('${item.label}_$isActive'),
                          color: isActive
                              ? AppColors.primary
                              : inactiveColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isActive
                              ? AppColors.primary
                              : inactiveColor,
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontFamily: 'Poppins',
                        ),
                        child: Text(item.label),
                      ),
                      // Active indicator dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(top: 3),
                        width: isActive ? 4 : 0,
                        height: isActive ? 4 : 0,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCentre;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCentre = false,
  });
}