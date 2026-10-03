import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class GradientShadow extends StatelessWidget {
  const GradientShadow({super.key});

  @override
  Widget build(BuildContext context) {
    final scrim = context.c.mediaSurface;
    return Positioned(
      bottom: -5,
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                scrim,
                scrim.withAlpha(120),
                scrim.withAlpha(100),
                scrim.withAlpha(20),
                scrim.withAlpha(2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
