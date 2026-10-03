import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/create_comment_request.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

part 'comments_event.dart';
part 'comments_state.dart';

enum CommentsListEntryKind { parent, reply, replyFooter }

class CommentsListEntry {
  final CommentsListEntryKind kind;
  final CommentResponse? comment;
  final String? parentId;
  final int remaining;
  final bool loading;

  const CommentsListEntry._({
    required this.kind,
    this.comment,
    this.parentId,
    this.remaining = 0,
    this.loading = false,
  });

  factory CommentsListEntry.parent(CommentResponse c) => CommentsListEntry._(
    kind: CommentsListEntryKind.parent,
    comment: c,
  );

  factory CommentsListEntry.reply(CommentResponse c, String parentId) =>
      CommentsListEntry._(
        kind: CommentsListEntryKind.reply,
        comment: c,
        parentId: parentId,
      );

  factory CommentsListEntry.replyFooter({
    required String parentId,
    required int remaining,
    required bool loading,
  }) => CommentsListEntry._(
    kind: CommentsListEntryKind.replyFooter,
    parentId: parentId,
    remaining: remaining,
    loading: loading,
  );
}

class CommentReplyTarget {
  final String parentCommentId;
  final String authorUsername;
  const CommentReplyTarget({
    required this.parentCommentId,
    required this.authorUsername,
  });
}

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {

  final ApiService apiService = serviceLocator.get<ApiService>();
  PagedResponse<CommentResponse>? page;
  List<CommentResponse> comments = [];
  final Map<String, List<CommentResponse>> replies = {};
  final Map<String, PagedResponse<CommentResponse>?> replyPages = {};
  final Set<String> loadingReplies = {};
  CommentReplyTarget? replyTarget;

  final void Function(int delta)? onCommentCountChanged;

  List<CommentsListEntry> flattenedEntries() {
    final out = <CommentsListEntry>[];
    for (final parent in comments) {
      out.add(CommentsListEntry.parent(parent));
      final loaded = replies[parent.id] ?? const <CommentResponse>[];
      for (final r in loaded) {
        out.add(CommentsListEntry.reply(r, parent.id));
      }
      final loadingMore = loadingReplies.contains(parent.id);
      final remaining = parent.replyCount - loaded.length;
      if (loadingMore || remaining > 0) {
        out.add(CommentsListEntry.replyFooter(
          parentId: parent.id,
          remaining: remaining,
          loading: loadingMore,
        ));
      }
    }
    return out;
  }

  CommentsBloc({this.onCommentCountChanged}) : super(CommentsInitial()) {
    on<CommentsEvent>((event, emit) {});

    on<GetComments>((event, emit) async {
      emit(CommentsLoading());

      ApiResponse<PagedResponse<CommentResponse>> response;
      try {
        response = await apiService.getComments(
          event.postId,
          page: 0,
          size: 20,
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(CommentsError('Failed to load comments'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        page = response.data!;
        comments = response.data!.content;
        replies.clear();
        replyPages.clear();
        loadingReplies.clear();
        emit(CommentsLoaded());

        for (final c in comments) {
          if (c.replyCount > 0) {
            add(GetReplies(postId: event.postId, parentCommentId: c.id));
          }
        }
      } else {
        emit(CommentsError(response.error ?? 'Failed to load comments'));
      }
    });

    on<GetMoreComments>((event, emit) async {
      if (page == null || page!.last) return;
      emit(CommentsMoreLoading());

      ApiResponse<PagedResponse<CommentResponse>> response;
      try {
        response = await apiService.getComments(
          event.postId,
          page: page!.page + 1,
          size: page!.size,
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(CommentsMoreError('Failed to load more comments'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        final newPage = response.data!;
        final fresh = newPage.content;
        comments = [...comments, ...fresh];
        page = PagedResponse(
          content: comments,
          page: newPage.page,
          size: newPage.size,
          totalElements: newPage.totalElements,
          totalPages: newPage.totalPages,
          last: newPage.last,
        );
        emit(CommentsMoreLoaded());

        for (final c in fresh) {
          if (c.replyCount > 0) {
            add(GetReplies(postId: event.postId, parentCommentId: c.id));
          }
        }
      } else {
        emit(CommentsMoreError(
          response.error ?? 'Failed to load more comments',
        ));
      }
    });

    on<GetReplies>((event, emit) async {
      if (loadingReplies.contains(event.parentCommentId)) return;
      if (replyPages.containsKey(event.parentCommentId)) return;

      loadingReplies.add(event.parentCommentId);
      emit(RepliesUpdated(event.parentCommentId));

      ApiResponse<PagedResponse<CommentResponse>> response;
      try {
        response = await apiService.getCommentReplies(
          event.postId,
          event.parentCommentId,
          page: 0,
          size: 10,
        );
      } on DioException catch (_) {
        loadingReplies.remove(event.parentCommentId);
        if (emit.isDone) return;
        emit(RepliesError(event.parentCommentId, 'Failed to load replies'));
        return;
      }

      loadingReplies.remove(event.parentCommentId);
      if (emit.isDone) return;
      if (response.success && response.data != null) {
        replyPages[event.parentCommentId] = response.data;
        replies[event.parentCommentId] = response.data!.content;
        emit(RepliesUpdated(event.parentCommentId));
      } else {
        emit(RepliesError(
          event.parentCommentId,
          response.error ?? 'Failed to load replies',
        ));
      }
    });

    on<GetMoreReplies>((event, emit) async {
      final current = replyPages[event.parentCommentId];
      if (current == null || current.last) return;
      if (loadingReplies.contains(event.parentCommentId)) return;

      loadingReplies.add(event.parentCommentId);
      emit(RepliesUpdated(event.parentCommentId));

      ApiResponse<PagedResponse<CommentResponse>> response;
      try {
        response = await apiService.getCommentReplies(
          event.postId,
          event.parentCommentId,
          page: current.page + 1,
          size: current.size,
        );
      } on DioException catch (_) {
        loadingReplies.remove(event.parentCommentId);
        if (emit.isDone) return;
        emit(RepliesError(
          event.parentCommentId,
          'Failed to load more replies',
        ));
        return;
      }

      loadingReplies.remove(event.parentCommentId);
      if (emit.isDone) return;
      if (response.success && response.data != null) {
        final newPage = response.data!;
        final combined = <CommentResponse>[
          ...(replies[event.parentCommentId] ?? const <CommentResponse>[]),
          ...newPage.content,
        ];
        replies[event.parentCommentId] = combined;
        replyPages[event.parentCommentId] = PagedResponse(
          content: combined,
          page: newPage.page,
          size: newPage.size,
          totalElements: newPage.totalElements,
          totalPages: newPage.totalPages,
          last: newPage.last,
        );
        emit(RepliesUpdated(event.parentCommentId));
      } else {
        emit(RepliesError(
          event.parentCommentId,
          response.error ?? 'Failed to load more replies',
        ));
      }
    });

    on<SetReplyTarget>((event, emit) {
      replyTarget = CommentReplyTarget(
        parentCommentId: event.parentCommentId,
        authorUsername: event.authorUsername,
      );
      emit(ReplyTargetChanged());
    });

    on<ClearReplyTarget>((event, emit) {
      if (replyTarget == null) return;
      replyTarget = null;
      emit(ReplyTargetChanged());
    });

    on<AddComment>((event, emit) async {
      final trimmed = event.body.trim();
      if (trimmed.isEmpty) return;

      final parentCommentId = event.parentCommentId;

      emit(AddingComment());

      ApiResponse<CommentResponse> response;
      try {
        response = await apiService.addComment(
          event.postId,
          CreateCommentRequest(
            body: trimmed,
            parentCommentId: parentCommentId,
          ),
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(AddCommentError('Failed to post comment'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        final created = response.data!;
        if (parentCommentId != null) {
          replies[parentCommentId] = <CommentResponse>[
            ...(replies[parentCommentId] ?? const <CommentResponse>[]),
            created,
          ];
          comments = [
            for (final c in comments)
              if (c.id == parentCommentId)
                CommentResponse(
                  id: c.id,
                  postId: c.postId,
                  author: c.author,
                  body: c.body,
                  mine: c.mine,
                  createdAt: c.createdAt,
                  parentCommentId: c.parentCommentId,
                  replyCount: c.replyCount + 1,
                )
              else
                c,
          ];
        } else {
          comments = [created, ...comments];
        }
        replyTarget = null;
        emit(CommentAdded());
        emit(CommentsLoaded());
        onCommentCountChanged?.call(1);
      } else {
        emit(AddCommentError(response.error ?? 'Failed to post comment'));
      }
    });

    on<DeleteComment>((event, emit) async {
      final topIndex = comments.indexWhere((c) => c.id == event.commentId);
      if (topIndex != -1) {
        final removed = comments[topIndex];
        final cascadeCount = 1 +
            removed.replyCount.clamp(0, 1 << 31).toInt();
        comments = [...comments]..removeAt(topIndex);
        replies.remove(event.commentId);
        replyPages.remove(event.commentId);
        emit(CommentsLoaded());

        try {
          await apiService.deleteComment(event.postId, event.commentId);
          onCommentCountChanged?.call(-cascadeCount);
        } on DioException catch (_) {
          comments = [...comments]..insert(topIndex, removed);
          if (emit.isDone) return;
          emit(CommentsLoaded());
        }
        return;
      }

      String? parentId;
      int? replyIndex;
      for (final entry in replies.entries) {
        final i = entry.value.indexWhere((c) => c.id == event.commentId);
        if (i != -1) {
          parentId = entry.key;
          replyIndex = i;
          break;
        }
      }
      if (parentId == null || replyIndex == null) return;

      final removed = replies[parentId]![replyIndex];
      final updated = [...replies[parentId]!]..removeAt(replyIndex);
      replies[parentId] = updated;
      comments = [
        for (final c in comments)
          if (c.id == parentId)
            CommentResponse(
              id: c.id,
              postId: c.postId,
              author: c.author,
              body: c.body,
              mine: c.mine,
              createdAt: c.createdAt,
              parentCommentId: c.parentCommentId,
              replyCount: (c.replyCount - 1).clamp(0, 1 << 31).toInt(),
            )
          else
            c,
      ];
      emit(RepliesUpdated(parentId));

      try {
        await apiService.deleteComment(event.postId, event.commentId);
        onCommentCountChanged?.call(-1);
      } on DioException catch (_) {
        final restored = [...replies[parentId]!]..insert(replyIndex, removed);
        replies[parentId] = restored;
        comments = [
          for (final c in comments)
            if (c.id == parentId)
              CommentResponse(
                id: c.id,
                postId: c.postId,
                author: c.author,
                body: c.body,
                mine: c.mine,
                createdAt: c.createdAt,
                parentCommentId: c.parentCommentId,
                replyCount: c.replyCount + 1,
              )
            else
              c,
        ];
        if (emit.isDone) return;
        emit(RepliesUpdated(parentId));
      }
    });
  }
}
