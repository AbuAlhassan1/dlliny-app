import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/controllers/comments/comments_bloc.dart';
import 'package:hangout/presentation/post/widgets/comments_bottom_sheet.dart';

class PostDetailsCommentsSliver extends StatelessWidget {
  final String postId;
  final void Function(String parentCommentId, String authorUsername)
      onStartReply;

  const PostDetailsCommentsSliver({
    super.key,
    required this.postId,
    required this.onStartReply,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommentsBloc, CommentsState>(
      listenWhen: (_, s) =>
          s is AddCommentError || s is CommentsError || s is RepliesError,
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
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1,
                ),
              ),
            ),
          );
        }
        if (bloc.comments.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  LocaleKeys.post_comments_sheet_empty.tr(),
                  style: TextStyle(color: c.onSurfaceSecondary),
                ),
              ),
            ),
          );
        }
        final entries = bloc.flattenedEntries();
        final extra = state is CommentsMoreLoading ? 1 : 0;
        return SliverList.builder(
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
              postId,
              onStartReply,
            );
          },
        );
      },
    );
  }
}
