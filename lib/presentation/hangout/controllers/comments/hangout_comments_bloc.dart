import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/create_comment_request.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

part 'hangout_comments_event.dart';
part 'hangout_comments_state.dart';

enum HangoutCommentsListEntryKind { parent, reply, replyFooter }

class HangoutCommentsListEntry {
  final HangoutCommentsListEntryKind kind;
  final HangoutCommentResponse? comment;
  final String? parentId;
  final int remaining;
  final bool loading;

  const HangoutCommentsListEntry._({
    required this.kind,
    this.comment,
    this.parentId,
    this.remaining = 0,
    this.loading = false,
  });

  factory HangoutCommentsListEntry.parent(HangoutCommentResponse c) =>
      HangoutCommentsListEntry._(
        kind: HangoutCommentsListEntryKind.parent,
        comment: c,
      );

  factory HangoutCommentsListEntry.reply(
    HangoutCommentResponse c,
    String parentId,
  ) =>
      HangoutCommentsListEntry._(
        kind: HangoutCommentsListEntryKind.reply,
        comment: c,
        parentId: parentId,
      );

  factory HangoutCommentsListEntry.replyFooter({
    required String parentId,
    required int remaining,
    required bool loading,
  }) =>
      HangoutCommentsListEntry._(
        kind: HangoutCommentsListEntryKind.replyFooter,
        parentId: parentId,
        remaining: remaining,
        loading: loading,
      );
}

class HangoutCommentReplyTarget {
  final String parentCommentId;
  final String authorUsername;
  const HangoutCommentReplyTarget({
    required this.parentCommentId,
    required this.authorUsername,
  });
}

class HangoutCommentsBloc
    extends Bloc<HangoutCommentsEvent, HangoutCommentsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  PagedResponse<HangoutCommentResponse>? page;
  List<HangoutCommentResponse> comments = [];
  final Map<String, List<HangoutCommentResponse>> replies = {};
  final Map<String, PagedResponse<HangoutCommentResponse>?> replyPages = {};
  final Set<String> loadingReplies = {};
  HangoutCommentReplyTarget? replyTarget;

  List<HangoutCommentsListEntry> flattenedEntries() {
    final out = <HangoutCommentsListEntry>[];
    for (final parent in comments) {
      out.add(HangoutCommentsListEntry.parent(parent));
      final loaded = replies[parent.id] ?? const <HangoutCommentResponse>[];
      for (final r in loaded) {
        out.add(HangoutCommentsListEntry.reply(r, parent.id));
      }
      final loadingMore = loadingReplies.contains(parent.id);
      final remaining = parent.replyCount - loaded.length;
      if (loadingMore || remaining > 0) {
        out.add(HangoutCommentsListEntry.replyFooter(
          parentId: parent.id,
          remaining: remaining,
          loading: loadingMore,
        ));
      }
    }
    return out;
  }

  HangoutCommentsBloc() : super(HangoutCommentsInitial()) {
    on<HangoutCommentsEvent>((event, emit) {});

    on<GetHangoutComments>((event, emit) async {
      emit(HangoutCommentsLoading());

      ApiResponse<PagedResponse<HangoutCommentResponse>> response;
      try {
        response = await apiService.getHangoutComments(
          event.hangoutId,
          page: 0,
          size: 20,
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(HangoutCommentsError('Failed to load comments'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        page = response.data!;
        comments = response.data!.content;
        replies.clear();
        replyPages.clear();
        loadingReplies.clear();
        emit(HangoutCommentsLoaded());

        for (final c in comments) {
          if (c.replyCount > 0) {
            add(GetHangoutReplies(
              hangoutId: event.hangoutId,
              parentCommentId: c.id,
            ));
          }
        }
      } else {
        emit(HangoutCommentsError(
          response.error ?? 'Failed to load comments',
        ));
      }
    });

    on<GetMoreHangoutComments>((event, emit) async {
      if (page == null || page!.last) return;
      emit(HangoutCommentsMoreLoading());

      ApiResponse<PagedResponse<HangoutCommentResponse>> response;
      try {
        response = await apiService.getHangoutComments(
          event.hangoutId,
          page: page!.page + 1,
          size: page!.size,
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(HangoutCommentsMoreError('Failed to load more comments'));
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
        emit(HangoutCommentsMoreLoaded());

        for (final c in fresh) {
          if (c.replyCount > 0) {
            add(GetHangoutReplies(
              hangoutId: event.hangoutId,
              parentCommentId: c.id,
            ));
          }
        }
      } else {
        emit(HangoutCommentsMoreError(
          response.error ?? 'Failed to load more comments',
        ));
      }
    });

    on<GetHangoutReplies>((event, emit) async {
      if (loadingReplies.contains(event.parentCommentId)) return;
      if (replyPages.containsKey(event.parentCommentId)) return;

      loadingReplies.add(event.parentCommentId);
      emit(HangoutRepliesUpdated(event.parentCommentId));

      ApiResponse<PagedResponse<HangoutCommentResponse>> response;
      try {
        response = await apiService.getHangoutCommentReplies(
          event.hangoutId,
          event.parentCommentId,
          page: 0,
          size: 10,
        );
      } on DioException catch (_) {
        loadingReplies.remove(event.parentCommentId);
        if (emit.isDone) return;
        emit(HangoutRepliesError(
          event.parentCommentId,
          'Failed to load replies',
        ));
        return;
      }

      loadingReplies.remove(event.parentCommentId);
      if (emit.isDone) return;
      if (response.success && response.data != null) {
        replyPages[event.parentCommentId] = response.data;
        replies[event.parentCommentId] = response.data!.content;
        emit(HangoutRepliesUpdated(event.parentCommentId));
      } else {
        emit(HangoutRepliesError(
          event.parentCommentId,
          response.error ?? 'Failed to load replies',
        ));
      }
    });

    on<GetMoreHangoutReplies>((event, emit) async {
      final current = replyPages[event.parentCommentId];
      if (current == null || current.last) return;
      if (loadingReplies.contains(event.parentCommentId)) return;

      loadingReplies.add(event.parentCommentId);
      emit(HangoutRepliesUpdated(event.parentCommentId));

      ApiResponse<PagedResponse<HangoutCommentResponse>> response;
      try {
        response = await apiService.getHangoutCommentReplies(
          event.hangoutId,
          event.parentCommentId,
          page: current.page + 1,
          size: current.size,
        );
      } on DioException catch (_) {
        loadingReplies.remove(event.parentCommentId);
        if (emit.isDone) return;
        emit(HangoutRepliesError(
          event.parentCommentId,
          'Failed to load more replies',
        ));
        return;
      }

      loadingReplies.remove(event.parentCommentId);
      if (emit.isDone) return;
      if (response.success && response.data != null) {
        final newPage = response.data!;
        final combined = <HangoutCommentResponse>[
          ...(replies[event.parentCommentId] ??
              const <HangoutCommentResponse>[]),
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
        emit(HangoutRepliesUpdated(event.parentCommentId));
      } else {
        emit(HangoutRepliesError(
          event.parentCommentId,
          response.error ?? 'Failed to load more replies',
        ));
      }
    });

    on<SetHangoutReplyTarget>((event, emit) {
      replyTarget = HangoutCommentReplyTarget(
        parentCommentId: event.parentCommentId,
        authorUsername: event.authorUsername,
      );
      emit(HangoutReplyTargetChanged());
    });

    on<ClearHangoutReplyTarget>((event, emit) {
      if (replyTarget == null) return;
      replyTarget = null;
      emit(HangoutReplyTargetChanged());
    });

    on<AddHangoutComment>((event, emit) async {
      final trimmed = event.body.trim();
      if (trimmed.isEmpty) return;

      final parentCommentId = event.parentCommentId;

      emit(AddingHangoutComment());

      ApiResponse<HangoutCommentResponse> response;
      try {
        response = await apiService.addHangoutComment(
          event.hangoutId,
          CreateCommentRequest(
            body: trimmed,
            parentCommentId: parentCommentId,
          ),
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(AddHangoutCommentError('Failed to post comment'));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        final created = response.data!;
        if (parentCommentId != null) {
          replies[parentCommentId] = <HangoutCommentResponse>[
            ...(replies[parentCommentId] ??
                const <HangoutCommentResponse>[]),
            created,
          ];
          comments = [
            for (final c in comments)
              if (c.id == parentCommentId)
                HangoutCommentResponse(
                  id: c.id,
                  hangoutId: c.hangoutId,
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
        emit(HangoutCommentAdded());
        emit(HangoutCommentsLoaded());
      } else {
        emit(AddHangoutCommentError(
          response.error ?? 'Failed to post comment',
        ));
      }
    });

    on<DeleteHangoutComment>((event, emit) async {
      final topIndex = comments.indexWhere((c) => c.id == event.commentId);
      if (topIndex != -1) {
        final removed = comments[topIndex];
        comments = [...comments]..removeAt(topIndex);
        replies.remove(event.commentId);
        replyPages.remove(event.commentId);
        emit(HangoutCommentsLoaded());

        try {
          await apiService.deleteHangoutComment(
            event.hangoutId,
            event.commentId,
          );
        } on DioException catch (_) {
          comments = [...comments]..insert(topIndex, removed);
          if (emit.isDone) return;
          emit(HangoutCommentsLoaded());
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
            HangoutCommentResponse(
              id: c.id,
              hangoutId: c.hangoutId,
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
      emit(HangoutRepliesUpdated(parentId));

      try {
        await apiService.deleteHangoutComment(
          event.hangoutId,
          event.commentId,
        );
      } on DioException catch (_) {
        final restored = [...replies[parentId]!]
          ..insert(replyIndex, removed);
        replies[parentId] = restored;
        comments = [
          for (final c in comments)
            if (c.id == parentId)
              HangoutCommentResponse(
                id: c.id,
                hangoutId: c.hangoutId,
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
        emit(HangoutRepliesUpdated(parentId));
      }
    });
  }
}
