import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

part 'user_hangouts_event.dart';
part 'user_hangouts_state.dart';

class UserHangoutsBloc extends Bloc<UserHangoutsEvent, UserHangoutsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  PagedResponse<HangoutResponse>? userHangouts;

  UserHangoutsBloc() : super(UserHangoutsInitial()) {
    on<UserHangoutsEvent>((event, emit) {});

    on<GetUserHangouts>((event, emit) async {
      emit(UserHangoutsLoading());

      ApiResponse<PagedResponse<HangoutResponse>> response;
      try {
        response = await apiService.getUserHangouts(
          event.userId,
          page: 0,
          size: 10,
        );
      } on DioException catch (e) {
        emit(UserHangoutsError('Failed to load hangouts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        userHangouts = response.data!;
        emit(UserHangoutsLoaded());
      } else {
        emit(UserHangoutsError(response.error ?? 'Failed to load hangouts'));
      }
    });

    on<GetMoreUserHangouts>((event, emit) async {
      if (userHangouts == null || userHangouts!.last) return;
      emit(UserHangoutsMoreLoading());

      ApiResponse<PagedResponse<HangoutResponse>> response;
      try {
        response = await apiService.getUserHangouts(
          event.userId,
          page: userHangouts!.page + 1,
          size: userHangouts!.size,
        );
      } on DioException catch (e) {
        emit(UserHangoutsMoreError('Failed to load more hangouts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        final newPage = response.data!;
        userHangouts = PagedResponse(
          content: [...userHangouts!.content, ...newPage.content],
          page: newPage.page,
          size: newPage.size,
          totalElements: newPage.totalElements,
          totalPages: newPage.totalPages,
          last: newPage.last,
        );
        emit(UserHangoutsMoreLoaded());
      } else {
        emit(UserHangoutsMoreError(
          response.error ?? 'Failed to load more hangouts',
        ));
      }
    });
  }
}
