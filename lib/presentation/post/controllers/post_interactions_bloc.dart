import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/report_post_request.dart';

part 'post_interactions_event.dart';
part 'post_interactions_state.dart';

class PostInteractionsBloc
    extends Bloc<PostInteractionsEvent, PostInteractionsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  final Map<String, PostInteractionOverlay> _overlays = {};

  bool likedByMe(String postId, bool fallback) =>
      _overlays[postId]?.likedByMe ?? fallback;

  int likesCount(String postId, int fallback) =>
      _overlays[postId]?.likesCount ?? fallback;

  int commentsCount(String postId, int fallback) =>
      _overlays[postId]?.commentsCount ?? fallback;

  PostInteractionsBloc() : super(PostInteractionsInitial()) {
    on<PostInteractionsEvent>((event, emit) {});

    on<ToggleLike>((event, emit) async {
      final existing = _overlays[event.postId];
      final liked = existing?.likedByMe ?? event.currentLikedByMe;
      final count = existing?.likesCount ?? event.currentLikesCount;

      final base = existing ?? const PostInteractionOverlay();
      _overlays[event.postId] = base.copyWith(
        likedByMe: !liked,
        likesCount: count + (liked ? -1 : 1),
      );
      emit(PostInteractionUpdated(event.postId));

      try {
        if (!liked) {
          await apiService.likePost(event.postId);
        } else {
          await apiService.unlikePost(event.postId);
        }
      } on DioException catch (_) {
        _overlays[event.postId] = base.copyWith(
          likedByMe: liked,
          likesCount: count,
        );
        emit(PostInteractionUpdated(event.postId));
      }
    });

    on<BumpPostCommentsCount>((event, emit) {
      final existing = _overlays[event.postId];
      final current =
          existing?.commentsCount ?? event.currentCommentsCount;
      final next = (current + event.delta).clamp(0, 1 << 31).toInt();
      _overlays[event.postId] =
          (existing ?? const PostInteractionOverlay())
              .copyWith(commentsCount: next);
      emit(PostInteractionUpdated(event.postId));
    });

    on<SubmitPostReport>((event, emit) async {
      emit(ReportSubmitting());
      try {
        final res = await apiService.reportPost(
          event.postId,
          ReportPostRequest(
            categoryId: event.categoryId,
            description: event.description,
          ),
        );
        if (res.success) {
          emit(ReportSubmitted());
        } else {
          emit(ReportFailed(res.error ?? 'Failed to submit report'));
        }
      } on DioException catch (_) {
        emit(ReportFailed('Failed to submit report'));
      }
    });
  }
}
