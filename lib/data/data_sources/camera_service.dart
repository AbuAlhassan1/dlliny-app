import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo == null) return null;

    File imageFile = File(photo.path);

    return imageFile;
  }

  Future<File?> takeVideo({
    Duration maxDuration = const Duration(seconds: 60),
  }) async {
    final XFile? clip = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );
    if (clip == null) return null;
    return File(clip.path);
  }
}