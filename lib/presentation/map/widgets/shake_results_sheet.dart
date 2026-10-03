import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/shake_recommendation_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:latlong2/latlong.dart';

class ShakeResultsSheet extends StatelessWidget {
  final double lat;
  final double lng;

  const ShakeResultsSheet({
    super.key,
    required this.lat,
    required this.lng,
  });

  static Future<void> show(
    BuildContext context, {
    required double lat,
    required double lng,
  }) {
    final bloc = context.read<MapBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ShakeResultsSheet(lat: lat, lng: lng),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              _Grabber(),
              Expanded(
                child: BlocBuilder<MapBloc, MapState>(
                  buildWhen: (_, s) =>
                      s is ShakeLoading ||
                      s is ShakeLoaded ||
                      s is ShakeError,
                  builder: (context, state) {
                    if (state is ShakeLoading) {
                      return const _LoadingBody();
                    }
                    if (state is ShakeError) {
                      return _ErrorBody(
                        message: state.message,
                        rateLimited: state.rateLimited,
                        onRetry: () => _fireShake(
                          context,
                          mode: 'LOVE_IT',
                          includeFar: false,
                        ),
                      );
                    }
                    if (state is ShakeLoaded) {
                      switch (state.status) {
                        case 'OK':
                          return _ResultsBody(
                            mode: state.mode,
                            items: state.items,
                            scrollController: scrollController,
                            onShakeAgain: () => _fireShake(
                              context,
                              mode: state.mode,
                              includeFar: false,
                            ),
                          );
                        case 'NEEDS_PROFILE':
                          return _NeedsProfileBody(
                            onTrySurpriseMe: () => _fireShake(
                              context,
                              mode: 'SURPRISE_ME',
                              includeFar: false,
                            ),
                          );
                        case 'NO_CANDIDATES':
                        default:
                          return _NoCandidatesBody(
                            onExpand: () => _fireShake(
                              context,
                              mode: state.mode,
                              includeFar: true,
                            ),
                            onTrySurpriseMe: state.mode == 'SURPRISE_ME' ||
                                    state.mode == 'RANDOM'
                                ? null
                                : () => _fireShake(
                                    context,
                                    mode: 'SURPRISE_ME',
                                    includeFar: false,
                                  ),
                          );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _fireShake(
    BuildContext context, {
    required String mode,
    required bool includeFar,
  }) {
    context.read<MapBloc>().add(ShakeRequested(
          mode: mode,
          lat: lat,
          lng: lng,
          includeFar: includeFar,
        ));
  }
}

class _Grabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: c.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatefulWidget {
  const _LoadingBody();
  @override
  State<_LoadingBody> createState() => _LoadingBodyState();
}

class _LoadingBodyState extends State<_LoadingBody>
    with SingleTickerProviderStateMixin {
  static const _faces = [
    TablerIcons.dice_1,
    TablerIcons.dice_2,
    TablerIcons.dice_3,
    TablerIcons.dice_4,
    TablerIcons.dice_5,
    TablerIcons.dice_6,
  ];
  late final AnimationController _ctrl;
  int _face = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _face = (_face + 1) % _faces.length);
          _ctrl.forward(from: 0);
        }
      });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) {
              return Transform.rotate(
                angle: _ctrl.value * 6.283,
                child: Icon(_faces[_face], size: 64, color: c.onSurface),
              );
            },
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.map_shake_searching.tr(),
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  final String mode;
  final List<ShakeRecommendationItem> items;
  final ScrollController scrollController;
  final VoidCallback onShakeAgain;

  const _ResultsBody({
    required this.mode,
    required this.items,
    required this.scrollController,
    required this.onShakeAgain,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isAr = context.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Row(
            children: [
              Icon(TablerIcons.sparkles, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  switch (mode) {
                    'RANDOM' => LocaleKeys.map_shake_mode_random.tr(),
                    'SURPRISE_ME' => LocaleKeys.map_shake_mode_surprise.tr(),
                    _ => LocaleKeys.map_shake_mode_match.tr(),
                  },
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: "IBMPlexSansArabic",
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onShakeAgain,
                icon: const Icon(TablerIcons.refresh, size: 16),
                label: Text(
                  LocaleKeys.map_shake_shake_again.tr(),
                  style: const TextStyle(
                    fontFamily: "IBMPlexSansArabic",
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: c.onSurface),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _VenueCard(item: items[i], isAr: isAr),
          ),
        ),
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  final ShakeRecommendationItem item;
  final bool isAr;
  const _VenueCard({required this.item, required this.isAr});

  String get _name {
    if (isAr) return item.nameAr;
    return item.nameEn ?? item.nameAr;
  }

  String? get _reason => isAr ? item.reasonAr : item.reasonEn;
  List<String> get _tags =>
      isAr ? item.matchingTagNamesAr : item.matchingTagNamesEn;

  String? get _distanceLabel {
    final m = item.distanceMeters;
    if (m == null) return null;
    if (m < 1000) return '$m م';
    final km = (m / 1000).toStringAsFixed(1);
    return '$km كم';
  }

  void _openVenue(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenuePageWrapper(venueId: item.venueId),
      ),
    );
  }

  void _panToVenue(BuildContext context) {
    final lat = item.lat;
    final lng = item.lng;
    if (lat == null || lng == null) return;
    final ctrl = context.read<MapBloc>().animatedMapController;
    if (ctrl == null) return;
    Navigator.of(context).pop();
    ctrl.animateTo(
      dest: LatLng(lat, lng),
      zoom: 18,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Logo(url: item.logoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: "IBMPlexSansArabic",
                        ),
                      ),
                      if (_distanceLabel != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              TablerIcons.map_pin,
                              size: 12,
                              color: c.onSurfaceSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _distanceLabel!,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                                fontFamily: "IBMPlexSansArabic",
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_reason != null && _reason!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _reason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: "IBMPlexSansArabic",
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags
                    .take(4)
                    .map((t) => _TagPill(label: t))
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _panToVenue(context),
                    icon: const Icon(TablerIcons.map_2, size: 16),
                    label: Text(
                      LocaleKeys.map_shake_show_on_map.tr(),
                      style: const TextStyle(
                        fontFamily: "IBMPlexSansArabic",
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.onSurface,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openVenue(context),
                    icon: const Icon(TablerIcons.arrow_left, size: 16),
                    label: Text(
                      LocaleKeys.map_shake_open_venue.tr(),
                      style: const TextStyle(
                        fontFamily: "IBMPlexSansArabic",
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.onSurface,
                      foregroundColor: c.background,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  const _Logo({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: 156,
              errorWidget: (_, _, _) => Icon(
                TablerIcons.building_store,
                color: c.onSurface,
                size: 22,
              ),
            )
          : Icon(
              TablerIcons.building_store,
              color: c.onSurface,
              size: 22,
            ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: "IBMPlexSansArabic",
        ),
      ),
    );
  }
}

class _NeedsProfileBody extends StatelessWidget {
  final VoidCallback onTrySurpriseMe;
  const _NeedsProfileBody({required this.onTrySurpriseMe});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.heart_question, size: 56, color: c.primary),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.map_shake_preferences_title.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.map_shake_preferences_body.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
              height: 1.5,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTrySurpriseMe,
              icon: const Icon(TablerIcons.sparkles, size: 18),
              label: Text(
                LocaleKeys.map_shake_try_surprise.tr(),
                style: const TextStyle(
                  fontFamily: "IBMPlexSansArabic",
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.onSurface,
                foregroundColor: c.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCandidatesBody extends StatelessWidget {
  final VoidCallback onExpand;

  final VoidCallback? onTrySurpriseMe;

  const _NoCandidatesBody({
    required this.onExpand,
    required this.onTrySurpriseMe,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.location_off,
            size: 56,
            color: c.onSurfaceSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.map_shake_no_nearby_title.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LocaleKeys.map_shake_no_nearby_body.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
              height: 1.5,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onExpand,
              icon: const Icon(TablerIcons.arrows_diagonal, size: 18),
              label: Text(
                LocaleKeys.map_shake_expand_search.tr(),
                style: const TextStyle(
                  fontFamily: "IBMPlexSansArabic",
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.onSurface,
                foregroundColor: c.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (onTrySurpriseMe != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTrySurpriseMe,
                icon: const Icon(TablerIcons.sparkles, size: 18),
                label: Text(
                  LocaleKeys.map_shake_try_surprise.tr(),
                  style: const TextStyle(
                    fontFamily: "IBMPlexSansArabic",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.onSurface,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  final bool rateLimited;
  final VoidCallback onRetry;
  const _ErrorBody({
    required this.message,
    required this.rateLimited,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final icon = rateLimited
        ? TablerIcons.clock_pause
        : TablerIcons.alert_triangle;
    final title = (rateLimited
            ? LocaleKeys.map_shake_rate_limited_title
            : LocaleKeys.map_shake_error_title)
        .tr();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 36, color: c.onSurface),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
              height: 1.5,
              fontFamily: "IBMPlexSansArabic",
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(TablerIcons.refresh, size: 18),
              label: Text(
                LocaleKeys.common_retry.tr(),
                style: const TextStyle(
                  fontFamily: "IBMPlexSansArabic",
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.onSurface,
                foregroundColor: c.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
