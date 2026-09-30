// lib/widgets/shimmer_loading.dart
// Shimmer effect loading placeholders for movie cards and sections

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class ShimmerMovieCard extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerMovieCard({
    super.key,
    this.width = 130,
    this.height = 195,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class ShimmerMovieRow extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final int count;

  const ShimmerMovieRow({
    super.key,
    this.cardWidth = 130,
    this.cardHeight = 195,
    this.count = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title shimmer
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surfaceVariant,
            highlightColor: const Color(0xFF2A2A2A),
            child: Container(
              width: 140,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        // Cards
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) =>
                ShimmerMovieCard(width: cardWidth, height: cardHeight),
          ),
        ),
      ],
    );
  }
}

class ShimmerHeroBanner extends StatelessWidget {
  const ShimmerHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        height: 520,
        color: AppColors.surfaceVariant,
      ),
    );
  }
}

class ShimmerMovieDetail extends StatelessWidget {
  const ShimmerMovieDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceVariant,
      highlightColor: const Color(0xFF2A2A2A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(height: 300, color: AppColors.surfaceVariant),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description lines
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: i == 3 ? 200 : double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
