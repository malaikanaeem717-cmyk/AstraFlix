// lib/widgets/rating_badge.dart
// Small reusable rating badge widget

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final bool compact;

  const RatingBadge({super.key, required this.rating, this.compact = false});

  Color get _ratingColor {
    if (rating >= 8.0) return const Color(0xFF2ECC71);
    if (rating >= 7.0) return AppColors.secondary;
    if (rating >= 5.0) return const Color(0xFFF39C12);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.glassBlack,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _ratingColor.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: _ratingColor, size: compact ? 9 : 11),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: _ratingColor,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Genre Chip ──────────────────────────────────────────────────────────────
class GenreChip extends StatelessWidget {
  final String genre;
  final bool isSelected;
  final VoidCallback? onTap;

  const GenreChip({
    super.key,
    required this.genre,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF2A2A2A),
            width: 1,
          ),
        ),
        child: Text(
          genre,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ─── Loading Indicator ────────────────────────────────────────────────────────
class AstraLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const AstraLoadingIndicator({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? leading;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Glass Container ──────────────────────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ─── Gradient Button ─────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [AppColors.primaryDark, AppColors.primaryDark]
                : AppColors.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Error Widget ─────────────────────────────────────────────────────────────
class AstraErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AstraErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GradientButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                width: 140,
                height: 44,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty State Widget ───────────────────────────────────────────────────────
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(icon, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: 24),
              GradientButton(
                label: buttonLabel!,
                width: 160,
                height: 44,
                onTap: onButtonTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
