import 'dart:io';

String contentTypeFromFile(File file) {
  final ext = file.path.split('.').last.toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/png',
    'webp' => 'image/webp',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    _ => throw Exception('Unsupported file type: $ext'),
  };
}

String mediaTypeFromContentType(String contentType) =>
    contentType.startsWith('video/') ? 'video' : 'image';
