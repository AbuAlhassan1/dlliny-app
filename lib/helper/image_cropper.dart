import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

Future<File> cropImageToAspectRatio(File imageFile, double aspectRatio) async {
  final bytes = await imageFile.readAsBytes();
  final src = img.decodeImage(bytes);
  if (src == null) {
    throw const FormatException('Unable to decode image');
  }

  final srcRatio = src.width / src.height;
  final int cropW;
  final int cropH;
  if (srcRatio > aspectRatio) {
    cropH = src.height;
    cropW = (src.height * aspectRatio).round();
  } else {
    cropW = src.width;
    cropH = (src.width / aspectRatio).round();
  }
  final x = ((src.width - cropW) / 2).round();
  final y = ((src.height - cropH) / 2).round();

  final cropped = img.copyCrop(src, x: x, y: y, width: cropW, height: cropH);

  final ext = _extensionOf(imageFile.path);
  final Uint8List out;
  switch (ext) {
    case '.png':
      out = img.encodePng(cropped);
      break;
    case '.jpg':
    case '.jpeg':
    default:
      out = img.encodeJpg(cropped, quality: 90);
  }

  final dir = await getTemporaryDirectory();
  final name =
      'cropped_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
  return File('${dir.path}/$name').writeAsBytes(out);
}

String _extensionOf(String path) {
  final i = path.lastIndexOf('.');
  if (i == -1 || i == path.length - 1) return '';
  return path.substring(i).toLowerCase();
}

Future<File?> cropImageWithUi(
  File imageFile,
  double aspectRatio, {
  String title = 'Crop',
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    aspectRatio: CropAspectRatio(ratioX: aspectRatio, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: title,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null;
  return File(cropped.path);
}
