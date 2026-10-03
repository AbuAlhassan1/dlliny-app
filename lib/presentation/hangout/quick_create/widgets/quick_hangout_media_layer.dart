import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';

class QuickHangoutMediaLayer extends StatelessWidget {
  final bool cameraLive;
  final CaptureAspectRatio aspect;
  final ValueChanged<CapturedMedia> onCaptured;

  const QuickHangoutMediaLayer({
    super.key,
    required this.cameraLive,
    required this.aspect,
    required this.onCaptured,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraLive) return ColoredBox(color: context.c.mediaSurface);
    return MediaCaptureCamera(
      fullscreen: true,
      aspect: aspect,
      onAspectChanged: (_) {},
      onCaptured: onCaptured,
    );
  }
}
