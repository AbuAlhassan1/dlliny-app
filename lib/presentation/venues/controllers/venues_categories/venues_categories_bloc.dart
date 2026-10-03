import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

part 'venues_categories_event.dart';
part 'venues_categories_state.dart';

class VenuesCategoriesBloc extends Bloc<VenuesCategoriesEvent, VenuesCategoriesState> {

  final ApiService apiService = serviceLocator.get<ApiService>();

  VenuesCategoriesBloc() : super(VenuesCategoriesInitial()) {
    on<VenuesCategoriesEvent>((event, emit) {});

    on<GetVenuesCategories>((event, emit) async {
      emit(VenuesCategoriesLoading());
  
      ApiResponse<List<VenueCategoryDto>>? response;

      try{
        response = await apiService.getVenueCategories();
      } on DioException catch (error) {
        if ( error.response != null && error.response!.data != null ){
          emit(VenuesCategoriesError(error.response!.data['error'] ?? 'حدث خطأ أثناء جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.'));
        } else {
          emit(VenuesCategoriesError('حدث خطأ أثناء جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.'));
        }
      }

      if (response != null && response.data != null) {
        emit(VenuesCategoriesLoaded(response.data!));
      } else {
        emit(VenuesCategoriesError('فشل جلب التصنيفات. الرجاء المحاولة مرة أخرى لاحقًا.'));
      }

    });
  }
}
