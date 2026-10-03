import 'dart:io';

import 'package:file_picker/file_picker.dart';

Future<File?> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    } else {
      return null;
    }
  }

Future<File?> pickMedia() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.media,
    allowMultiple: false,
  );
  if (result != null && result.files.single.path != null) {
    return File(result.files.single.path!);
  }
  return null;
}

bool isVideoFile(File file) {
  final ext = file.path.toLowerCase().split('.').last;
  return const {'mp4', 'mov', 'm4v', 'webm', 'qt'}.contains(ext);
}