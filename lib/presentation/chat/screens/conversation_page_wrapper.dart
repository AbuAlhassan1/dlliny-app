import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/local/chat_cache_repository.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/data/repositories/voice_upload_repository.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/active_conversation_tracker.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/helpers/message_snippet.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';
import 'package:hangout/presentation/chat/screens/conversation_info_page.dart';
import 'package:hangout/presentation/chat/widgets/conversation_composer.dart';
import 'package:hangout/presentation/chat/widgets/conversation_empty_state.dart';
import 'package:hangout/presentation/chat/widgets/conversation_header.dart';
import 'package:hangout/presentation/chat/widgets/conversation_message_list.dart';
import 'package:hangout/presentation/chat/widgets/request_banner.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class ConversationPageWrapper extends StatelessWidget {
  final String conversationId;
  const ConversationPageWrapper({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final viewerId = context.read<MyProfileBloc>().user?.id;
    return BlocProvider<ConversationBloc>(
      create: (_) => ConversationBloc(
        repo: serviceLocator.get<ChatRepository>(),
        voiceUpload: serviceLocator.get<VoiceUploadRepository>(),
        inbox: serviceLocator.get<ChatInboxBloc>(),
        events: serviceLocator.get<ChatEventSource>(),
        cache: serviceLocator.get<ChatCacheRepository>(),
        conversationId: conversationId,
        viewerId: viewerId,
      )..add(ConversationOpened()),
      child: _ConversationView(viewerId: viewerId),
    );
  }
}

class _ConversationView extends StatefulWidget {
  final String? viewerId;
  const _ConversationView({required this.viewerId});

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  String? _trackedConversationId;
  MessageDisplayItem? _replyTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.read<ConversationBloc>().conversationId;
    if (_trackedConversationId != id) {
      _trackedConversationId = id;
      ActiveConversationTracker.instance.enter(id);
    }
  }

  @override
  void dispose() {
    final id = _trackedConversationId;
    if (id != null) ActiveConversationTracker.instance.exit(id);
    super.dispose();
  }

  void _clearReply() => setState(() => _replyTo = null);

  void _openInfo(BuildContext context) {
    final bloc = context.read<ConversationBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<ConversationBloc>.value(
          value: bloc,
          child: ConversationInfoPage(viewerUserId: widget.viewerId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: BlocBuilder<ConversationBloc, ConversationState>(
          buildWhen: (p, c) =>
              p.conversation != c.conversation ||
              p.typingByMember != c.typingByMember ||
              p.peerOnline != c.peerOnline ||
              p.peerLastSeenAt != c.peerLastSeenAt,
          builder: (context, state) {
            final header = ConversationHeader(
              conversation: state.conversation,
              viewerUserId: widget.viewerId,
              typingByMember: state.typingByMember,
              peerOnline: state.peerOnline,
              peerLastSeenAt: state.peerLastSeenAt,
            );
            if (state.conversation == null) return header;
            return GestureDetector(
              onTap: () => _openInfo(context),
              child: header,
            );
          },
        ),
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listenWhen: (p, c) =>
            c.errorMessage != null && p.errorMessage != c.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            appToast.error(state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.messages.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1.5,
              ),
            );
          }
          if (state.hasFailed && state.messages.isEmpty) {
            return ConversationEmptyState(
              icon: TablerIcons.cloud_off,
              message: state.errorMessage ?? 'Couldn\'t load messages',
              actionLabel: LocaleKeys.common_retry.tr(),
              onAction: () =>
                  context.read<ConversationBloc>().add(ConversationRefreshed()),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ConversationMessageList(
                  viewerId: widget.viewerId,
                  onReply: (item) => setState(() => _replyTo = item),
                ),
              ),
              if (!state.isPendingRequest)
                ConversationComposer(
                  replyTo: _replyTo,
                  replyPreviewSnippet:
                      _replyTo == null ? null : messageSnippet(_replyTo!),
                  onClearReply: _clearReply,
                ),
              if (state.isPendingRequest && state.conversation != null)
                RequestBanner(
                  conversation: state.conversation!,
                  viewerUserId: widget.viewerId,
                ),
            ],
          );
        },
      ),
    );
  }
}
