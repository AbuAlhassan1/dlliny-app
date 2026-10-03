import 'dart:io';
import 'package:dio/dio.dart';

Future<void> uploadToS3(
  String presignedUrl,
  String contentType,
  File file,
) async {
  final length = await file.length();
  await Dio().put(
    presignedUrl,
    data: file.openRead(),
    options: Options(
      headers: {'Content-Type': contentType, 'Content-Length': length},
    ),
  );
}
