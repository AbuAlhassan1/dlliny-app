import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/data/repositories/chat_repository.dart';

class VoiceUploadRepository {
  final ChatRepository _chat;
  final Dio _s3 = Dio();
  VoiceUploadRepository(this._chat);

  Future<String> uploadVoice({
    required File audio,
    required String mimeType,
  }) async {
    final presign = await _chat.getVoiceUploadUrl(mimeType);

    try {
      final length = await audio.length();
      await _s3.put(
        presign.uploadUrl,
        data: audio.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': length,
          },
        ),
      );
    } on DioException catch (e) {
      throw ChatTransientException(
        'Voice upload to S3 failed: ${e.message ?? 'network'}',
      );
    }

    return presign.key;
  }
}
