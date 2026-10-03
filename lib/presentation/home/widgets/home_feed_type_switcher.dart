import 'dart:ui' show ImageFilter;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/controller/home_bloc.dart';

class HomeFeedTypeSwitcher extends StatelessWidget {
  const HomeFeedTypeSwitcher({super.key});

  static const Duration _slide = Duration(milliseconds: 180);
  static const Curve _slideCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, _) {
            final bloc = context.read<HomeBloc>();
            final current = bloc.currentFeedType;
            return _Track(
              current: current,
              onSelect: (next) {
                if (next == current) return;
                HapticFeedback.selectionClick();
                bloc.add(HomeFeedTypeChanged(next));
              },
              slideDuration: _slide,
              slideCurve: _slideCurve,
            );
          },
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  final HomeFeedType current;
  final ValueChanged<HomeFeedType> onSelect;
  final Duration slideDuration;
  final Curve slideCurve;

  const _Track({
    required this.current,
    required this.onSelect,
    required this.slideDuration,
    required this.slideCurve,
  });

  static const double _height = 38;
  static const double _width = 220;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isFollowing = current == HomeFeedType.following;
    return SizedBox(
      width: _width,
      height: _height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_height / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(
                    color: c.onSurface.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),

              AnimatedAlign(
                duration: slideDuration,
                curve: slideCurve,
                alignment: isFollowing
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: (_width / 2) - 3,
                    height: _height - 6,
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius:
                          BorderRadius.circular((_height - 6) / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  _Half(
                    label: LocaleKeys.home_feed_tabs_following.tr(),
                    active: isFollowing,
                    duration: slideDuration,
                    curve: slideCurve,
                    onTap: () => onSelect(HomeFeedType.following),
                  ),
                  _Half(
                    label: LocaleKeys.home_feed_tabs_explore.tr(),
                    active: !isFollowing,
                    duration: slideDuration,
                    curve: slideCurve,
                    onTap: () => onSelect(HomeFeedType.forYou),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Half extends StatelessWidget {
  final String label;
  final bool active;
  final Duration duration;
  final Curve curve;
  final VoidCallback onTap;

  const _Half({
    required this.label,
    required this.active,
    required this.duration,
    required this.curve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: duration,
            curve: curve,
            style: TextStyle(
              color: active ? c.onPrimary : c.onSurfaceSecondary,
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              fontFamily: "IBMPlexSansArabic",
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
