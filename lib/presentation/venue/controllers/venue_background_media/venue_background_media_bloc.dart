import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/network/upload_file_to_s3.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'venue_background_media_event.dart';
part 'venue_background_media_state.dart';

class VenueBackgroundMediaBloc
    extends Bloc<VenueBackgroundMediaEvent, VenueBackgroundMediaState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  VenueBackgroundMediaBloc() : super(VenueBackgroundMediaInitial()) {
    on<UpdateVenueCover>((event, emit) async {
      final contentType = _contentTypeFor(event.file.path);
      if (contentType == null) {
        emit(VenueBackgroundMediaError(
          'Unsupported file type. Use JPEG, PNG, WebP, GIF, MP4, or WebM.',
        ));
        return;
      }

      emit(VenueBackgroundMediaLoading());

      final ApiResponse<VenueMediaUploadResponse> step1;
      try {
        step1 = await apiService.getVenueCoverUploadUrl(
          event.venueId,
          contentType,
        );
      } on DioException catch (_) {
        emit(VenueBackgroundMediaError('Failed to get upload URL'));
        return;
      }
      if (!step1.success || step1.data == null) {
        emit(VenueBackgroundMediaError(
          step1.error ?? 'Failed to get upload URL',
        ));
        return;
      }

      try {
        await uploadToS3(step1.data!.uploadUrl, contentType, event.file);
      } on DioException catch (_) {
        emit(VenueBackgroundMediaError('Failed to upload cover to S3'));
        return;
      }

      final ApiResponse<BusinessVenueResponse> step3;
      try {
        step3 = await apiService.confirmVenueCover(
          event.venueId,
          step1.data!.key,
          contentType,
        );
      } on DioException catch (_) {
        emit(VenueBackgroundMediaError('Failed to confirm cover upload'));
        return;
      }
      if (!step3.success || step3.data == null) {
        emit(VenueBackgroundMediaError(
          step3.error ?? 'Failed to confirm cover upload',
        ));
        return;
      }

      emit(VenueBackgroundMediaLoaded(step3.data!));
    });

    on<DeleteVenueCover>((event, emit) async {
      emit(VenueBackgroundMediaLoading());

      final ApiResponse<BusinessVenueResponse> response;
      try {
        response = await apiService.deleteVenueCover(event.venueId);
      } on DioException catch (_) {
        emit(VenueBackgroundMediaError('Failed to remove cover'));
        return;
      }
      if (!response.success || response.data == null) {
        emit(VenueBackgroundMediaError(
          response.error ?? 'Failed to remove cover',
        ));
        return;
      }

      emit(VenueBackgroundMediaLoaded(response.data!));
    });
  }
}

String? _contentTypeFor(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return null;
  switch (path.substring(dot).toLowerCase()) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.mp4':
      return 'video/mp4';
    case '.webm':
      return 'video/webm';
    case '.mov':
      return 'video/mov';
    default:
      return null;
  }
}
