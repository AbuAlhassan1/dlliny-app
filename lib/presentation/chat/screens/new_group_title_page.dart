import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/domain/dto/request/create_conversation_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/screens/conversation_page_wrapper.dart';

class NewGroupTitlePage extends StatefulWidget {
  final List<UserSummaryResponse> members;
  const NewGroupTitlePage({super.key, required this.members});

  @override
  State<NewGroupTitlePage> createState() => _NewGroupTitlePageState();
}

class _NewGroupTitlePageState extends State<NewGroupTitlePage> {
  final TextEditingController _title = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      !_creating && _title.text.trim().isNotEmpty && widget.members.isNotEmpty;

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty || widget.members.isEmpty || _creating) return;

    setState(() => _creating = true);
    final repo = serviceLocator.get<ChatRepository>();
    final inbox = serviceLocator.get<ChatInboxBloc>();
    final navigator = Navigator.of(context);

    try {
      final conv = await repo.createConversation(
        CreateConversationRequest(
          type: ConversationType.group,
          title: title,
          participants: widget.members
              .map((u) => Participant(type: ChatMemberType.user, id: u.id))
              .toList(growable: false),
        ),
      );
      if (!mounted) return;
      inbox.add(InboxRefreshed());
      navigator.pop();
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ConversationPageWrapper(conversationId: conv.id),
        ),
      );
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      appToast.error(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        title: Text(
          LocaleKeys.chat_new_group_title_name_page.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _canCreate ? _create : null,
            child: _creating
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: c.onSurface,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Text(
                    LocaleKeys.chat_new_group_create.tr(),
                    style: TextStyle(
                      color: _canCreate ? c.onSurface : c.onSurfaceDisabled,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _avatarPlaceholder(),
            const SizedBox(height: 20),
            Text(
              LocaleKeys.chat_new_group_group_name_label.tr(),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: c.border,
                ),
              ),
              child: TextField(
                controller: _title,
                focusNode: _focus,
                cursorColor: c.onSurface,
                style: TextStyle(color: c.onSurface, fontSize: 15),
                onChanged: (_) => setState(() {}),
                maxLength: 60,
                decoration: InputDecoration(
                  hintText: LocaleKeys.chat_new_group_group_name_hint.tr(),
                  hintStyle: TextStyle(color: c.onSurfaceMuted),
                  border: InputBorder.none,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _memberList(),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    final c = context.c;
    final firstTwo = widget.members.take(2).toList();
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: firstTwo.isEmpty
            ? Icon(
                TablerIcons.users,
                color: c.onSurfaceSecondary,
                size: 36,
              )
            : Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _MemberCircle(url: firstTwo[0].avatarUrl, size: 50),
                  ),
                  if (firstTwo.length > 1)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _MemberCircle(
                        url: firstTwo[1].avatarUrl,
                        size: 50,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _memberList() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.chat_new_group_members_count.tr(
            namedArgs: {'n': '${widget.members.length}'},
          ),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < widget.members.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: c.divider,
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _MemberCircle(url: widget.members[i].avatarUrl, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.members[i].displayName ??
                              widget.members[i].username ??
                              '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCircle extends StatelessWidget {
  final String? url;
  final double size;
  const _MemberCircle({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.divider,
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: (size * 3).round(),
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
    );
  }
}
