import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';

part 'access_event.dart';
part 'access_state.dart';

class AccessBloc extends Bloc<AccessEvent, AccessState> {

  final ApiService apiService = serviceLocator.get<ApiService>();
  ApiResponse<UserAccessResponse>? myAccess;

  AccessBloc() : super(AccessInitial()) {
    on<AccessEvent>((event, emit) {});

    on<GetMyAccess>((event, emit) async {
      emit(AccessLoading());

      ApiResponse<UserAccessResponse>? response;

      try{
        response = await apiService.getMyAccess();
      } on DioException {
        return;
      }

      if ( response.success && response.data != null) {
        myAccess = response;
        emit(AccessLoaded(response: response.data!));
      } else {
        emit(AccessError(message: "حدث خطأ ما، يرجى المحاولة لاحقًا"));
      }

    });
  }
}
