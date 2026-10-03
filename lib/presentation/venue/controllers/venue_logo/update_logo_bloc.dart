import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/network/upload_file_to_s3.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'update_logo_event.dart';
part 'update_logo_state.dart';

class UpdateLogoBloc extends Bloc<UpdateLogoEvent, UpdateLogoState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  UpdateLogoBloc() : super(UpdateLogoInitial()) {
    on<UpdateVenueLogo>((event, emit) async {
      final contentType = _contentTypeFor(event.logo.path);
      if (contentType == null) {
        emit(UpdateLogoError(
          'Unsupported file type. Use JPEG, PNG, or WebP.',
        ));
        return;
      }

      emit(UpdateLogoLoading());

      final ApiResponse<VenueMediaUploadResponse> step1;
      try {
        step1 = await apiService.getVenueLogoUploadUrl(
          event.venueId,
          contentType,
        );
      } on DioException catch (_) {
        emit(UpdateLogoError('Failed to get upload URL'));
        return;
      }
      if (!step1.success || step1.data == null) {
        emit(UpdateLogoError(step1.error ?? 'Failed to get upload URL'));
        return;
      }

      try {
        await uploadToS3(step1.data!.uploadUrl, contentType, event.logo);
      } on DioException catch (_) {
        emit(UpdateLogoError('Failed to upload logo to S3'));
        return;
      }

      final ApiResponse<BusinessVenueResponse> step3;
      try {
        step3 = await apiService.confirmVenueLogo(
          event.venueId,
          step1.data!.key,
        );
      } on DioException catch (_) {
        emit(UpdateLogoError('Failed to confirm logo upload'));
        return;
      }
      if (!step3.success || step3.data == null) {
        emit(UpdateLogoError(step3.error ?? 'Failed to confirm logo upload'));
        return;
      }

      emit(UpdateLogoLoaded(step3.data!));
    });

    on<DeleteVenueLogo>((event, emit) async {
      emit(UpdateLogoLoading());

      final ApiResponse<BusinessVenueResponse> response;
      try {
        response = await apiService.deleteVenueLogo(event.venueId);
      } on DioException catch (_) {
        emit(UpdateLogoError('Failed to remove logo'));
        return;
      }
      if (!response.success || response.data == null) {
        emit(UpdateLogoError(response.error ?? 'Failed to remove logo'));
        return;
      }

      emit(UpdateLogoLoaded(response.data!));
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
    default:
      return null;
  }
}
