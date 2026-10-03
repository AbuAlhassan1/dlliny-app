import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class MediaDoubleTapLike extends StatefulWidget {
  final VoidCallback onDoubleTapLike;

  final Widget child;

  const MediaDoubleTapLike({
    super.key,
    required this.onDoubleTapLike,
    required this.child,
  });

  @override
  State<MediaDoubleTapLike> createState() => _MediaDoubleTapLikeState();
}

class _MediaDoubleTapLikeState extends State<MediaDoubleTapLike>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    _burst
      ..reset()
      ..forward();
    widget.onDoubleTapLike();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          _HeartBurst(animation: _burst),
        ],
      ),
    );
  }
}

class _HeartBurst extends StatelessWidget {
  final Animation<double> animation;
  const _HeartBurst({required this.animation});

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
              ? Curves.easeOutBack.transform((t / 0.4).clamp(0.0, 1.0)) *
                      0.8 +
                  0.4
              : 1.2;
          final opacity = t < 0.4
              ? 1.0
              : 1.0 - ((t - 0.4) / 0.6).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                TablerIcons.heart_filled,
                color: c.danger,
                size: 110,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
