import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ReelMediaDots extends StatelessWidget {
  final PageController controller;
  final int count;

  const ReelMediaDots({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    final c = context.c;
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: WormEffect(
        dotColor: c.onMediaSurface.withValues(alpha: 0.35),
        activeDotColor: c.onMediaSurface.withValues(alpha: 0.9),
        dotHeight: 6,
        dotWidth: 6,
      ),
      onDotClicked: (i) => controller.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
