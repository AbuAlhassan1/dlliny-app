import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/home/widgets/home_feed_type_switcher.dart';
import 'package:hangout/presentation/my_profile/widgets/add_content_button.dart';
import 'package:hangout/presentation/notifications/controllers/notifications_bloc.dart';
import 'package:hangout/presentation/notifications/notifications_page_wrapper.dart';
import 'package:hangout/presentation/search/search_page_wrapper.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      foregroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      flexibleSpace: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      _NotificationBellButton(),
                      SizedBox(width: 8),
                      _SearchButton(),
                    ],
                  ),
                ),
                Image.asset("assets/images/logo.png", scale: 110),
                const Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [AddContentButton()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: const HomeFeedTypeSwitcher(),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.onSurface.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            icon: Icon(TablerIcons.search, color: c.onSurface),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchPageWrapper(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.onSurface.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final unread = state.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(TablerIcons.bell, color: c.onSurface),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPageWrapper(),
                        ),
                      );
                    },
                  ),
                  if (unread > 0)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: c.danger,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.background, width: 1.5),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
