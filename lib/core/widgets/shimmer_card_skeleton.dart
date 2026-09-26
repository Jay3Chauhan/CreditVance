import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Skeleton effect configuration for luxury fintech obsidian theme
const _luxuryShimmerEffect = ShimmerEffect(
  baseColor: AppColors.surfaceSecondary,
  highlightColor: AppColors.surfaceElevated,
  duration: Duration(milliseconds: 1500),
);

/// Skeleton loader for credit cards and preview tiles powered by Skeletonizer.
class ShimmerCardSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerCardSkeleton({
    super.key,
    this.width,
    this.height = 200,
    this.borderRadius = AppDimensions.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _luxuryShimmerEffect,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderSubtle),
        ),
      ),
    );
  }
}

/// Skeleton loader for lists of cards or catalog items powered by Skeletonizer.
class ShimmerListSkeleton extends StatelessWidget {
  final int count;

  const ShimmerListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _luxuryShimmerEffect,
      child: ListView.separated(
        itemCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.p12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(AppDimensions.p16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: AppDimensions.roundedMd,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: const [
              Bone.square(
                size: 44,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: AppDimensions.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone.text(words: 3),
                    SizedBox(height: 6),
                    Bone.text(words: 2),
                  ],
                ),
              ),
              SizedBox(width: AppDimensions.p12),
              Bone.square(
                size: 20,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Luxury credit card skeleton placeholder powered by Skeletonizer.
class LuxuryCreditCardSkeleton extends StatelessWidget {
  const LuxuryCreditCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: _luxuryShimmerEffect,
      child: Container(
        height: 210,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(AppDimensions.p20),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Bone.text(words: 2),
                Bone.square(size: 28),
              ],
            ),
            const SizedBox(height: 16),
            const Bone.text(words: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Bone.text(words: 2),
                Bone.text(words: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
