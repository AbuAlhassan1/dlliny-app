import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class MemoryProgressBars extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Animation<double> animation;

  const MemoryProgressBars({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: i == 0 ? 0 : 3,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: i < currentIndex
                  ? _Bar(value: 1.0)
                  : i == currentIndex
                      ? AnimatedBuilder(
                          animation: animation,
                          builder: (_, _) => _Bar(value: animation.value),
                        )
                      : _Bar(value: 0.0),
            ),
          ),
        );
      }),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  const _Bar({required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LinearProgressIndicator(
      value: value,
      minHeight: 2.5,
      backgroundColor: c.onMediaSurface.withValues(alpha: 0.4),
      valueColor: AlwaysStoppedAnimation<Color>(c.onMediaSurface),
    );
  }
}
