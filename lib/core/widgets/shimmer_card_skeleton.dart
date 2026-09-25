import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Shimmer skeleton loader for credit cards and catalog items.
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
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceSecondary,
      highlightColor: AppColors.surfaceElevated,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
    );
  }
}

/// Shimmer list tile skeleton
class ShimmerListSkeleton extends StatelessWidget {
  final int count;

  const ShimmerListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.p12),
      itemBuilder: (_, __) => const ShimmerCardSkeleton(height: 88),
    );
  }
}
