import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/auth/helpers/confirm_sign_out.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/hangout/quick_create/quick_sheet_controller.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final QuickSheetController quickSheet;

  const CustomBottomNavigationBar({super.key, required this.quickSheet});

  static const double _itemSize = 46;
  static const double _iconSize = 23;

  void _onTab(BuildContext context, int target, {bool retappable = false}) {
    final bloc = context.read<TabsBloc>();
    if (retappable && bloc.tabController.index == target) {
      bloc.add(TabRetapped(target));
    } else {
      bloc.add(SwitchTab(target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = context.read<TabsBloc>().tabController;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BlocBuilder<TabsBloc, TabsState>(
                builder: (context, _) {
                  final index = tabController.index;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) =>
                        quickSheet.onDragUpdate(d.primaryDelta ?? 0),
                    onVerticalDragEnd: (d) =>
                        quickSheet.onDragEnd(d.primaryVelocity ?? 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ProfileItem(active: index == 0),
                          _NavItem(
                            icon: TablerIcons.layout_grid,
                            active: index == 1,
                            onTap: () => _onTab(context, 1, retappable: true),
                          ),
                          _NavItem(
                            icon: TablerIcons.send,
                            active: index == 2,
                            onTap: () => _onTab(context, 2),
                          ),
                          _CreateButton(controller: quickSheet),
                          _NavItem(
                            icon: TablerIcons.map,
                            active: index == 3,
                            onTap: () => _onTab(context, 3),
                          ),
                          _NavItem(
                            icon: TablerIcons.binoculars,
                            active: index == 4,
                            onTap: () => _onTab(context, 4, retappable: true),
                          ),
                          _NavItem(
                            icon: TablerIcons.search,
                            active: index == 5,
                            onTap: () => _onTab(context, 5, retappable: true),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final QuickSheetController controller;
  const _CreateButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedBuilder(
          animation: controller.animation,
          builder: (context, _) {
            final t = controller.animation.value.clamp(0.0, 1.0);
            return Transform.rotate(
              angle: t * 0.785398,
              child: Container(
                width: CustomBottomNavigationBar._itemSize,
                height: CustomBottomNavigationBar._itemSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                ),
                child: Icon(
                  TablerIcons.plus,
                  size: CustomBottomNavigationBar._iconSize + 3,
                  color: c.onPrimary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: CustomBottomNavigationBar._itemSize,
          height: CustomBottomNavigationBar._itemSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: CustomBottomNavigationBar._iconSize,
            color: active ? Colors.black : Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final bool active;
  const _ProfileItem({required this.active});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<TabsBloc>().add(SwitchTab(0)),
      onLongPress: () {
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(0, 0, 0, 0),
          items: [
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ).then((value) {
          if (value == 'logout' && context.mounted) confirmAndSignOut(context);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: CustomBottomNavigationBar._itemSize,
          height: CustomBottomNavigationBar._itemSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white : Colors.transparent,
          ),
          child: Opacity(
            opacity: active ? 1 : 0.7,
            child: BlocBuilder<MyProfileBloc, ProfileState>(
              buildWhen: (_, curr) =>
                  curr is MyProfileLoaded || curr is MyProfileUpdated,
              builder: (context, _) {
                final url = context.read<MyProfileBloc>().user?.avatarUrl;
                final hasUrl = url != null && url.isNotEmpty;
                Widget fallback() => Container(
                      color: c.surfaceMuted,
                      alignment: Alignment.center,
                      child: Icon(
                        TablerIcons.user,
                        size: 16,
                        color: c.onSurfaceSecondary,
                      ),
                    );
                return ClipOval(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: hasUrl
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            memCacheWidth: 90,
                            memCacheHeight: 90,
                            placeholder: (_, _) => fallback(),
                            errorWidget: (_, _, _) => fallback(),
                          )
                        : fallback(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
