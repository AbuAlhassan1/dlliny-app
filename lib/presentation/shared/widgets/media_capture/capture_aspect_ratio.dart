import 'package:image_cropper/image_cropper.dart';

enum CaptureAspectRatio {
  square(1, 1, label: '1:1'),
  portrait(4, 5, label: '4:5'),
  landscape(16, 9, label: '16:9'),
  vertical(9, 16, label: '9:16');

  final int x;
  final int y;
  final String label;

  const CaptureAspectRatio(this.x, this.y, {required this.label});

  double get ratio => x / y;

  CropAspectRatio toCropAspect() =>
      CropAspectRatio(ratioX: x.toDouble(), ratioY: y.toDouble());
}

const List<CaptureAspectRatio> hangoutAspectRatios = [
  CaptureAspectRatio.square,
  CaptureAspectRatio.portrait,
  CaptureAspectRatio.landscape,
];
