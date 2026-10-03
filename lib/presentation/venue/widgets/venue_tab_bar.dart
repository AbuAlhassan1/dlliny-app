import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class VenueTabBar extends StatelessWidget {
  final Function(int) onTabSelected;
  final int pageIndex;
  const VenueTabBar({
    super.key,
    required this.onTabSelected,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
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
          alignment: AlignmentDirectional.centerStart,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.only(start: 20, end: 10),
            child: Row(
              children: [
                _VenueNameTab(
                  active: pageIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                const SizedBox(width: 18),
                _Tab(
                  label: LocaleKeys.venue_tabs_posts.tr(),
                  active: pageIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                const SizedBox(width: 18),
                _Tab(
                  label: LocaleKeys.venue_tabs_services.tr(),
                  active: pageIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
                const SizedBox(width: 18),
                _Tab(
                  label: LocaleKeys.venue_tabs_community.tr(),
                  active: pageIndex == 3,
                  onTap: () => onTabSelected(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: active ? c.onSurface : c.onSurfaceSecondary,
        ),
      ),
    );
  }
}

class _VenueNameTab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _VenueNameTab({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: BlocBuilder<VenueBloc, VenueState>(
        builder: (context, state) {
          if (state is GetVenueDetailsLoaded) {
            return Text(
              state.venue.nameAr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: active ? c.onSurface : c.onSurfaceSecondary,
              ),
            );
          }
          return Shimmer(
            color: c.onSurface.withValues(alpha: 0.4),
            child: Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        },
      ),
    );
  }
}
