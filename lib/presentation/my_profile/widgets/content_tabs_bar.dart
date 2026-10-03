import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class ContentTabsBar extends StatefulWidget {
  final Function(int) onTabSelected;
  final int pageIndex;
  const ContentTabsBar({super.key, required this.onTabSelected, required this.pageIndex});

  @override
  State<ContentTabsBar> createState() => _ContentTabsBarState();
}

class _ContentTabsBarState extends State<ContentTabsBar> {
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
          padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => widget.onTabSelected(0),
                      child: Text(
                        LocaleKeys.profile_my_tabs_my_posts.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.pageIndex == 0 ? c.onSurface : c.onSurfaceSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => widget.onTabSelected(1),
                      child: Text(
                        LocaleKeys.profile_my_tabs_my_hangouts.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.pageIndex == 1 ? c.onSurface : c.onSurfaceSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => widget.onTabSelected(2),
                      child: Text(
                        LocaleKeys.profile_my_tabs_invited_hangouts.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.pageIndex == 2 ? c.onSurface : c.onSurfaceSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
