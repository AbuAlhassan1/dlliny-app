import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/confirm_hangout_media_request.dart';
import 'package:hangout/domain/dto/request/create_hangout_request.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:hangout/presentation/shared/utils/file_media_aspect.dart';

part 'create_hangout_event.dart';
part 'create_hangout_state.dart';

class CreateHangoutBloc extends Bloc<CreateHangoutEvent, CreateHangoutState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  CreateHangoutBloc() : super(CreateHangoutInitial()) {
    on<AddNewHangout>((event, emit) async {
      emit(CreateHangoutLoading());

      final venueId = event.asVenueId;

      ApiResponse<HangoutResponse> createResp;
      try {
        createResp = venueId != null
            ? await apiService.createVenueHangout(venueId, event.body)
            : await apiService.createHangout(event.body);
      } on DioException catch (e) {
        emit(CreateHangoutError('Failed to create hangout: ${e.message}'));
        return;
      }

      if (!createResp.success || createResp.data == null) {
        emit(CreateHangoutError('Failed to create hangout: ${createResp.error}'));
        return;
      }

      final hangout = createResp.data!;

      if (event.files != null) {
        for (int i = 0; i < event.files!.length; i++) {
          final file = event.files![i];
          final String contentType = contentTypeFromFile(file);

          try {
            final urlResp = await apiService.getHangoutMediaUploadUrl(hangout.id, contentType);
            final uploadUrl = urlResp.data!.uploadUrl;
            final key = urlResp.data!.key;

            final bytes = await file.readAsBytes();
            await Dio().put(
              uploadUrl,
              data: Stream.fromIterable([bytes]),
              options: Options(
                headers: {
                  'Content-Type': contentType,
                  'Content-Length': bytes.length,
                },
              ),
            );

            final mediaType = mediaTypeFromContentType(contentType);
            final aspectRatio = await readFileMediaAspect(file, mediaType);

            await apiService.confirmHangoutMedia(
              hangout.id,
              ConfirmHangoutMediaRequest(
                key: key,
                mediaType: mediaType,
                sortOrder: i,
                aspectRatio: aspectRatio,
              ),
            );
          } on DioException catch (e) {
            emit(CreateHangoutError('Failed to upload media: ${e.message}'));
            return;
          }
        }
      }

      emit(CreateHangoutSuccess(hangout));
    });
  }
}
