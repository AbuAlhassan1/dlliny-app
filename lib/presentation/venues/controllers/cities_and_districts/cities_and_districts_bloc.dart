import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

part 'cities_and_districts_event.dart';
part 'cities_and_districts_state.dart';

class CitiesAndDistrictsBloc
    extends Bloc<CitiesAndDistrictsEvent, CitiesAndDistrictsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  CitiesAndDistrictsBloc() : super(CitiesAndDistrictsInitial()) {
    on<CitiesAndDistrictsEvent>((event, emit) {});

    on<GetCities>((event, emit) async {
      emit(CitiesAndDistrictsLoading());

      ApiResponse<List<CityWithDistrictsDto>>? response;

      try {
        response = await apiService.getCitiesWithDistricts();
      } on DioException catch (error) {
        if (error.response != null && error.response!.data != null) {
          emit(
            CitiesAndDistrictsError(
              error.response!.data['error'] ??
                  'حدث خطأ أثناء جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.',
            ),
          );
        } else {
          emit(
            CitiesAndDistrictsError(
              'حدث خطأ أثناء جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.',
            ),
          );
        }
      }

      if (response != null && response.data != null) {
        emit(CitiesAndDistrictsLoaded(response.data!));
      } else {
        emit(
          CitiesAndDistrictsError(
            'فشل جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.',
          ),
        );
      }
    });
  }
}
