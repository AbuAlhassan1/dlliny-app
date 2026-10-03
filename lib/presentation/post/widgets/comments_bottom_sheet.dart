import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/controllers/comments/comments_bloc.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/post/widgets/comment_tile.dart';

Future<void> showCommentsBottomSheet({
  required BuildContext context,
  required String postId,
  required int initialCommentsCount,
}) {
  final interactions = context.read<PostInteractionsBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => CommentsBloc(
        onCommentCountChanged: (delta) {
          interactions.add(BumpPostCommentsCount(
            postId: postId,
            delta: delta,
            currentCommentsCount: initialCommentsCount,
          ));
        },
      )..add(GetComments(postId)),
      child: _CommentsSheet(postId: postId),
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeFetchMore);
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeFetchMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<CommentsBloc>().add(GetMoreComments(widget.postId));
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<CommentsBloc>();
    bloc.add(AddComment(
      postId: widget.postId,
      body: text,
      parentCommentId: bloc.replyTarget?.parentCommentId,
    ));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _startReply(String parentCommentId, String authorUsername) {
    context.read<CommentsBloc>().add(SetReplyTarget(
      parentCommentId: parentCommentId,
      authorUsername: authorUsername,
    ));
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetController) {
        final c = context.c;
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.post_comments_sheet_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Divider(height: 16, color: c.divider),
              Expanded(
                child: BlocConsumer<CommentsBloc, CommentsState>(
                  listenWhen: (_, s) =>
                      s is AddCommentError ||
                      s is CommentsError ||
                      s is RepliesError,
                  listener: (context, state) {
                    final msg = switch (state) {
                      AddCommentError(:final message) => message,
                      CommentsError(:final message) => message,
                      RepliesError(:final message) => message,
                      _ => null,
                    };
                    if (msg != null) appToast.error(msg);
                  },
                  builder: (context, state) {
                    final c = context.c;
                    final bloc = context.read<CommentsBloc>();
                    if (state is CommentsLoading && bloc.comments.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: c.onSurface,
                          strokeWidth: 1,
                        ),
                      );
                    }
                    if (bloc.comments.isEmpty) {
                      return Center(
                        child: Text(
                          LocaleKeys.post_comments_sheet_empty.tr(),
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      );
                    }
                    final entries = bloc.flattenedEntries();
                    final extra = state is CommentsMoreLoading ? 1 : 0;
                    return ListView.builder(
                      controller: _scroll,
                      itemCount: entries.length + extra,
                      itemBuilder: (context, i) {
                        if (i == entries.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: c.onSurface,
                                strokeWidth: 1,
                              ),
                            ),
                          );
                        }
                        return buildCommentsEntry(
                          context,
                          entries[i],
                          widget.postId,
                          _startReply,
                        );
                      },
                    );
                  },
                ),
              ),
              Divider(height: 1, color: c.divider),
              const CommentsReplyBanner(),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          focusNode: _inputFocus,
                          style: TextStyle(color: c.onSurface),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: LocaleKeys.post_comments_sheet_add_hint.tr(),
                            hintStyle:
                                TextStyle(color: c.onSurfaceMuted),
                            filled: true,
                            fillColor: c.surfaceMuted,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      BlocBuilder<CommentsBloc, CommentsState>(
                        buildWhen: (_, s) =>
                            s is AddingComment || s is CommentAdded,
                        builder: (context, state) {
                          final c = context.c;
                          final busy = state is AddingComment;
                          return IconButton(
                            onPressed: busy ? null : _send,
                            icon: busy
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: c.primary,
                                    ),
                                  )
                                : Icon(
                                    TablerIcons.send,
                                    color: c.primary,
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildCommentsEntry(
  BuildContext context,
  CommentsListEntry entry,
  String postId,
  void Function(String parentCommentId, String authorUsername) onReply,
) {
  final bloc = context.read<CommentsBloc>();
  switch (entry.kind) {
    case CommentsListEntryKind.parent:
      final c = entry.comment!;
      return CommentTile(
        comment: c,
        onDelete: () => bloc.add(
          DeleteComment(postId: postId, commentId: c.id),
        ),
        onReply: () => onReply(c.id, c.author.username),
      );
    case CommentsListEntryKind.reply:
      final c = entry.comment!;
      return CommentTile(
        comment: c,
        isReply: true,
        onDelete: () => bloc.add(
          DeleteComment(postId: postId, commentId: c.id),
        ),
      );
    case CommentsListEntryKind.replyFooter:
      return _RepliesFooter(
        postId: postId,
        parentId: entry.parentId!,
        remaining: entry.remaining,
        loading: entry.loading,
      );
  }
}

class _RepliesFooter extends StatelessWidget {
  final String postId;
  final String parentId;
  final int remaining;
  final bool loading;
  const _RepliesFooter({
    required this.postId,
    required this.parentId,
    required this.remaining,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 52,
        end: 16,
        top: 2,
        bottom: 8,
      ),
      child: InkWell(
        onTap: loading
            ? null
            : () => context.read<CommentsBloc>().add(GetMoreReplies(
                  postId: postId,
                  parentCommentId: parentId,
                )),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: loading
              ? SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    color: c.onSurfaceMuted,
                    strokeWidth: 1,
                  ),
                )
              : Text(
                  LocaleKeys.post_comments_sheet_show_n_more_replies.tr(
                    namedArgs: {'n': '$remaining'},
                  ),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class CommentsReplyBanner extends StatelessWidget {
  const CommentsReplyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      buildWhen: (_, s) => s is ReplyTargetChanged || s is CommentsLoaded,
      builder: (context, _) {
        final c = context.c;
        final target = context.read<CommentsBloc>().replyTarget;
        if (target == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: c.surfaceMuted,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.post_comments_sheet_replying_to.tr(
                    namedArgs: {'username': target.authorUsername},
                  ),
                  style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
                ),
              ),
              InkWell(
                onTap: () =>
                    context.read<CommentsBloc>().add(ClearReplyTarget()),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: c.onSurfaceSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
