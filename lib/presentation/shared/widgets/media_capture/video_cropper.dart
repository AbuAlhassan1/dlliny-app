import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

File _passthrough(File file) => file;

Future<File?> centerCropVideoToAspect({
  required File file,
  required CaptureAspectRatio aspect,
}) async {
  return _passthrough(file);
}

Future<File> cropVideoWithLoadingDialog({
  required BuildContext context,
  required File file,
  required CaptureAspectRatio aspect,
}) async {
  return _passthrough(file);
}
