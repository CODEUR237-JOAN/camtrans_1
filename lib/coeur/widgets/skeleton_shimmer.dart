import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkeletonShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Fond gris sombre "Neo Dark"
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.1),
          angle: 1.0, 
        );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10192A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonShimmer(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonShimmer(width: double.infinity, height: 16),
                SizedBox(height: 8),
                SkeletonShimmer(width: 150, height: 12),
                SizedBox(height: 8),
                SkeletonShimmer(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
