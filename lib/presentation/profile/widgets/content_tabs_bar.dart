import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class ContentTabsBar extends StatelessWidget {
  final void Function(int) onTabSelected;
  final int pageIndex;

  const ContentTabsBar({
    super.key,
    required this.onTabSelected,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SliverAppBar(
        toolbarHeight: 0,
        pinned: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        collapsedHeight: 50,
        expandedHeight: 50,
        flexibleSpace: Container(
          height: 50,
          padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onTabSelected(0),
                child: Text(
                  LocaleKeys.profile_tabs_posts.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pageIndex == 0 ? c.onSurface : c.onSurfaceSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => onTabSelected(1),
                child: Text(
                  LocaleKeys.profile_tabs_hangouts.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pageIndex == 1 ? c.onSurface : c.onSurfaceSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
