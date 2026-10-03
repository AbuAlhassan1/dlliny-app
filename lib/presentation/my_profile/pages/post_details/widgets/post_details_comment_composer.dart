import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/controllers/comments/comments_bloc.dart';

class PostDetailsCommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const PostDetailsCommentComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: c.onSurface),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: LocaleKeys.post_comments_sheet_add_hint.tr(),
                hintStyle: TextStyle(color: c.onSurfaceMuted),
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
            buildWhen: (_, s) => s is AddingComment || s is CommentAdded,
            builder: (context, state) {
              final busy = state is AddingComment;
              return IconButton(
                onPressed: busy ? null : onSend,
                icon: busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.primary,
                        ),
                      )
                    : Icon(TablerIcons.send, color: c.primary),
              );
            },
          ),
        ],
      ),
    );
  }
}
