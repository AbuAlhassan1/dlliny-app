import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final placeholderColor = c.onSurface.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.only(top: 5),
      margin: const EdgeInsets.only(bottom: 15),
      child: Shimmer(
        duration: const Duration(milliseconds: 1200),
        color: c.onSurface,
        colorOpacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 15, end: 0),
              child: Row(
                children: [
                  _Circle(size: 45, color: placeholderColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bar(width: 140, height: 12, color: placeholderColor),
                        const SizedBox(height: 4),
                        _Bar(width: 90, height: 10, color: placeholderColor),
                        const SizedBox(height: 4),
                        _Bar(width: 60, height: 9, color: placeholderColor),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _Circle(size: 20, color: placeholderColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(color: placeholderColor),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bar(
                    width: double.infinity,
                    height: 10,
                    color: placeholderColor,
                  ),
                  const SizedBox(height: 6),
                  _Bar(width: 200, height: 10, color: placeholderColor),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Bar(width: 60, height: 12, color: placeholderColor),
                  const SizedBox(width: 10),
                  _Bar(width: 90, height: 12, color: placeholderColor),
                ],
              ),
            ),
            const SizedBox(height: 5),

            Container(width: double.infinity, height: 2, color: placeholderColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Circle(size: 24, color: placeholderColor),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Circle(size: 24, color: placeholderColor),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _Circle(size: 24, color: placeholderColor),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Container(width: double.infinity, height: 6, color: placeholderColor),
          ],
        ),
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
      width: width,
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

class PostSkeletonList extends StatelessWidget {
  final int count;
  const PostSkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) const PostSkeleton(),
      ],
    );
  }
}
