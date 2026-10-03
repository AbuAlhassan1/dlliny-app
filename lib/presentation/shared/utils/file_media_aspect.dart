import 'dart:io';

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:video_player/video_player.dart';

Future<double?> readFileMediaAspect(File file, String mediaType) async {
  try {
    if (mediaType == 'image') {
      final bytes = await file.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      final ar = decoded.width / decoded.height;
      decoded.dispose();
      return (ar.isFinite && ar > 0) ? ar : null;
    }
    if (mediaType == 'video') {
      final c = VideoPlayerController.file(file);
      try {
        await c.initialize().timeout(const Duration(seconds: 3));
        final ar = c.value.aspectRatio;
        return (ar.isFinite && ar > 0) ? ar : null;
      } finally {
        await c.dispose();
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
