import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/hangout/controllers/comments/hangout_comments_bloc.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comments_bottom_sheet.dart';
import 'package:wave_divider/wave_divider.dart';

class HangoutDetailsCommentsSection extends StatefulWidget {
  final String hangoutId;
  const HangoutDetailsCommentsSection({super.key, required this.hangoutId});

  @override
  State<HangoutDetailsCommentsSection> createState() =>
      _HangoutDetailsCommentsSectionState();
}

class _HangoutDetailsCommentsSectionState
    extends State<HangoutDetailsCommentsSection> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<HangoutCommentsBloc>();
    bloc.add(AddHangoutComment(
      hangoutId: widget.hangoutId,
      body: text,
      parentCommentId: bloc.replyTarget?.parentCommentId,
    ));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _startReply(String parentCommentId, String authorUsername) {
    context.read<HangoutCommentsBloc>().add(SetHangoutReplyTarget(
          parentCommentId: parentCommentId,
          authorUsername: authorUsername,
        ));
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<HangoutCommentsBloc, HangoutCommentsState>(
      listenWhen: (_, s) =>
          s is AddHangoutCommentError ||
          s is HangoutCommentsError ||
          s is HangoutRepliesError,
      listener: (context, state) {
        final msg = switch (state) {
          AddHangoutCommentError(:final message) => message,
          HangoutCommentsError(:final message) => message,
          HangoutRepliesError(:final message) => message,
          _ => null,
        };
        if (msg != null) appToast.error(msg);
      },
      buildWhen: (_, s) =>
          s is HangoutCommentsInitial ||
          s is HangoutCommentsLoading ||
          s is HangoutCommentsLoaded ||
          s is HangoutCommentsMoreLoading ||
          s is HangoutRepliesUpdated,
      builder: (context, state) {
        final bloc = context.read<HangoutCommentsBloc>();
        final entries = bloc.flattenedEntries();
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 6),
                child: Row(
                  children: [
                    Icon(TablerIcons.messages, color: c.onSurface, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      LocaleKeys.hangout_comments_sheet_title.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: WaveDivider(
                color: c.divider,
                padding: EdgeInsets.zero,
                thickness: 1,
                waveHeight: 1,
              ),
            ),
            _CommentsListSliver(
              state: state,
              hangoutId: widget.hangoutId,
              comments: bloc.comments.length,
              entries: entries,
              onStartReply: _startReply,
            ),
            SliverToBoxAdapter(
              child: WaveDivider(
                color: c.divider,
                padding: EdgeInsets.zero,
                thickness: 1,
                waveHeight: 1,
              ),
            ),
            const SliverToBoxAdapter(child: HangoutCommentsReplyBanner()),
            SliverToBoxAdapter(
              child: SafeArea(
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
                            hintText: LocaleKeys
                                .hangout_comments_sheet_add_hint
                                .tr(),
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
                      BlocBuilder<HangoutCommentsBloc, HangoutCommentsState>(
                        buildWhen: (_, s) =>
                            s is AddingHangoutComment ||
                            s is HangoutCommentAdded,
                        builder: (context, state) {
                          final busy = state is AddingHangoutComment;
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
                                : Icon(TablerIcons.send, color: c.primary),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentsListSliver extends StatelessWidget {
  final HangoutCommentsState state;
  final String hangoutId;
  final int comments;
  final List<HangoutCommentsListEntry> entries;
  final void Function(String parentCommentId, String authorUsername)
      onStartReply;
  const _CommentsListSliver({
    required this.state,
    required this.hangoutId,
    required this.comments,
    required this.entries,
    required this.onStartReply,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (state is HangoutCommentsLoading && comments == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: CircularProgressIndicator(
              color: c.onSurface,
              strokeWidth: 1,
            ),
          ),
        ),
      );
    }
    if (comments == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Text(
              LocaleKeys.hangout_comments_sheet_empty.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) => buildHangoutCommentsEntry(
            context,
            entries[i],
            hangoutId,
            onStartReply,
          ),
        ),
        SliverToBoxAdapter(
          child: BlocBuilder<HangoutCommentsBloc, HangoutCommentsState>(
            buildWhen: (_, s) =>
                s is HangoutCommentsMoreLoading ||
                s is HangoutCommentsLoaded,
            builder: (context, s) {
              final bloc = context.read<HangoutCommentsBloc>();
              final hasMore = bloc.page != null && bloc.page!.last == false;
              if (!hasMore) return const SizedBox.shrink();
              final loading = s is HangoutCommentsMoreLoading;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: c.onSurfaceMuted,
                            strokeWidth: 1,
                          ),
                        )
                      : TextButton(
                          onPressed: () => bloc.add(
                            GetMoreHangoutComments(hangoutId),
                          ),
                          child: Text(
                            LocaleKeys.common_show_more.tr(),
                            style: TextStyle(color: c.primary),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
