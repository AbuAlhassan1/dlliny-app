import 'dart:async';

import 'package:flutter/material.dart';

class MountEntrance extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  final double offsetY;
  final Curve curve;

  const MountEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offsetY = 24,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<MountEntrance> createState() => _MountEntranceState();
}

class _MountEntranceState extends State<MountEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _startTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * widget.offsetY),
            child: child,
          ),
        );
      },
    );
  }
}
