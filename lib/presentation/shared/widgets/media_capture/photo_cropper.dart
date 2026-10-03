import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

Future<File?> openPhotoCropper({
  required File file,
  required CaptureAspectRatio aspect,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: file.path,
    aspectRatio: aspect.toCropAspect(),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'قص الصورة',
        toolbarColor: const Color(0xFF111111),
        toolbarWidgetColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF000000),
        statusBarLight: false,
        activeControlsWidgetColor: const Color(0xFFFFFFFF),
        lockAspectRatio: true,
        hideBottomControls: true,
        initAspectRatio: CropAspectRatioPreset.original,
      ),
      IOSUiSettings(
        title: 'قص الصورة',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
        rotateButtonsHidden: false,
        doneButtonTitle: 'تم',
        cancelButtonTitle: 'إلغاء',
      ),
    ],
  );
  if (cropped == null) return null;
  return File(cropped.path);
}
