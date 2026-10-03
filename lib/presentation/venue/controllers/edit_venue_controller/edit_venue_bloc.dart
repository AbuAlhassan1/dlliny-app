import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/update_business_venue_request.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'edit_venue_event.dart';
part 'edit_venue_state.dart';

class EditVenueBloc extends Bloc<EditVenueEvent, EditVenueState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  EditVenueBloc() : super(EditVenueInitial()) {
    on<EditVenueEvent>((event, emit) {});

    on<EditVenue>((event, emit) async {
      emit(EditVenueLoading());

      ApiResponse<BusinessVenueResponse> response;
      try {
        response = await apiService.updateMyBusinessVenue(
          event.venueId,
          event.request,
        );
      } on DioException catch (e) {
        emit(EditVenueError('فشل التحديث: ${e.message}'));
        return;
      }

      if (response.success && response.data != null) {
        emit(EditVenueSuccess());
      } else {
        emit(EditVenueError(response.error ?? 'فشل التحديث'));
      }
    });
  }
}
