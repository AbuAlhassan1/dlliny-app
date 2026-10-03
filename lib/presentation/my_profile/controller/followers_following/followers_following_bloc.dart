import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';

part 'followers_following_event.dart';
part 'followers_following_state.dart';

enum FollowKind { followers, following }

class FollowersFollowingBloc
    extends Bloc<FollowersFollowingEvent, FollowersFollowingState> {
  final FollowKind kind;
  final ApiService apiService = serviceLocator.get<ApiService>();

  PagedResponse<UserSummaryResponse>? page;
  List<UserSummaryResponse> users = [];

  FollowersFollowingBloc(this.kind) : super(FollowersFollowingInitial()) {
    on<FollowersFollowingEvent>((event, emit) {});

    on<GetFollowList>((event, emit) async {
      emit(FollowersFollowingLoading());

      ApiResponse<PagedResponse<UserSummaryResponse>> response;
      try {
        response = await _fetch(page: 0, size: 20);
      } on DioException catch (e) {
        emit(FollowersFollowingError('Failed to load: ${e.message}'));
        return;
      }

      if (response.success && response.data != null) {
        page = response.data!;
        users = response.data!.content;
        emit(FollowersFollowingLoaded());
      } else {
        emit(FollowersFollowingError(response.error ?? 'Failed to load'));
      }
    });

    on<GetMoreFollowList>((event, emit) async {
      if (page == null || page!.last) return;
      emit(FollowersFollowingMoreLoading());

      ApiResponse<PagedResponse<UserSummaryResponse>> response;
      try {
        response = await _fetch(page: page!.page + 1, size: page!.size);
      } on DioException catch (e) {
        emit(FollowersFollowingMoreError('Failed to load more: ${e.message}'));
        return;
      }

      if (response.success && response.data != null) {
        final next = response.data!;
        users = [...users, ...next.content];
        page = PagedResponse(
          content: users,
          page: next.page,
          size: next.size,
          totalElements: next.totalElements,
          totalPages: next.totalPages,
          last: next.last,
        );
        emit(FollowersFollowingMoreLoaded());
      } else {
        emit(FollowersFollowingMoreError(
          response.error ?? 'Failed to load more',
        ));
      }
    });
  }

  Future<ApiResponse<PagedResponse<UserSummaryResponse>>> _fetch({
    required int page,
    required int size,
  }) {
    return switch (kind) {
      FollowKind.followers =>
        apiService.getMyFollowers(page: page, size: size),
      FollowKind.following =>
        apiService.getMyFollowing(page: page, size: size),
    };
  }
}
