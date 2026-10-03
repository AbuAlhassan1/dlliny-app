import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

part 'user_posts_event.dart';
part 'user_posts_state.dart';

class UserPostsBloc extends Bloc<UserPostsEvent, UserPostsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  PagedResponse<PostResponse>? userPosts;

  UserPostsBloc() : super(UserPostsInitial()) {
    on<UserPostsEvent>((event, emit) {});

    on<GetUserPosts>((event, emit) async {
      emit(UserPostsLoading());

      ApiResponse<PagedResponse<PostResponse>> response;
      try {
        response = await apiService.getUserPosts(
          event.userId,
          page: 0,
          size: 10,
        );
      } on DioException catch (e) {
        emit(UserPostsError('Failed to load posts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        userPosts = response.data!;
        emit(UserPostsLoaded());
      } else {
        emit(UserPostsError(response.error ?? 'Failed to load posts'));
      }
    });

    on<GetMoreUserPosts>((event, emit) async {
      if (userPosts == null || userPosts!.last) return;
      emit(UserPostsMoreLoading());

      ApiResponse<PagedResponse<PostResponse>> response;
      try {
        response = await apiService.getUserPosts(
          event.userId,
          page: userPosts!.page + 1,
          size: userPosts!.size,
        );
      } on DioException catch (e) {
        emit(UserPostsMoreError('Failed to load more posts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        final newPage = response.data!;
        userPosts = PagedResponse(
          content: [...userPosts!.content, ...newPage.content],
          page: newPage.page,
          size: newPage.size,
          totalElements: newPage.totalElements,
          totalPages: newPage.totalPages,
          last: newPage.last,
        );
        emit(UserPostsMoreLoaded());
      } else {
        emit(UserPostsMoreError(
          response.error ?? 'Failed to load more posts',
        ));
      }
    });
  }
}
