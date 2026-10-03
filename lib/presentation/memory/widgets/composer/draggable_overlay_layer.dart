import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/memory/bloc/memory_composer/memory_composer_bloc.dart';
import 'package:hangout/presentation/memory/widgets/composer/composer_overlay.dart';
import 'package:hangout/presentation/memory/widgets/composer/text_editor_sheet.dart';

class DraggableOverlayLayer extends StatelessWidget {
  const DraggableOverlayLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) => prev.overlays != curr.overlays,
      builder: (context, state) {
        return Stack(
          children: [
            for (final overlay in state.overlays)
              _DraggableOverlay(
                key: ValueKey(overlay.id),
                overlay: overlay,
              ),
          ],
        );
      },
    );
  }
}

class _DraggableOverlay extends StatefulWidget {
  final ComposerOverlay overlay;

  const _DraggableOverlay({
    super.key,
    required this.overlay,
  });

  @override
  State<_DraggableOverlay> createState() => _DraggableOverlayState();
}

class _DraggableOverlayState extends State<_DraggableOverlay> {
  late Offset _position;
  late double _scale;
  late double _rotation;

  late double _scaleAtStart;
  late double _rotationAtStart;

  bool _gestureActive = false;

  bool _movementStarted = false;

  static const double _moveThreshold = 8;
  static const double _scaleThreshold = 0.02;
  static const double _rotationThreshold = 0.04;

  @override
  void initState() {
    super.initState();
    _position = widget.overlay.position;
    _scale = widget.overlay.scale;
    _rotation = widget.overlay.rotation;
  }

  @override
  void didUpdateWidget(covariant _DraggableOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overlay.position != widget.overlay.position) {
      _position = widget.overlay.position;
    }
    if (oldWidget.overlay.scale != widget.overlay.scale) {
      _scale = widget.overlay.scale;
    }
    if (oldWidget.overlay.rotation != widget.overlay.rotation) {
      _rotation = widget.overlay.rotation;
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _scaleAtStart = _scale;
    _rotationAtStart = _rotation;
    _gestureActive = true;
    _movementStarted = false;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (!_movementStarted) {
      final pointerMoved = d.focalPointDelta.distance > _moveThreshold;
      final pinched = (d.scale - 1.0).abs() > _scaleThreshold;
      final twisted = d.rotation.abs() > _rotationThreshold;
      if (!pointerMoved && !pinched && !twisted) return;
      _movementStarted = true;
    }
    setState(() {
      _position += d.focalPointDelta;
      _scale = (_scaleAtStart * d.scale).clamp(0.3, 3.0);
      _rotation = _rotationAtStart + d.rotation;
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    final moved = _movementStarted;
    _gestureActive = false;
    _movementStarted = false;
    if (!moved) return;
    context.read<MemoryComposerBloc>().add(
          OverlayTransformed(
            id: widget.overlay.id,
            position: _position,
            scale: _scale,
            rotation: _rotation,
          ),
        );
  }

  Future<void> _onTap() async {
    if (_gestureActive && _movementStarted) return;
    final overlay = widget.overlay;
    if (overlay is! TextOverlay) return;
    final result = await showTextOverlayEditor(
      context,
      initialText: overlay.text,
      initialColor: overlay.color,
    );
    if (result == null || !mounted) return;
    context.read<MemoryComposerBloc>().add(
          TextOverlayEdited(
            id: overlay.id,
            text: result.text,
            color: result.color,
          ),
        );
  }

  void _onLongPress() {
    if (_gestureActive && _movementStarted) return;
    HapticFeedback.mediumImpact();
    context.read<MemoryComposerBloc>().add(OverlayRemoved(widget.overlay.id));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Transform.rotate(
        angle: _rotation,
        child: Transform.scale(
          scale: _scale,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            onLongPress: _onLongPress,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: _OverlayVisual(overlay: widget.overlay),
          ),
        ),
      ),
    );
  }
}

class _OverlayVisual extends StatelessWidget {
  final ComposerOverlay overlay;
  const _OverlayVisual({required this.overlay});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    switch (overlay) {
      case TextOverlay(:final text, :final color):
        return Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: c.mediaSurface.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        );
      case MentionOverlay(:final label):
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.onMediaSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: c.mediaSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }
}
