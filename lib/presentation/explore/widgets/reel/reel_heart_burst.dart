import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class ReelHeartBurst extends StatelessWidget {
  final Animation<double> animation;
  const ReelHeartBurst({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          if (t == 0) return const SizedBox.shrink();
          final scale = t < 0.4
              ? Curves.easeOutBack
                          .transform((t / 0.4).clamp(0.0, 1.0)) *
                      0.8 +
                  0.4
              : 1.2;
          final opacity = t < 0.4
              ? 1.0
              : 1.0 - ((t - 0.4) / 0.6).clamp(0.0, 1.0);
          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  TablerIcons.heart_filled,
                  color: c.danger,
                  size: 120,
                  shadows: [
                    Shadow(
                      color: c.mediaSurface.withValues(alpha: 0.5),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
