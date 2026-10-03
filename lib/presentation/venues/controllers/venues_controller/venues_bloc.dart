import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'venues_event.dart';
part 'venues_state.dart';

class VenuesBloc extends Bloc<VenuesEvent, VenuesState> {

  final ApiService apiService = serviceLocator.get<ApiService>();

  VenuesBloc() : super(VenuesInitial()) {
    on<VenuesEvent>((event, emit) {});

    on<GetVenuesByBusinessId>((event, emit) async {
      
      emit(GetVenuesLoading());

      ApiResponse<List<BusinessVenueResponse>>? response;

      try {
        response = await apiService.getBusinessVenues(event.businessId);
      } on DioException catch (error) {
        if ( error.response != null && error.response?.data != null) {
          emit(GetVenuesError(error.response?.data['message'] ?? 'حدث خطأ غير متوقع'));
        } else {
          emit(GetVenuesError('حدث خطأ غير متوقع'));
        }
      }

      if ( response != null && response.success && response.data != null) {
        emit(GetVenuesLoaded(response.data!));
      }

      if ( response != null && !response.success) {
        emit(GetVenuesError(response.error ?? 'حدث خطأ غير متوقع'));
      }

    });
  }
}
