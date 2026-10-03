import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HangoutMediaIndexIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const HangoutMediaIndexIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SmoothPageIndicator(
          controller: controller,
          count: count,
          effect: WormEffect(
            dotColor: c.onSurface.withValues(alpha: 0.25),
            activeDotColor: c.onSurface.withValues(alpha: 0.85),
            dotHeight: 7,
            dotWidth: 7,
          ),
          onDotClicked: (_) {},
        ),
      ),
    );
  }
}
