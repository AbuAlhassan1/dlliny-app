import 'package:flutter/material.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

class AspectFrameOverlay extends StatelessWidget {
  final CaptureAspectRatio aspect;

  const AspectFrameOverlay({super.key, required this.aspect});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: aspect.ratio),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (_, ratio, _) =>
            CustomPaint(painter: _AspectMaskPainter(ratio), size: Size.infinite),
      ),
    );
  }
}

class _AspectMaskPainter extends CustomPainter {
  final double ratio;

  const _AspectMaskPainter(this.ratio);

  @override
  void paint(Canvas canvas, Size size) {
    const marginX = 10.0;
    const marginTop = 44.0;
    const marginBottom = 88.0;
    final availW = size.width - marginX * 2;
    final availH = size.height - marginTop - marginBottom;
    if (availW <= 0 || availH <= 0) return;

    double frameW;
    double frameH;
    if (availW / availH > ratio) {
      frameH = availH;
      frameW = frameH * ratio;
    } else {
      frameW = availW;
      frameH = frameW / ratio;
    }

    final centerY = marginTop + availH / 2;
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: frameW,
      height: frameH,
    );
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(16));

    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.4));

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_AspectMaskPainter old) => old.ratio != ratio;
}
