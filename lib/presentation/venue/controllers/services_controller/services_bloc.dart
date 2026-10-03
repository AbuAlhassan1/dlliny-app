import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/venue_content_response.dart';

part 'services_event.dart';
part 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {

  final ApiService apiService = serviceLocator.get<ApiService>();
  
  ServicesBloc() : super(ServicesInitial()) {
    on<ServicesEvent>((event, emit) {});

    on<GetServices>((event, emit) async {
      
      emit(ServicesLoading());

      ApiResponse<List<VenueServiceItemDto>>? response;

      try {
        response = await apiService.getVenueServices(event.venueId);
      } on DioException catch (error) {
        if ( error.response != null ) {
          emit(ServicesError(error.response?.data['error'] ?? 'حدث خطأ أثناء جلب الخدمات'));
        }
        emit(ServicesError(error.message ?? 'حدث خطأ أثناء جلب الخدمات'));
      }

      if (response != null) {
        if (response.success) {
          emit(ServicesLoaded(response.data ?? []));
        } else {
          emit(ServicesError(response.error ?? 'حدث خطأ أثناء جلب الخدمات'));
        }
      } else {
        emit(ServicesError('حدث خطأ أثناء جلب الخدمات'));
      }

    });
  }
}
