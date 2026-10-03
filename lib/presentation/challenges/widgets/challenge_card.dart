import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/challenge_enums.dart';
import 'package:hangout/domain/dto/response/challenge_list_item_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeListItemResponse item;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = context.pickBilingual(
      ar: item.titleAr,
      en: item.titleEn,
    );
    final description = context.pickBilingual(
      ar: item.descriptionAr,
      en: item.descriptionEn,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.onSurface.withAlpha(15), width: 1)
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Icon(iconUrl: item.iconUrl, cadence: item.cadence),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'IBMPlexSansArabic',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 12,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  Row(
                    children: [
                      _BonusChip(points: item.bonusPoints),
                      const Spacer(),
                      if (item.myProgress == null)
                        _JoinBadge()
                      else
                        _ProgressChip(
                          done: item.myProgress!.completedObjectiveCount,
                          total: item.myProgress!.totalObjectiveCount,
                          status: item.myProgress!.status,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  final String? iconUrl;
  final ChallengeCadence cadence;
  const _Icon({required this.iconUrl, required this.cadence});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = iconUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            width: 30,
            height: 30,
            color: c.surfaceMuted,
          ),
          errorWidget: (_, _, _) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final c = context.c;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(_iconFor(cadence), color: c.onSurfaceSecondary, size: 14),
    );
  }

  IconData _iconFor(ChallengeCadence c) {
    return switch (c) {
      ChallengeCadence.daily => TablerIcons.sunrise,
      ChallengeCadence.weekly => TablerIcons.calendar_week,
      ChallengeCadence.monthly => TablerIcons.calendar_month,
      ChallengeCadence.seasonal => TablerIcons.leaf,
      ChallengeCadence.special => TablerIcons.sparkles,
    };
  }
}

class _CadenceBadge extends StatelessWidget {
  final ChallengeCadence cadence;
  const _CadenceBadge({required this.cadence});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      _labelFor(cadence),
      style: TextStyle(
        color: c.onSurfaceMuted,
        fontSize: 11,
        fontFamily: 'IBMPlexSansArabic',
      ),
    );
  }

  String _labelFor(ChallengeCadence c) {
    return switch (c) {
      ChallengeCadence.daily => LocaleKeys.challenges_cadence_badge_daily.tr(),
      ChallengeCadence.weekly => LocaleKeys.challenges_cadence_badge_weekly.tr(),
      ChallengeCadence.monthly => LocaleKeys.challenges_cadence_badge_monthly.tr(),
      ChallengeCadence.seasonal => LocaleKeys.challenges_cadence_badge_seasonal.tr(),
      ChallengeCadence.special => LocaleKeys.challenges_cadence_badge_special.tr(),
    };
  }
}

class _BonusChip extends StatelessWidget {
  final int points;
  const _BonusChip({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 8, 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.gift, color: c.onSurface, size: 12),
          const SizedBox(width: 4),
          Text(
            LocaleKeys.challenges_card_bonus_points.tr(
              namedArgs: {'points': points.toString()},
            ),
            style: TextStyle(
              color: c.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocaleKeys.challenges_card_join_cta.tr(),
        style: TextStyle(
          color: c.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final int done;
  final int total;
  final ChallengeProgressStatus status;
  const _ProgressChip({
    required this.done,
    required this.total,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color fg = switch (status) {
      ChallengeProgressStatus.inProgress => Colors.white,
      ChallengeProgressStatus.completed => c.success,
      ChallengeProgressStatus.expired => c.onSurfaceMuted,
    };
    final icon = switch (status) {
      ChallengeProgressStatus.inProgress => TablerIcons.progress,
      ChallengeProgressStatus.completed => TablerIcons.circle_check_filled,
      ChallengeProgressStatus.expired => TablerIcons.clock_off,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: fg, size: 14),
        const SizedBox(width: 4),
        Text(
          LocaleKeys.challenges_card_joined_chip.tr(namedArgs: {
            'done': done.toString(),
            'total': total.toString(),
          }),
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ],
    );
  }
}
