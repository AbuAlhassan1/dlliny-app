import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'my_businesses_event.dart';
part 'my_businesses_state.dart';

class MyBusinessesBloc extends Bloc<MyBusinessesEvent, MyBusinessesState> {

  final ApiService apiService = serviceLocator.get<ApiService>();

  MyBusinessesBloc() : super(MyBusinessesInitial()) {
    on<MyBusinessesEvent>((event, emit) {});

    on<GetMyBusinesses>((event, emit) async {
      emit(GetMyBusinessesLoading());

      ApiResponse<List<BusinessAccountResponse>>? response;

      try {
        response = await apiService.getMyBusinessAccounts();
      } on DioException catch (error) {
        if ( error.response != null ) {
          if ( error.response!.data.error != null ) {
            emit(GetMyBusinessesError(error.response!.data.error));
          } else {
            emit(GetMyBusinessesError(LocaleKeys.business_load_error.tr()));
          }
        } else {
          emit(GetMyBusinessesError(LocaleKeys.business_load_error.tr()));
        }
      }

      if ( response != null && response.success && response.data != null ) {
        if ( response.data!.isEmpty ) {
          emit(GetMyBusinessesError(
            LocaleKeys.business_empty_no_business_title.tr(),
          ));
          return;
        }
        emit(GetMyBusinessesLoaded(response.data!));
      } else {
        emit(GetMyBusinessesError(response?.error ?? LocaleKeys.business_load_error.tr()));
      }
    });
  }
}
