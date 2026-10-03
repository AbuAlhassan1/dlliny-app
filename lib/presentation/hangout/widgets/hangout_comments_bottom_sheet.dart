import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/hangout/controllers/comments/hangout_comments_bloc.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comment_tile.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';

Future<void> showHangoutCommentsBottomSheet({
  required BuildContext context,
  required String hangoutId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) =>
          HangoutCommentsBloc()..add(GetHangoutComments(hangoutId)),
      child: _HangoutCommentsSheet(hangoutId: hangoutId),
    ),
  );
}

class _HangoutCommentsSheet extends StatefulWidget {
  final String hangoutId;
  const _HangoutCommentsSheet({required this.hangoutId});

  @override
  State<_HangoutCommentsSheet> createState() => _HangoutCommentsSheetState();
}

class _HangoutCommentsSheetState extends State<_HangoutCommentsSheet> {
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
      context
          .read<HangoutCommentsBloc>()
          .add(GetMoreHangoutComments(widget.hangoutId));
    }
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
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
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
                LocaleKeys.hangout_comments_sheet_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Divider(height: 16, color: c.divider),
              Expanded(
                child: BlocConsumer<HangoutCommentsBloc, HangoutCommentsState>(
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
                  builder: (context, state) {
                    final c = context.c;
                    final bloc = context.read<HangoutCommentsBloc>();
                    if (state is HangoutCommentsLoading &&
                        bloc.comments.isEmpty) {
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
                          LocaleKeys.hangout_comments_sheet_empty.tr(),
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      );
                    }
                    final entries = bloc.flattenedEntries();
                    final extra =
                        state is HangoutCommentsMoreLoading ? 1 : 0;
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
                        return buildHangoutCommentsEntry(
                          context,
                          entries[i],
                          widget.hangoutId,
                          _startReply,
                        );
                      },
                    );
                  },
                ),
              ),
              Divider(height: 1, color: c.divider),
              const HangoutCommentsReplyBanner(),
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
                            hintText: LocaleKeys.hangout_comments_sheet_add_hint.tr(),
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
                          final c = context.c;
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

Widget buildHangoutCommentsEntry(
  BuildContext context,
  HangoutCommentsListEntry entry,
  String hangoutId,
  void Function(String parentCommentId, String authorUsername) onReply,
) {
  final bloc = context.read<HangoutCommentsBloc>();
  final navigator = Navigator.of(context);
  final myUsername = context.read<MyProfileBloc>().user?.username;
  final tabsBloc = context.read<TabsBloc>();

  void openProfile(String username) {
    if (myUsername != null &&
        username.toLowerCase() == myUsername.toLowerCase()) {
      navigator.popUntil((r) => r.isFirst);
      tabsBloc.add(SwitchTab(0));
      return;
    }
    navigator.push(
      MaterialPageRoute(builder: (_) => ProfilePageWrapper(username: username)),
    );
  }

  switch (entry.kind) {
    case HangoutCommentsListEntryKind.parent:
      final c = entry.comment!;
      return HangoutCommentTile(
        comment: c,
        onDelete: () => bloc.add(
          DeleteHangoutComment(hangoutId: hangoutId, commentId: c.id),
        ),
        onReply: () => onReply(c.id, c.author.username),
        onAuthorTap: () => openProfile(c.author.username),
      );
    case HangoutCommentsListEntryKind.reply:
      final c = entry.comment!;
      return HangoutCommentTile(
        comment: c,
        isReply: true,
        onDelete: () => bloc.add(
          DeleteHangoutComment(hangoutId: hangoutId, commentId: c.id),
        ),
        onAuthorTap: () => openProfile(c.author.username),
      );
    case HangoutCommentsListEntryKind.replyFooter:
      return _HangoutRepliesFooter(
        hangoutId: hangoutId,
        parentId: entry.parentId!,
        remaining: entry.remaining,
        loading: entry.loading,
      );
  }
}

class _HangoutRepliesFooter extends StatelessWidget {
  final String hangoutId;
  final String parentId;
  final int remaining;
  final bool loading;
  const _HangoutRepliesFooter({
    required this.hangoutId,
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
            : () =>
                context.read<HangoutCommentsBloc>().add(GetMoreHangoutReplies(
                      hangoutId: hangoutId,
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
                  LocaleKeys.hangout_comments_sheet_show_n_more_replies.tr(
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

class HangoutCommentsReplyBanner extends StatelessWidget {
  const HangoutCommentsReplyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HangoutCommentsBloc, HangoutCommentsState>(
      buildWhen: (_, s) =>
          s is HangoutReplyTargetChanged || s is HangoutCommentsLoaded,
      builder: (context, _) {
        final c = context.c;
        final target = context.read<HangoutCommentsBloc>().replyTarget;
        if (target == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: c.surfaceMuted,
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  LocaleKeys.hangout_comments_sheet_replying_to.tr(
                    namedArgs: {'username': target.authorUsername},
                  ),
                  style:
                      TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
                ),
              ),
              InkWell(
                onTap: () => context
                    .read<HangoutCommentsBloc>()
                    .add(ClearHangoutReplyTarget()),
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
