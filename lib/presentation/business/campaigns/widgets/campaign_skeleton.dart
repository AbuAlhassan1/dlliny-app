import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CampaignSkeletonList extends StatelessWidget {
  final int count;
  const CampaignSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final placeholder = c.onSurface.withValues(alpha: 0.08);
    return Shimmer(
      duration: const Duration(milliseconds: 1200),
      color: c.onSurface,
      colorOpacity: 0.1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _SectionHeaderSkeleton(placeholder: placeholder),
          for (var i = 0; i < count; i++) ...[
            _CampaignCardSkeleton(placeholder: placeholder),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  final Color placeholder;
  const _SectionHeaderSkeleton({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Row(
        children: [
          _Circle(size: 10, color: placeholder),
          const SizedBox(width: 8),
          _Bar(width: 110, height: 14, color: placeholder),
          const SizedBox(width: 6),
          _Bar(width: 22, height: 12, color: placeholder),
        ],
      ),
    );
  }
}

class _CampaignCardSkeleton extends StatelessWidget {
  final Color placeholder;
  const _CampaignCardSkeleton({required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Bar(width: 0, height: 15, color: placeholder)),
              const SizedBox(width: 8),
              Container(
                width: 76,
                height: 20,
                decoration: BoxDecoration(
                  color: placeholder,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: placeholder,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Bar(width: 60, height: 13, color: placeholder),
              const SizedBox(width: 6),
              _Bar(width: 80, height: 12, color: placeholder),
              const Spacer(),
              _Circle(size: 14, color: placeholder),
              const SizedBox(width: 4),
              _Bar(width: 20, height: 12, color: placeholder),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const _Bar({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == 0 ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
