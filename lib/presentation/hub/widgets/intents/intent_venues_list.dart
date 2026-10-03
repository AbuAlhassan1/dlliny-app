import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venue_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

const double _spacing = 10;
const int _perRow = 5;
const double _sidePadding = 16;

class IntentVenuesList extends StatelessWidget {
  final List<VenueSummaryResponse> venues;
  final bool hasNoMatches;
  const IntentVenuesList({
    super.key,
    required this.venues,
    required this.hasNoMatches,
  });

  @override
  Widget build(BuildContext context) {
    if (hasNoMatches || venues.isEmpty) {
      return const _EmptyState();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _sidePadding,
        end: _sidePadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalSpacing = _spacing * (_perRow - 1);
          final boxWidth = (constraints.maxWidth - totalSpacing) / _perRow;
          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (final v in venues)
                NearbyVenueBoxCard(venue: v, width: boxWidth),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.mood_empty,
            size: 16,
            color: c.onSurfaceSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              LocaleKeys.hub_intents_no_venues.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IntentVenuesLoadingRow extends StatelessWidget {
  const IntentVenuesLoadingRow({super.key});

  static const double _nameLineHeight = 12 * 1.2;

  static Widget _shimmer(AppColors c, Widget child) => Shimmer(
        duration: const Duration(milliseconds: 1400),
        color: c.onSurface.withValues(alpha: 0.06),
        colorOpacity: 0.5,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: _sidePadding,
        end: _sidePadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalSpacing = _spacing * (_perRow - 1);
          final boxWidth = (constraints.maxWidth - totalSpacing) / _perRow;
          return Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (int i = 0; i < _perRow; i++)
                SizedBox(
                  width: boxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: _shimmer(
                          c,
                          Container(
                            width: boxWidth,
                            height: boxWidth,
                            decoration: BoxDecoration(
                              color: c.surfaceMuted,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.border, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: _nameLineHeight,
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _shimmer(
                              c,
                              Container(
                                height: 10,
                                width: boxWidth * 0.7,
                                color: c.surfaceMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class IntentVenuesErrorRow extends StatelessWidget {
  final VoidCallback onRetry;
  const IntentVenuesErrorRow({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            foregroundColor: c.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          icon: const Icon(TablerIcons.refresh, size: 16),
          label: Text(
            LocaleKeys.common_retry.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ),
    );
  }
}
