import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/memory/widgets/mentions_inbox_tab.dart';
import 'package:hangout/presentation/notifications/controllers/follow_requests_bloc.dart';
import 'package:hangout/presentation/notifications/controllers/notifications_bloc.dart';
import 'package:hangout/presentation/notifications/notification_navigator.dart';
import 'package:hangout/presentation/notifications/widgets/follow_request_tile.dart';
import 'package:hangout/presentation/notifications/widgets/notification_tile.dart';

class NotificationsPageWrapper extends StatefulWidget {
  const NotificationsPageWrapper({super.key});

  @override
  State<NotificationsPageWrapper> createState() =>
      _NotificationsPageWrapperState();
}

class _NotificationsPageWrapperState extends State<NotificationsPageWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(GetNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider<FollowRequestsBloc>(
      create: (_) => FollowRequestsBloc()..add(GetFollowRequests()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: appPageGradient(context)),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Row(
                              children: [
                                BackButton(),

                                Text(
                                  LocaleKeys.notifications_page_title.tr(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]
                            ),
                                          
                            BlocBuilder<NotificationsBloc, NotificationsState>(
                              builder: (context, state) {
                                final unread = state.unreadCount;
                                if (unread == 0) return const SizedBox.shrink();
                                return TextButton.icon(
                                  onPressed: () => context
                                      .read<NotificationsBloc>()
                                      .add(MarkAllNotificationsRead()),
                                  icon: Icon(
                                    TablerIcons.checks,
                                    color: c.onSurface,
                                  ),
                                  label: Text(
                                    LocaleKeys.notifications_mark_all_read.tr(),
                                    style: TextStyle(color: c.onSurface),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  
                      SizedBox(height: 10),
                  
                      TabBar(
                        indicatorColor: c.onSurface,
                        labelColor: c.onSurface,
                        unselectedLabelColor: c.onSurfaceSecondary,
                        dividerHeight: 0,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: LocaleKeys.notifications_tab_all.tr()),
                          Tab(text: LocaleKeys.notifications_tab_follow_requests.tr()),
                          Tab(text: LocaleKeys.notifications_tab_mentions.tr()),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: const TabBarView(
                    children: [
                      _NotificationsTab(),
                      _FollowRequestsTab(),
                      MentionsInboxTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<NotificationsBloc>().add(GetNotifications()),
      color: c.onSurface,
      child: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          final items = state.notifications;

          if (state is NotificationsLoading && items.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            );
          }

          if (state is NotificationsError && items.isEmpty) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
            );
          }

          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 200),
                Center(
                  child: Text(
                    LocaleKeys.notifications_empty_all.tr(),
                    style: TextStyle(color: c.onSurfaceSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
            itemBuilder: (context, index) {
              final n = items[index];
              return NotificationTile(
                notification: n,
                onTap: () {
                  if (!n.read) {
                    context.read<NotificationsBloc>().add(
                      MarkNotificationRead(n.id),
                    );
                  }
                  if (n.type == 'admin_broadcast') return;
                  openNotification(n);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowRequestsTab extends StatelessWidget {
  const _FollowRequestsTab();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<FollowRequestsBloc>().add(GetFollowRequests()),
      color: c.onSurface,
      child: BlocBuilder<FollowRequestsBloc, FollowRequestsState>(
        builder: (context, state) {
          final bloc = context.read<FollowRequestsBloc>();

          if (state is FollowRequestsLoading && bloc.requests.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            );
          }

          if (state is FollowRequestsError && bloc.requests.isEmpty) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
            );
          }

          if (bloc.requests.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 200),
                Center(
                  child: Text(
                    LocaleKeys.notifications_empty_follow_requests.tr(),
                    style: TextStyle(color: c.onSurfaceSecondary),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: bloc.requests.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
            itemBuilder: (context, index) {
              return FollowRequestTile(user: bloc.requests[index]);
            },
          );
        },
      ),
    );
  }
}
