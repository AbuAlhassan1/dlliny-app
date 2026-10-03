import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class HeartBurstOverlay extends StatefulWidget {
  final Widget child;
  final HeartBurstController controller;

  const HeartBurstOverlay({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<HeartBurstOverlay> createState() => _HeartBurstOverlayState();
}

class _HeartBurstOverlayState extends State<HeartBurstOverlay>
    with TickerProviderStateMixin {
  final List<_Burst> _bursts = [];

  @override
  void initState() {
    super.initState();
    widget.controller._fire = _spawn;
  }

  @override
  void dispose() {
    widget.controller._fire = null;
    for (final b in _bursts) {
      b.controller.dispose();
    }
    super.dispose();
  }

  void _spawn() {
    final ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final burst = _Burst(controller: ac, particles: _generateParticles());
    setState(() => _bursts.add(burst));
    ac.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _bursts.remove(burst));
      ac.dispose();
    });
  }

  List<_Particle> _generateParticles() {
    final rng = math.Random();
    return List.generate(8, (i) {
      final angle = (i / 8) * 2 * math.pi + rng.nextDouble() * 0.4 - 0.2;
      final distance = 60.0 + rng.nextDouble() * 40;
      return _Particle(
        angle: angle,
        distance: distance,
        size: 14 + rng.nextDouble() * 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        for (final burst in _bursts)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: burst.controller,
              builder: (context, _) {
                final t = burst.controller.value;
                return SizedBox(
                  width: 1,
                  height: 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + t * 1.6,
                          child: const Icon(
                            TablerIcons.heart_filled,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ),
                      for (final p in burst.particles)
                        Transform.translate(
                          offset: Offset(
                            math.cos(p.angle) * p.distance * t,
                            math.sin(p.angle) * p.distance * t,
                          ),
                          child: Opacity(
                            opacity: (1 - t).clamp(0.0, 1.0),
                            child: Icon(
                              TablerIcons.heart_filled,
                              color: Colors.red.withValues(alpha: 0.9),
                              size: p.size * (1 - t * 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class HeartBurstController {
  VoidCallback? _fire;

  void fire() => _fire?.call();
}

class _Burst {
  final AnimationController controller;
  final List<_Particle> particles;
  _Burst({required this.controller, required this.particles});
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
  });
}
