import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/bloc/message_requests/message_requests_bloc.dart';

class RequestBanner extends StatelessWidget {
  final ConversationResponse conversation;
  final String? viewerUserId;

  const RequestBanner({
    super.key,
    required this.conversation,
    required this.viewerUserId,
  });

  String get _peerName {
    if (conversation.type == ConversationType.group) {
      return conversation.title?.trim().isNotEmpty == true
          ? conversation.title!
          : LocaleKeys.chat_request_banner_fallback_group.tr();
    }
    for (final m in conversation.members) {
      if (m.memberType == ChatMemberType.user && m.memberId == viewerUserId) {
        continue;
      }
      return m.displayName ??
          LocaleKeys.chat_request_banner_fallback_user.tr();
    }
    return LocaleKeys.chat_request_banner_fallback_user.tr();
  }

  Future<void> _accept(BuildContext context) async {
    final requestsBloc = serviceLocator.get<MessageRequestsBloc>();
    final convBloc = context.read<ConversationBloc>();
    requestsBloc.add(MessageRequestAccepted(conversation.id));
    convBloc.add(ConversationRefreshed());
  }

  Future<void> _reject(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final c = dialogCtx.c;
        return AlertDialog(
          backgroundColor: c.surfaceElevated,
          title: Text(
            LocaleKeys.chat_request_banner_decline_dialog_title.tr(),
            style: TextStyle(color: c.onSurface),
          ),
          content: Text(
            LocaleKeys.chat_request_banner_decline_dialog_body.tr(),
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
                LocaleKeys.chat_request_banner_decline_dialog_confirm.tr(),
                style: TextStyle(color: c.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    serviceLocator
        .get<MessageRequestsBloc>()
        .add(MessageRequestRejected(conversation.id));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: BlocBuilder<MessageRequestsBloc, MessageRequestsState>(
        bloc: serviceLocator.get<MessageRequestsBloc>(),
        buildWhen: (p, cur) =>
            p.inFlightIds.contains(conversation.id) !=
            cur.inFlightIds.contains(conversation.id),
        builder: (context, requestsState) {
          final busy = requestsState.inFlightIds.contains(conversation.id);
          return Container(
            color: c.surfaceMuted,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      TablerIcons.info_circle,
                      color: c.onSurfaceSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_peerName يرغب بإرسال رسائل لك.',
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(
                    LocaleKeys.chat_request_banner_body.tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: LocaleKeys.chat_request_banner_accept.tr(),
                        bg: c.primary,
                        fg: c.onPrimary,
                        busy: busy,
                        onTap: () => _accept(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: LocaleKeys.chat_request_banner_reject.tr(),
                        bg: c.surface,
                        fg: c.onSurface,
                        busy: busy,
                        onTap: () => _reject(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final bool busy;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
