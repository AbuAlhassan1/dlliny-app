import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class ReelScrimLayer extends StatelessWidget {
  const ReelScrimLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final scrim = context.c.mediaSurface;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.18, 0.6, 1.0],
            colors: [
              scrim.withValues(alpha: 0.55),
              Colors.transparent,
              Colors.transparent,
              scrim.withValues(alpha: 0.7),
            ],
          ),
        ),
      ),
    );
  }
}
