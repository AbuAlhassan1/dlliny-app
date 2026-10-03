import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class DemographicsBars extends StatelessWidget {
  final AudienceDemographicsResponse data;
  const DemographicsBars({super.key, required this.data});

  String _friendlyLabel(String raw) {
    switch (raw) {
      case '_other_':
        return LocaleKeys.business_analytics_demographics_bucket_other.tr();
      case 'anonymous':
        return LocaleKeys.business_analytics_demographics_bucket_unspecified.tr();
      case 'male':
        return LocaleKeys.business_analytics_demographics_gender_male.tr();
      case 'female':
        return LocaleKeys.business_analytics_demographics_gender_female.tr();
      case 'ar':
        return LocaleKeys.business_analytics_demographics_lang_arabic.tr();
      case 'en':
        return LocaleKeys.business_analytics_demographics_lang_english.tr();
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasAny = data.byDistrict.isNotEmpty ||
        data.byCity.isNotEmpty ||
        data.byLanguage.isNotEmpty ||
        data.byGender.isNotEmpty;
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_demographics_title.tr(),
      subtitle: LocaleKeys.business_analytics_demographics_subtitle_followers.tr(
        namedArgs: {'n': '${data.totalFollowers}'},
      ),
      child: !hasAny
          ? AnalyticsTileEmpty(
              icon: TablerIcons.users,
              message: LocaleKeys.business_analytics_demographics_empty.tr(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  label: LocaleKeys.business_analytics_demographics_tab_districts.tr(),
                  buckets: data.byDistrict,
                  friendly: _friendlyLabel,
                ),
                _Section(
                  label: LocaleKeys.business_analytics_demographics_tab_cities.tr(),
                  buckets: data.byCity,
                  friendly: _friendlyLabel,
                ),
                _Section(
                  label: LocaleKeys.business_analytics_demographics_tab_language.tr(),
                  buckets: data.byLanguage,
                  friendly: _friendlyLabel,
                ),
                _Section(
                  label: LocaleKeys.business_analytics_demographics_tab_gender.tr(),
                  buckets: data.byGender,
                  friendly: _friendlyLabel,
                ),
                if (data.privacyFloorApplied) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        TablerIcons.shield_lock,
                        color: c.onSurfaceMuted,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          LocaleKeys.business_analytics_demographics_privacy_note.tr(),
                          style: TextStyle(
                            color: c.onSurfaceMuted,
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<DemographicBucket> buckets;
  final String Function(String raw) friendly;

  const _Section({
    required this.label,
    required this.buckets,
    required this.friendly,
  });

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();
    final c = context.c;
    final maxV = buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    final scale = maxV == 0 ? 1 : maxV;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          for (final bucket in buckets)
            _BucketRow(
              label: friendly(bucket.label),
              count: bucket.count,
              fraction: bucket.count / scale,
            ),
        ],
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final String label;
  final int count;
  final num fraction;
  const _BucketRow({
    required this.label,
    required this.count,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = fraction.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: c.onSurface, fontSize: 12),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: pct,
              backgroundColor: c.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(c.primary),
            ),
          ),
        ],
      ),
    );
  }
}
