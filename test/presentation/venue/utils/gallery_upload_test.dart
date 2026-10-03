import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/utils/thumbhash.dart';
import 'package:hangout/presentation/venue/utils/gallery_upload.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

Uint8List _png(int w, int h) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(120, 90, 60));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: w ~/ 2,
    y2: h,
    color: img.ColorRgb8(30, 60, 150),
  );
  return Uint8List.fromList(img.encodePng(image, level: 1));
}

void main() {
  group('sniffGalleryContentType', () {
    test('reads the magic bytes, not the name', () {
      expect(
        sniffGalleryContentType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(sniffGalleryContentType(_png(2, 2)), 'image/png');
      expect(
        sniffGalleryContentType(
          Uint8List.fromList(ascii.encode('RIFF\x00\x00\x00\x00WEBPVP8 ')),
        ),
        'image/webp',
      );
      expect(
        sniffGalleryContentType(
          Uint8List.fromList(ascii.encode('\x00\x00\x00\x18ftypheic')),
        ),
        isNull,
      );
      expect(
        sniffGalleryContentType(Uint8List.fromList(ascii.encode('GIF89a'))),
        isNull,
      );
      expect(sniffGalleryContentType(Uint8List(0)), isNull);
    });
  });

  group('pickGalleryFiles', () {
    late _MockImagePicker picker;

    setUpAll(() => registerFallbackValue(ImageSource.gallery));

    setUp(() {
      picker = _MockImagePicker();
      when(
        () => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => XFile('/tmp/one.jpg'));
      when(
        () => picker.pickMultiImage(
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [XFile('/tmp/a.jpg'), XFile('/tmp/b.jpg')]);
    });

    test('one slot left → pickImage, never pickMultiImage(limit: 1)', () async {
      final files = await pickGalleryFiles(picker, 1);
      expect(files.map((f) => f.path), ['/tmp/one.jpg']);
      verify(
        () => picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
        ),
      ).called(1);
      verifyNever(
        () => picker.pickMultiImage(
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('a cancelled single pick returns nothing', () async {
      when(
        () => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => null);
      expect(await pickGalleryFiles(picker, 1), isEmpty);
    });

    test('several slots → pickMultiImage limited to the free slots', () async {
      final files = await pickGalleryFiles(picker, 3);
      expect(files, hasLength(2));
      verify(
        () => picker.pickMultiImage(
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
          limit: 3,
        ),
      ).called(1);
    });

    test('no slot → no picker at all', () async {
      expect(await pickGalleryFiles(picker, 0), isEmpty);
      verifyZeroInteractions(picker);
    });
  });

  group('computeGalleryThumbHash', () {
    testWidgets('portrait 1536×2048 hashes a 75×100 decode', (tester) async {
      final seen = <String>[];
      final hash = await tester.runAsync(
        () => computeGalleryThumbHash(
          _png(1536, 2048),
          1536,
          2048,
          encoder: (w, h, rgba) {
            seen.add('${w}x$h');
            return rgbaToThumbHash(w, h, rgba);
          },
        ),
      );
      expect(seen, ['75x100']);
      expect(hash, isNotNull);
      expect(RegExp(r'^[A-Za-z0-9+/]{8,60}={0,2}$').hasMatch(hash!), isTrue);
    });

    testWidgets('landscape 2048×1536 hashes a 100×75 decode', (tester) async {
      final seen = <String>[];
      final hash = await tester.runAsync(
        () => computeGalleryThumbHash(
          _png(2048, 1536),
          2048,
          1536,
          encoder: (w, h, rgba) {
            seen.add('${w}x$h');
            return rgbaToThumbHash(w, h, rgba);
          },
        ),
      );
      expect(seen, ['100x75']);
      expect(hash, isNotNull);
    });

    testWidgets('a failing encoder yields null, never an exception', (
      tester,
    ) async {
      final hash = await tester.runAsync(
        () => computeGalleryThumbHash(
          _png(300, 400),
          300,
          400,
          encoder: (_, _, _) => throw StateError('boom'),
        ),
      );
      expect(hash, isNull);
    });

    testWidgets('undecodable bytes yield null', (tester) async {
      final hash = await tester.runAsync(
        () => computeGalleryThumbHash(Uint8List.fromList([1, 2, 3]), 10, 10),
      );
      expect(hash, isNull);
    });
  });

  group('prepareGalleryFile', () {
    testWidgets('measures the decoded size and hashes it', (tester) async {
      final prepared = await tester.runAsync(
        () => prepareGalleryFile(XFile.fromData(_png(300, 400), name: 'a.png')),
      );
      expect(prepared!.contentType, 'image/png');
      expect(prepared.width, 300);
      expect(prepared.height, 400);
      expect(prepared.placeholderHash, isNotNull);
    });

    testWidgets('a HEIC / unknown file is unsupported (no upload)', (
      tester,
    ) async {
      final error = await tester.runAsync(() async {
        try {
          await prepareGalleryFile(
            XFile.fromData(
              Uint8List.fromList(ascii.encode('\x00\x00\x00\x18ftypheic')),
            ),
          );
          return null;
        } on GalleryUploadException catch (e) {
          return e.code;
        }
      });
      expect(error, VenueErrorCodes.galleryUnsupportedType);
    });

    testWidgets('a banner wider than 5:1 is rejected before uploading', (
      tester,
    ) async {
      final error = await tester.runAsync(() async {
        try {
          await prepareGalleryFile(XFile.fromData(_png(600, 100)));
          return null;
        } on GalleryUploadException catch (e) {
          return e.code;
        }
      });
      expect(error, VenueErrorCodes.galleryDimensionsInvalid);
    });
  });
}
