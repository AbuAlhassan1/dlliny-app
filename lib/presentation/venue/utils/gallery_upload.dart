import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:hangout/core/utils/thumbhash.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:image_picker/image_picker.dart';

const double kGalleryPickMaxSide = 2560;
const int kGalleryPickQuality = 85;

const int kGalleryMaxAspect = 5;

class GalleryUploadException implements Exception {
  final String code;
  const GalleryUploadException(this.code);

  @override
  String toString() => 'GalleryUploadException($code)';
}

class PreparedGalleryFile {
  final Uint8List bytes;
  final String contentType;
  final int width;
  final int height;
  final String? placeholderHash;

  const PreparedGalleryFile({
    required this.bytes,
    required this.contentType,
    required this.width,
    required this.height,
    this.placeholderHash,
  });
}

Future<List<XFile>> pickGalleryFiles(ImagePicker picker, int remaining) async {
  if (remaining <= 0) return const [];
  if (remaining == 1) {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: kGalleryPickMaxSide,
      maxHeight: kGalleryPickMaxSide,
      imageQuality: kGalleryPickQuality,
    );
    return [?file];
  }
  return picker.pickMultiImage(
    maxWidth: kGalleryPickMaxSide,
    maxHeight: kGalleryPickMaxSide,
    imageQuality: kGalleryPickQuality,
    limit: remaining,
  );
}

String? sniffGalleryContentType(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return 'image/jpeg';
  }
  const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (b.length >= png.length) {
    var match = true;
    for (var i = 0; i < png.length; i++) {
      if (b[i] != png[i]) {
        match = false;
        break;
      }
    }
    if (match) return 'image/png';
  }
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

Future<PreparedGalleryFile> prepareGalleryFile(XFile file) async {
  final bytes = await file.readAsBytes();
  final contentType = sniffGalleryContentType(bytes);
  if (contentType == null) {
    throw const GalleryUploadException(VenueErrorCodes.galleryUnsupportedType);
  }
  if (bytes.length > kGalleryMaxBytes) {
    throw const GalleryUploadException(VenueErrorCodes.galleryTooLarge);
  }

  final int width;
  final int height;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    width = frame.image.width;
    height = frame.image.height;
    frame.image.dispose();
    codec.dispose();
  } catch (_) {
    throw const GalleryUploadException(VenueErrorCodes.galleryUnsupportedType);
  }
  if (math.max(width, height) > kGalleryMaxAspect * math.min(width, height)) {
    throw const GalleryUploadException(
      VenueErrorCodes.galleryDimensionsInvalid,
    );
  }

  return PreparedGalleryFile(
    bytes: bytes,
    contentType: contentType,
    width: width,
    height: height,
    placeholderHash: await computeGalleryThumbHash(bytes, width, height),
  );
}

final RegExp _placeholderPattern = RegExp(r'^[A-Za-z0-9+/]{8,60}={0,2}$');

Future<String?> computeGalleryThumbHash(
  Uint8List bytes,
  int width,
  int height, {
  Uint8List Function(int w, int h, Uint8List rgba) encoder = rgbaToThumbHash,
}) async {
  try {
    final longer = math.max(width, height);
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: math.max(1, (100 * width / longer).round()),
      targetHeight: math.max(1, (100 * height / longer).round()),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width;
    final h = image.height;
    image.dispose();
    codec.dispose();
    if (data == null) return null;
    final hash = base64Encode(encoder(w, h, data.buffer.asUint8List()));
    return _placeholderPattern.hasMatch(hash) ? hash : null;
  } catch (_) {
    return null;
  }
}
