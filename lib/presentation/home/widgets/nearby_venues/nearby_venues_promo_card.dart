import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class NearbyVenuesPromoCard extends StatelessWidget {
  final List<VenueSummaryResponse> venues;
  final VoidCallback? onTap;

  const NearbyVenuesPromoCard({
    super.key,
    required this.venues,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final logos = venues.take(5).toList();

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 0, end: 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
        
              if (logos.isNotEmpty)
                PositionedDirectional(
                  top: 0,
                  bottom: 0,
                  end: 8,
                  child: _FloatingLogoCluster(venues: logos),
                ),
        
              PositionedDirectional(
                start: 18,
                end: 162,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.home_nearby_venues_promo_title.tr(),
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 28,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                        children: [
                          TextSpan(
                            text: LocaleKeys.home_nearby_venues_promo_subtitle
                                .tr(),
                          ),
                        ],
                      ),
                      maxLines: 2,
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

class _FloatingLogoCluster extends StatelessWidget {
  final List<VenueSummaryResponse> venues;
  const _FloatingLogoCluster({required this.venues});

  @override
  Widget build(BuildContext context) {
    const specs = [
      _LogoSpec(size: 65, end: 18, top: 48),
      _LogoSpec(size: 54, end: 58, top: 8),
      _LogoSpec(size: 52, end: 100, top: 46),
      _LogoSpec(size: 50, end: 56, top: 92),
      _LogoSpec(size: 48, end: 14, top: 104),
    ];

    return SizedBox(
      width: 160,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = venues.length - 1; i >= 0; i--)
            PositionedDirectional(
              end: specs[i].end,
              top: specs[i].top,
              child: _FloatingLogo(
                seed: i,
                size: specs[i].size,
                logoUrl: venues[i].logoUrl,
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoSpec {
  final double size;
  final double end;
  final double top;
  const _LogoSpec({required this.size, required this.end, required this.top});
}

class _FloatingLogo extends StatefulWidget {
  final int seed;
  final double size;
  final String? logoUrl;

  const _FloatingLogo({
    required this.seed,
    required this.size,
    required this.logoUrl,
  });

  @override
  State<_FloatingLogo> createState() => _FloatingLogoState();
}

class _FloatingLogoState extends State<_FloatingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final double _phase;
  late final double _amplitudeY;
  late final double _amplitudeX;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed * 2654435761 & 0x7fffffff);
    _phase = r.nextDouble() * 2 * math.pi;
    _amplitudeY = 3.5 + r.nextDouble() * 3.0;
    _amplitudeX = 1.5 + r.nextDouble() * 2.0;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3400 + (widget.seed % 3) * 500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 2 * math.pi;
        final dy = math.sin(t + _phase) * _amplitudeY;
        final dx = math.cos(t + _phase) * _amplitudeX;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: _LogoCircle(size: widget.size, logoUrl: widget.logoUrl),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  final double size;
  final String? logoUrl;
  const _LogoCircle({required this.size, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = logoUrl;
    final fallback = Icon(
      TablerIcons.building_store,
      color: c.onSurfaceSecondary,
      size: size * 0.42,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surfaceMuted,
      ),
      child: (url != null && url.isNotEmpty)
          ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
          )
          : Center(child: fallback),
    );
  }
}
