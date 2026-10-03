import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/screens/add_members_page.dart';

class ConversationInfoPage extends StatelessWidget {
  final String? viewerUserId;
  const ConversationInfoPage({super.key, required this.viewerUserId});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return BlocConsumer<ConversationBloc, ConversationState>(
      listenWhen: (p, c) =>
          (!p.isLeft && c.isLeft) ||
          (c.errorMessage != null && p.errorMessage != c.errorMessage),
      listener: (context, state) {
        if (state.isLeft) {
          Navigator.of(context).pop();
          Navigator.of(context).maybePop();
          return;
        }
        if (state.errorMessage != null) {
          appToast.error(state.errorMessage!);
        }
      },
      builder: (context, state) {
        final c = state.conversation;
        if (c == null) {
          return Scaffold(
            backgroundColor: t.background,
            body: Center(
              child: CircularProgressIndicator(
                color: t.onSurface,
                strokeWidth: 1.5,
              ),
            ),
          );
        }
        final isGroup = c.type == ConversationType.group;
        final viewerIsAdmin = _viewerIsAdmin(c);
        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            foregroundColor: t.onSurface,
            title: Text(
              (isGroup
                      ? LocaleKeys.chat_info_title_group
                      : LocaleKeys.chat_info_title_dm)
                  .tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Header(conversation: c, viewerUserId: viewerUserId),
              const SizedBox(height: 24),
              if (isGroup && viewerIsAdmin) ...[
                _RenameTile(conversation: c),
                const SizedBox(height: 8),
              ],
              _RetentionTile(
                conversation: c,
                editable: !isGroup || viewerIsAdmin,
              ),
              const SizedBox(height: 8),
              _MuteTile(conversation: c),
              const SizedBox(height: 20),
              _MembersSection(
                conversation: c,
                viewerUserId: viewerUserId,
                viewerIsAdmin: viewerIsAdmin,
              ),
              const SizedBox(height: 28),
              _LeaveTile(isGroup: isGroup),
            ],
          ),
        );
      },
    );
  }

  bool _viewerIsAdmin(ConversationResponse c) {
    if (c.type != ConversationType.group) return false;
    for (final m in c.members) {
      if (m.memberType == ChatMemberType.user &&
          m.memberId == viewerUserId &&
          m.role == ChatMemberRole.admin) {
        return true;
      }
    }
    return false;
  }
}

class _Header extends StatelessWidget {
  final ConversationResponse conversation;
  final String? viewerUserId;
  const _Header({required this.conversation, required this.viewerUserId});

  ChatMemberResponse? get _peer {
    if (conversation.type != ConversationType.direct) return null;
    for (final m in conversation.members) {
      if (m.memberType == ChatMemberType.user && m.memberId == viewerUserId) {
        continue;
      }
      return m;
    }
    return conversation.members.isNotEmpty
        ? conversation.members.first
        : null;
  }

  String get _title {
    if (conversation.type == ConversationType.group) {
      return conversation.title?.trim().isNotEmpty == true
          ? conversation.title!
          : 'Group';
    }
    return _peer?.displayName ?? 'Conversation';
  }

  String? get _avatarUrl {
    if (conversation.type == ConversationType.group) {
      return conversation.avatarUrl;
    }
    return _peer?.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.divider,
          ),
          child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: _avatarUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 336,
                  errorWidget: (_, _, _) => Icon(
                    TablerIcons.user,
                    color: c.onSurfaceSecondary,
                    size: 44,
                  ),
                )
              : Icon(
                  conversation.type == ConversationType.group
                      ? TablerIcons.users
                      : TablerIcons.user,
                  color: c.onSurfaceSecondary,
                  size: 44,
                ),
        ),
        const SizedBox(height: 12),
        Text(
          _title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        if (conversation.type == ConversationType.group) ...[
          const SizedBox(height: 4),
          Text(
            '${conversation.members.length} عضوًا',
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _RenameTile extends StatelessWidget {
  final ConversationResponse conversation;
  const _RenameTile({required this.conversation});

  Future<void> _open(BuildContext context) async {
    final bloc = context.read<ConversationBloc>();
    final updated = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RenameSheet(initial: conversation.title ?? ''),
    );
    if (updated == null || updated.trim().isEmpty) return;
    if (updated.trim() == conversation.title?.trim()) return;
    bloc.add(ConversationSettingsUpdated(title: updated.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Tile(
      icon: TablerIcons.pencil,
      label: LocaleKeys.chat_info_rename_group_field.tr(),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: c.onSurfaceDisabled,
        size: 14,
      ),
      onTap: () => _open(context),
    );
  }
}

class _RenameSheet extends StatefulWidget {
  final String initial;
  const _RenameSheet({required this.initial});

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.chat_info_rename_group_dialog_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: c.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: c.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  cursorColor: c.onSurface,
                  maxLength: 60,
                  style: TextStyle(color: c.onSurface, fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        LocaleKeys.common_cancel.tr(),
                        style: TextStyle(color: c.onSurfaceSecondary),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(
                          _controller.text.trim(),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              LocaleKeys.common_save.tr(),
                              style: TextStyle(
                                color: c.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_RetentionOption> _retentionOptionsList() => [
  _RetentionOption(
    label: LocaleKeys.chat_info_retention_default.tr(),
    days: null,
  ),
  _RetentionOption(
    label: LocaleKeys.chat_info_retention_days_count.plural(7),
    days: 7,
  ),
  _RetentionOption(
    label: LocaleKeys.chat_info_retention_days_count.plural(30),
    days: 30,
  ),
  _RetentionOption(
    label: LocaleKeys.chat_info_retention_days_count.plural(90),
    days: 90,
  ),
];

class _RetentionOption {
  final String label;
  final int? days;
  const _RetentionOption({required this.label, required this.days});
}

class _RetentionTile extends StatelessWidget {
  final ConversationResponse conversation;
  final bool editable;
  const _RetentionTile({
    required this.conversation,
    required this.editable,
  });

  String get _currentLabel {
    final options = _retentionOptionsList();
    final d = conversation.retentionDays;
    if (d == null) return options.first.label;
    return options
        .firstWhere(
          (o) => o.days == d,
          orElse: () => _RetentionOption(
            label: LocaleKeys.chat_info_retention_days_count.plural(d),
            days: d,
          ),
        )
        .label;
  }

  Future<void> _open(BuildContext context) async {
    final bloc = context.read<ConversationBloc>();
    final t = context.c;
    final picked = await showModalBottomSheet<_RetentionOption>(
      context: context,
      backgroundColor: t.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  LocaleKeys.chat_info_retention_label.tr(),
                  style: TextStyle(
                    color: t.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            for (final opt in _retentionOptionsList())
              ListTile(
                title: Text(
                  opt.label,
                  style: TextStyle(color: t.onSurface),
                ),
                trailing: conversation.retentionDays == opt.days
                    ? Icon(
                        TablerIcons.check,
                        color: t.onSurface,
                        size: 18,
                      )
                    : null,
                onTap: () => Navigator.of(sheetCtx).pop(opt),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    if (picked.days == conversation.retentionDays) return;
    bloc.add(
      ConversationSettingsUpdated(
        retentionDays: picked.days,
        clearRetention: picked.days == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Tile(
      icon: TablerIcons.clock_hour_4,
      label: LocaleKeys.chat_info_retention_label.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentLabel,
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
          ),
          if (editable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: c.onSurfaceDisabled,
              size: 14,
            ),
          ],
        ],
      ),
      onTap: editable ? () => _open(context) : null,
    );
  }
}

class _MuteTile extends StatelessWidget {
  final ConversationResponse conversation;
  const _MuteTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Tile(
      icon: conversation.muted ? TablerIcons.bell_off : TablerIcons.bell,
      label: LocaleKeys.chat_info_mute_label.tr(),
      trailing: Switch.adaptive(
        value: conversation.muted,
        activeThumbColor: c.onSurface,
        activeTrackColor: c.onSurfaceDisabled,
        onChanged: (v) {
          context
              .read<ConversationBloc>()
              .add(ConversationMutedRequested(v));
        },
      ),
      onTap: () => context
          .read<ConversationBloc>()
          .add(ConversationMutedRequested(!conversation.muted)),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final ConversationResponse conversation;
  final String? viewerUserId;
  final bool viewerIsAdmin;

  const _MembersSection({
    required this.conversation,
    required this.viewerUserId,
    required this.viewerIsAdmin,
  });

  bool get _isGroup => conversation.type == ConversationType.group;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                (_isGroup
                        ? LocaleKeys.chat_info_section_members_group
                        : LocaleKeys.chat_info_section_members_dm)
                    .tr(),
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (_isGroup && viewerIsAdmin)
                _AddMembersButton(conversation: conversation),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < conversation.members.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: c.border,
                  ),
                _MemberRow(
                  member: conversation.members[i],
                  isViewer: conversation.members[i].memberType ==
                          ChatMemberType.user &&
                      conversation.members[i].memberId == viewerUserId,
                  viewerIsAdmin: viewerIsAdmin && _isGroup,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AddMembersButton extends StatelessWidget {
  final ConversationResponse conversation;
  const _AddMembersButton({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextButton.icon(
      onPressed: () {
        final parentBloc = context.read<ConversationBloc>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddMembersPage(
              existingMemberIds: conversation.members
                  .where((m) => m.memberType == ChatMemberType.user)
                  .map((m) => m.memberId)
                  .toSet(),
              currentMemberCount: conversation.members.length,
              parentBloc: parentBloc,
            ),
          ),
        );
      },
      icon: Icon(TablerIcons.user_plus, size: 16, color: c.onSurface),
      label: Text(
        LocaleKeys.chat_info_add_member.tr(),
        style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ChatMemberResponse member;
  final bool isViewer;
  final bool viewerIsAdmin;
  const _MemberRow({
    required this.member,
    required this.isViewer,
    required this.viewerIsAdmin,
  });

  Future<void> _showActions(BuildContext context) async {
    if (!viewerIsAdmin || isViewer) return;
    final t = context.c;
    final action = await showModalBottomSheet<_MemberAction>(
      context: context,
      backgroundColor: t.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (member.role == ChatMemberRole.admin)
              ListTile(
                leading: Icon(
                  TablerIcons.crown_off,
                  color: t.onSurface,
                  size: 20,
                ),
                title: Text(
                  LocaleKeys.chat_info_demote_admin.tr(),
                  style: TextStyle(color: t.onSurface),
                ),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_MemberAction.demote),
              )
            else
              ListTile(
                leading: Icon(
                  TablerIcons.crown,
                  color: t.onSurface,
                  size: 20,
                ),
                title: Text(
                  LocaleKeys.chat_info_promote_admin.tr(),
                  style: TextStyle(color: t.onSurface),
                ),
                onTap: () =>
                    Navigator.of(sheetCtx).pop(_MemberAction.promote),
              ),
            ListTile(
              leading: Icon(
                TablerIcons.user_minus,
                color: t.danger,
                size: 20,
              ),
              title: Text(
                LocaleKeys.chat_info_remove_from_group.tr(),
                style: TextStyle(color: t.danger),
              ),
              onTap: () => Navigator.of(sheetCtx).pop(_MemberAction.remove),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final bloc = context.read<ConversationBloc>();
    switch (action) {
      case _MemberAction.promote:
        bloc.add(MemberRoleChangeRequested(
          member.memberId,
          promoteToAdmin: true,
        ));
        break;
      case _MemberAction.demote:
        bloc.add(MemberRoleChangeRequested(
          member.memberId,
          promoteToAdmin: false,
        ));
        break;
      case _MemberAction.remove:
        final ok = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) {
            final dt = dialogCtx.c;
            return AlertDialog(
              backgroundColor: dt.surfaceElevated,
              title: Text(
                LocaleKeys.chat_info_remove_member_title.tr(),
                style: TextStyle(color: dt.onSurface),
              ),
              content: Text(
                LocaleKeys.chat_info_remove_member_confirm_with_name.tr(
                  namedArgs: {
                    'name': member.displayName ??
                        LocaleKeys.chat_info_remove_member_fallback_name.tr(),
                  },
                ),
                style: TextStyle(color: dt.onSurfaceSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: Text(
                    LocaleKeys.common_cancel.tr(),
                    style: TextStyle(color: dt.onSurfaceSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(true),
                  child: Text(
                    LocaleKeys.chat_info_remove_member_title.tr(),
                    style: TextStyle(color: dt.danger),
                  ),
                ),
              ],
            );
          },
        );
        if (ok == true) bloc.add(MemberRemoveRequested(member.memberId));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () => _showActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.divider,
                shape: BoxShape.circle,
              ),
              child: (member.avatarUrl != null &&
                      member.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: member.avatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      errorWidget: (_, _, _) => Icon(
                        TablerIcons.user,
                        color: c.onSurfaceSecondary,
                        size: 18,
                      ),
                    )
                  : Icon(
                      TablerIcons.user,
                      color: c.onSurfaceSecondary,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      member.displayName ?? LocaleKeys.chat_info_user_fallback.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isViewer) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(أنت)',
                      style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (member.role == ChatMemberRole.admin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: c.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  LocaleKeys.chat_info_admin_badge.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _MemberAction { promote, demote, remove }

class _LeaveTile extends StatelessWidget {
  final bool isGroup;
  const _LeaveTile({required this.isGroup});

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final c = dialogCtx.c;
        return AlertDialog(
          backgroundColor: c.surfaceElevated,
          title: Text(
            (isGroup
                    ? LocaleKeys.chat_info_leave_group_title
                    : LocaleKeys.chat_info_hide_dm_title)
                .tr(),
            style: TextStyle(color: c.onSurface),
          ),
          content: Text(
            (isGroup
                    ? LocaleKeys.chat_info_leave_group_body
                    : LocaleKeys.chat_info_hide_dm_body)
                .tr(),
            style: TextStyle(color: c.onSurfaceSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                LocaleKeys.common_cancel.tr(),
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                (isGroup
                        ? LocaleKeys.chat_info_leave_group_cta
                        : LocaleKeys.chat_info_hide_dm_cta)
                    .tr(),
                style: TextStyle(color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    context.read<ConversationBloc>().add(ConversationLeaveRequested());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _confirm(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.danger.withValues(alpha: 0.33)),
          ),
          child: Row(
            children: [
              Icon(
                TablerIcons.logout,
                color: c.danger,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                (isGroup
                        ? LocaleKeys.chat_info_leave_group_title
                        : LocaleKeys.chat_info_hide_dm_title)
                    .tr(),
                style: TextStyle(
                  color: c.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.onSurfaceSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
