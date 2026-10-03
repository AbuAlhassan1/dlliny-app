import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';

part 'follow_requests_event.dart';
part 'follow_requests_state.dart';

class FollowRequestsBloc
    extends Bloc<FollowRequestsEvent, FollowRequestsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  List<UserSummaryResponse> requests = [];

  FollowRequestsBloc() : super(FollowRequestsInitial()) {
    on<GetFollowRequests>((event, emit) async {
      emit(FollowRequestsLoading());
      ApiResponse<PagedResponse<UserSummaryResponse>> response;
      try {
        response = await apiService.getMyFollowRequests(page: 0, size: 20);
      } on DioException catch (e) {
        emit(FollowRequestsError('Failed to load: ${e.message}'));
        return;
      }

      if (response.success && response.data != null) {
        requests = response.data!.content;
        emit(FollowRequestsLoaded());
      } else {
        emit(FollowRequestsError(response.error ?? 'Failed to load'));
      }
    });

    on<AcceptFollowRequest>((event, emit) async {
      final index = requests.indexWhere((u) => u.id == event.userId);
      if (index == -1) return;
      final original = List<UserSummaryResponse>.from(requests);
      requests.removeAt(index);
      emit(FollowRequestsLoaded());
      try {
        await apiService.acceptFollowRequest(event.userId);
      } on DioException catch (_) {
        requests = original;
        emit(FollowRequestsLoaded());
      }
    });

    on<RejectFollowRequest>((event, emit) async {
      final index = requests.indexWhere((u) => u.id == event.userId);
      if (index == -1) return;
      final original = List<UserSummaryResponse>.from(requests);
      requests.removeAt(index);
      emit(FollowRequestsLoaded());
      try {
        await apiService.rejectFollowRequest(event.userId);
      } on DioException catch (_) {
        requests = original;
        emit(FollowRequestsLoaded());
      }
    });
  }
}
