import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

enum MemoryUploadSlot { image, video, audio }

class MemoryUploadRepository {
  final MemoryRepository _memory;
  final Dio _s3 = Dio();
  MemoryUploadRepository(this._memory);

  Future<String> upload({
    required File file,
    required String mimeType,
    required MemoryUploadSlot slot,
    String? venueId,
  }) async {
    final presign = await _presign(slot, mimeType, venueId);

    try {
      final length = await file.length();
      await _s3.put(
        presign.uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': length,
          },
        ),
      );
    } on DioException catch (e) {
      throw MemoryTransientException(
        'Memory ${slot.name} upload to S3 failed: ${e.message ?? 'network'}',
      );
    }

    return presign.key;
  }

  Future<MediaUploadUrlResponse> _presign(
    MemoryUploadSlot slot,
    String mimeType,
    String? venueId,
  ) {
    final isVenue = venueId != null;
    return switch (slot) {
      MemoryUploadSlot.image => isVenue
          ? _memory.getVenueImageUploadUrl(venueId, mimeType)
          : _memory.getImageUploadUrl(mimeType),
      MemoryUploadSlot.video => isVenue
          ? _memory.getVenueVideoUploadUrl(venueId, mimeType)
          : _memory.getVideoUploadUrl(mimeType),
      MemoryUploadSlot.audio => isVenue
          ? _memory.getVenueAudioUploadUrl(venueId, mimeType)
          : _memory.getAudioUploadUrl(mimeType),
    };
  }
}
