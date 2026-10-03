import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/bloc/message_requests/message_requests_bloc.dart';
import 'package:hangout/presentation/chat/screens/conversation_page_wrapper.dart';
import 'package:hangout/presentation/chat/screens/new_group_picker_page.dart';
import 'package:hangout/presentation/chat/widgets/inbox_conversation_tile.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class ChatInboxPageWrapper extends StatefulWidget {
  const ChatInboxPageWrapper({super.key});

  @override
  State<ChatInboxPageWrapper> createState() => _ChatInboxPageWrapperState();
}

class _ChatInboxPageWrapperState extends State<ChatInboxPageWrapper> {
  @override
  void initState() {
    super.initState();
    final inbox = serviceLocator.get<ChatInboxBloc>();
    if (inbox.state.status == ChatInboxStatus.initial) {
      inbox.add(InboxRequested());
    }
    final requests = serviceLocator.get<MessageRequestsBloc>();
    if (requests.state.status == MessageRequestsStatus.initial) {
      requests.add(MessageRequestsRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatInboxBloc>.value(
          value: serviceLocator.get<ChatInboxBloc>(),
        ),
        BlocProvider<MessageRequestsBloc>.value(
          value: serviceLocator.get<MessageRequestsBloc>(),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: c.background,
            foregroundColor: c.onSurface,
            centerTitle: false,
            title: Text(
              LocaleKeys.chat_inbox_title.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: BlocBuilder<MessageRequestsBloc, MessageRequestsState>(
                buildWhen: (p, c) => p.pendingCount != c.pendingCount,
                builder: (context, requestsState) {
                  return TabBar(
                    indicatorColor: c.onSurface,
                    labelColor: c.onSurface,
                    unselectedLabelColor: c.onSurfaceSecondary,
                    dividerColor: c.border,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: LocaleKeys.chat_inbox_tab_conversations.tr()),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(LocaleKeys.chat_inbox_tab_requests.tr()),
                            if (requestsState.pendingCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${requestsState.pendingCount}',
                                  style: TextStyle(
                                    color: c.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NewGroupPickerPage(),
                  ),
                ),
                icon: const Icon(TablerIcons.plus),
              )
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: appPageGradient(context)),
            child: const TabBarView(
              children: [
                _ChatsTab(),
                _RequestsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<ChatInboxBloc>().add(InboxLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    final viewerUserId =
        context.read<MyProfileBloc>().user?.id;
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatInboxBloc>().add(InboxRefreshed());
      },
      color: t.onSurface,
      child: BlocConsumer<ChatInboxBloc, ChatInboxState>(
        listenWhen: (p, c) =>
            c.status == ChatInboxStatus.failure &&
            c.errorMessage != null &&
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          appToast.error(state.errorMessage ?? 'Error');
        },
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: t.onSurface,
                strokeWidth: 1.5,
              ),
            );
          }
          if (state.hasFailed && state.conversations.isEmpty) {
            return _Empty(
              icon: TablerIcons.cloud_off,
              message: state.errorMessage ?? 'Couldn\'t load chats',
              actionLabel: LocaleKeys.common_retry.tr(),
              onAction: () =>
                  context.read<ChatInboxBloc>().add(InboxRefreshed()),
            );
          }
          if (state.conversations.isEmpty) {
            return _Empty(
              icon: TablerIcons.message_circle,
              message: LocaleKeys.chat_inbox_empty_conversations.tr(),
            );
          }
          return ListView.separated(
            controller: _scroll,
            padding: EdgeInsets.zero,
            itemCount: state.conversations.length +
                (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: t.divider,
            ),
            itemBuilder: (context, index) {
              if (index >= state.conversations.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: t.onSurface,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                );
              }
              final c = state.conversations[index];
              return InboxConversationTile(
                conversation: c,
                viewerUserId: viewerUserId,
                onTap: () => _open(context, c),
              );
            },
          );
        },
      ),
    );
  }

  void _open(BuildContext context, ConversationResponse c) {
    context.read<ChatInboxBloc>().add(InboxConversationOpened(c.id));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationPageWrapper(conversationId: c.id),
      ),
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<MessageRequestsBloc>().add(
            MessageRequestsLoadMoreRequested(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    final viewerUserId =
        context.read<MyProfileBloc>().user?.id;
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MessageRequestsBloc>().add(MessageRequestsRefreshed());
      },
      color: t.onSurface,
      child: BlocConsumer<MessageRequestsBloc, MessageRequestsState>(
        listenWhen: (p, c) =>
            c.errorMessage != null &&
            p.errorMessage != c.errorMessage,
        listener: (context, state) {
          appToast.error(state.errorMessage ?? 'Error');
        },
        builder: (context, state) {
          if (state.isLoading && state.requests.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: t.onSurface,
                strokeWidth: 1.5,
              ),
            );
          }
          if (state.hasFailed && state.requests.isEmpty) {
            return _Empty(
              icon: TablerIcons.cloud_off,
              message: state.errorMessage ?? 'Couldn\'t load requests',
              actionLabel: LocaleKeys.common_retry.tr(),
              onAction: () => context
                  .read<MessageRequestsBloc>()
                  .add(MessageRequestsRefreshed()),
            );
          }
          if (state.requests.isEmpty) {
            return _Empty(
              icon: TablerIcons.inbox,
              message: LocaleKeys.chat_inbox_empty_requests.tr(),
            );
          }
          return ListView.separated(
            controller: _scroll,
            padding: EdgeInsets.zero,
            itemCount: state.requests.length +
                (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: t.divider,
            ),
            itemBuilder: (context, index) {
              if (index >= state.requests.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: t.onSurface,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                );
              }
              final c = state.requests[index];
              final busy = state.inFlightIds.contains(c.id);
              return InboxConversationTile(
                conversation: c,
                viewerUserId: viewerUserId,
                isInFlight: busy,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConversationPageWrapper(
                      conversationId: c.id,
                    ),
                  ),
                ),
                onAccept: () => context
                    .read<MessageRequestsBloc>()
                    .add(MessageRequestAccepted(c.id)),
                onReject: () => _confirmReject(context, c),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    ConversationResponse c,
  ) async {
    final bloc = context.read<MessageRequestsBloc>();
    final t = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: t.surfaceElevated,
        title: Text(
          LocaleKeys.chat_request_banner_decline_dialog_title.tr(),
          style: TextStyle(color: t.onSurface),
        ),
        content: Text(
          LocaleKeys.chat_request_banner_decline_dialog_body.tr(),
          style: TextStyle(color: t.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              LocaleKeys.common_cancel.tr(),
              style: TextStyle(color: t.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              LocaleKeys.chat_request_banner_decline_dialog_confirm.tr(),
              style: TextStyle(color: t.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) bloc.add(MessageRequestRejected(c.id));
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Empty({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      children: [
        const SizedBox(height: 140),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: c.onSurfaceDisabled, size: 56),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: c.onSurfaceSecondary),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(color: c.onSurface),
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
