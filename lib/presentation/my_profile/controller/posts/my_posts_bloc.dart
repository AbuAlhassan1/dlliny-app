import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

part 'my_posts_event.dart';
part 'my_posts_state.dart';

class MyPostsBloc extends Bloc<MyPostsEvent, MyPostsState> {

  final ApiService apiService = serviceLocator.get<ApiService>();
  PagedResponse<PostResponse>? myPosts;

  void _restoreAt(int index, PostResponse post) {
    final current = myPosts;
    if (current == null) return;
    final restored = [...current.content]..insert(index, post);
    myPosts = PagedResponse(
      content: restored,
      page: current.page,
      size: current.size,
      totalElements: current.totalElements + 1,
      totalPages: current.totalPages,
      last: current.last,
    );
  }

  MyPostsBloc() : super(MyPostsInitial()) {
    on<MyPostsEvent>((event, emit) {});

    on<GetMyPosts>((event, emit) async {

      emit(MyPostsLoading());

      ApiResponse<PagedResponse<PostResponse>> response;

      try{
        response = await apiService.getMyPosts(page: 0, size: 10);
      } on DioException catch (e) {
        emit(MyPostsError('Failed to load posts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        myPosts = response.data!;
        emit(MyPostsLoaded());
      } else {
        emit(MyPostsError('Failed to load posts: ${response.error}'));
      }
    });

    on<DeleteMyPost>((event, emit) async {
      final cached = myPosts;
      if (cached == null) return;
      final index = cached.content.indexWhere((p) => p.id == event.postId);
      if (index == -1) return;

      final removed = cached.content[index];
      final after = [...cached.content]..removeAt(index);
      myPosts = PagedResponse(
        content: after,
        page: cached.page,
        size: cached.size,
        totalElements: (cached.totalElements - 1).clamp(0, 1 << 31),
        totalPages: cached.totalPages,
        last: cached.last,
      );
      emit(MyPostDeleted(event.postId));
      emit(MyPostsLoaded());

      try {
        final res = await apiService.deletePost(event.postId);
        if (!res.success) {
          throw Exception(res.error ?? 'Failed to delete post');
        }
      } on DioException catch (_) {
        _restoreAt(index, removed);
        emit(MyPostDeleteError('Failed to delete post'));
        emit(MyPostsLoaded());
      } catch (e) {
        _restoreAt(index, removed);
        emit(MyPostDeleteError(e.toString()));
        emit(MyPostsLoaded());
      }
    });

    on<ResetMyPosts>((event, emit) {
      myPosts = null;
      emit(MyPostsInitial());
    });

    on<GetMorePosts>((event, emit) async {

      if (myPosts == null || myPosts!.last) return;

      emit(MyPostsMoreLoading());

      ApiResponse<PagedResponse<PostResponse>> response;

      try {
        response = await apiService.getMyPosts(page: myPosts!.page + 1, size: myPosts!.size);
      } on DioException catch (e) {
        emit(MyPostsMoreError('Failed to load more posts: $e'));
        return;
      }

      if (response.success && response.data != null) {
        final newPage = response.data!;
        myPosts = PagedResponse(
          content: [...myPosts!.content, ...newPage.content],
          page: newPage.page,
          size: newPage.size,
          totalElements: newPage.totalElements,
          totalPages: newPage.totalPages,
          last: newPage.last,
        );
        emit(MyPostsMoreLoaded());
      } else {
        emit(MyPostsMoreError('Failed to load more posts: ${response.error}'));
      }
    });
  }
}
