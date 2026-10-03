import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

part 'my_hangouts_event.dart';
part 'my_hangouts_state.dart';

class MyHangoutsBloc extends Bloc<MyHangoutsEvent, MyHangoutsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  List<HangoutResponse> myHangouts = [];

  MyHangoutsBloc() : super(MyHangoutsInitial()) {
    on<MyHangoutsEvent>((event, emit) {});

    on<ResetMyHangouts>((event, emit) {
      myHangouts = [];
      emit(MyHangoutsInitial());
    });

    on<GetMoreHangouts>((event, emit) async {
    });

    on<GetMyHangouts>((event, emit) async {
      emit(MyHangoutsLoading());

      ApiResponse<List<HangoutResponse>> response;

      try {
        response = await apiService.getMyHangouts();
      } on DioException catch (e) {
        emit(MyHangoutsError('Failed to load hangouts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        myHangouts = response.data!;
        emit(MyHangoutsLoaded());
      } else {
        emit(MyHangoutsError('Failed to load hangouts: ${response.error}'));
      }
    });
  }
}
