import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class CampaignDetailPageWrapper extends StatelessWidget {
  final CampaignResponse campaign;
  const CampaignDetailPageWrapper({super.key, required this.campaign});

  static Future<void> push(BuildContext context, CampaignResponse campaign) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampaignDetailPageWrapper(campaign: campaign),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.business_campaigns_detail_page_title.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Header(campaign: campaign),
          const SizedBox(height: 18),
          if (campaign.status == 'rejected' &&
              campaign.rejectionReason != null &&
              campaign.rejectionReason!.isNotEmpty) ...[
            _RejectionBanner(reason: campaign.rejectionReason!),
            const SizedBox(height: 18),
          ],
          _SectionLabel(text: LocaleKeys.business_campaigns_detail_section_performance.tr()),
          const SizedBox(height: 10),
          _PerformanceCard(campaign: campaign),
          const SizedBox(height: 22),
          _SectionLabel(text: LocaleKeys.business_campaigns_detail_section_creative.tr()),
          const SizedBox(height: 10),
          _CreativeCard(creative: campaign.creative),
          const SizedBox(height: 22),
          _SectionLabel(text: LocaleKeys.business_campaigns_detail_section_schedule.tr()),
          const SizedBox(height: 10),
          _ScheduleCard(
            startsAt: campaign.startsAt,
            endsAt: campaign.endsAt,
          ),
          const SizedBox(height: 22),
          _SectionLabel(text: LocaleKeys.business_campaigns_detail_section_targeting.tr()),
          const SizedBox(height: 10),
          _TargetingCard(
            districts: campaign.targetDistricts,
            categories: campaign.targetCategories,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CampaignResponse campaign;
  const _Header({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campaign.name,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _StatusPill(status: campaign.status),
            _PlacementPill(type: campaign.type),
          ],
        ),
      ],
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  final String reason;
  const _RejectionBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(TablerIcons.alert_triangle, color: c.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.business_campaigns_detail_rejection_reason.tr(),
                  style: TextStyle(
                    color: c.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final CampaignResponse campaign;
  const _PerformanceCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = campaign.budget <= 0
        ? 0.0
        : (campaign.spent / campaign.budget).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: LocaleKeys.business_campaigns_detail_metric_spent.tr(),
                  value: '${_formatIqd(campaign.spent)} د.ع',
                ),
              ),
              Container(width: 1, height: 36, color: c.divider),
              Expanded(
                child: _Stat(
                  label: LocaleKeys.business_campaigns_detail_metric_budget.tr(),
                  value: '${_formatIqd(campaign.budget)} د.ع',
                ),
              ),
              Container(width: 1, height: 36, color: c.divider),
              Expanded(
                child: _Stat(
                  label: LocaleKeys.business_campaigns_detail_metric_clicks.tr(),
                  value: '${campaign.clickCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: c.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? c.onSurfaceSecondary : c.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% من الميزانية',
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 11,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ],
    );
  }
}

class _CreativeCard extends StatelessWidget {
  final CampaignCreativeResponse? creative;
  const _CreativeCard({required this.creative});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (creative == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          LocaleKeys.business_campaigns_detail_no_creative_legacy.tr(),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 12,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      );
    }
    final cr = creative!;
    final sourceLabel = switch (cr.sourceType) {
      'POST' => LocaleKeys.business_campaigns_source_boosted_post.tr(),
      'HANGOUT' => LocaleKeys.business_campaigns_source_boosted_hangout.tr(),
      'CUSTOM' => LocaleKeys.business_campaigns_source_custom.tr(),
      _ => cr.sourceType,
    };
    final body = cr.sourceCaption?.isNotEmpty == true
        ? cr.sourceCaption
        : cr.caption;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cr.sourceType == 'CUSTOM' &&
              cr.mediaUrl != null &&
              cr.mediaUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: cr.mediaUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: c.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    TablerIcons.photo_x,
                    color: c.onSurfaceSecondary,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceLabel,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
                if (cr.ctaText != null && cr.ctaText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        TablerIcons.click,
                        size: 14,
                        color: c.onSurfaceSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${cr.ctaText!} → ${cr.ctaUrl ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String startsAt;
  final String endsAt;
  const _ScheduleCard({required this.startsAt, required this.endsAt});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          _DateRow(label: LocaleKeys.business_campaigns_detail_date_starts.tr(), value: _formatIso(startsAt)),
          const SizedBox(height: 10),
          _DateRow(label: LocaleKeys.business_campaigns_detail_date_ends.tr(), value: _formatIso(endsAt)),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String value;
  const _DateRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(TablerIcons.calendar, size: 16, color: c.onSurfaceSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 12,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ],
    );
  }
}

class _TargetingCard extends StatelessWidget {
  final List<String> districts;
  final List<int> categories;
  const _TargetingCard({required this.districts, required this.categories});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final nationwide = districts.isEmpty && categories.isEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: nationwide
          ? Row(
              children: [
                Icon(TablerIcons.world, color: c.onSurfaceSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.business_campaigns_detail_targeting_all_iraq.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 13,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (districts.isNotEmpty) ...[
                  Text(
                    LocaleKeys.business_campaigns_detail_targeting_districts_label.tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in districts) _Chip(label: d),
                    ],
                  ),
                ],
                if (categories.isNotEmpty) ...[
                  if (districts.isNotEmpty) const SizedBox(height: 12),
                  Text(
                    LocaleKeys.business_campaigns_detail_targeting_categories_label.tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in categories)
                        _Chip(label: '#$id'),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 12,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      text,
      style: TextStyle(
        color: c.onSurfaceSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, color) = switch (status) {
      'active' => (LocaleKeys.business_campaigns_status_active.tr(), c.success),
      'approved' => (LocaleKeys.business_campaigns_status_approved.tr(), c.primary),
      'pending' => (LocaleKeys.business_campaigns_status_pending.tr(), c.onSurfaceSecondary),
      'rejected' => (LocaleKeys.business_campaigns_status_rejected.tr(), c.danger),
      'completed' => (LocaleKeys.business_campaigns_status_completed.tr(), c.onSurfaceMuted),
      _ => (status, c.onSurfaceSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacementPill extends StatelessWidget {
  final String type;
  const _PlacementPill({required this.type});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, icon) = switch (type) {
      'feed_card' => (LocaleKeys.business_campaigns_placement_feed_card.tr(), TablerIcons.layout_list),
      'reels_placement' => (LocaleKeys.business_campaigns_placement_reels_placement.tr(), TablerIcons.movie),
      'map_pin' => (LocaleKeys.business_campaigns_placement_map_pin.tr(), TablerIcons.map_pin),
      _ => (type, TablerIcons.bookmark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.onSurfaceSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

String _formatIso(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${local.year}/${pad(local.month)}/${pad(local.day)} '
      '${pad(local.hour)}:${pad(local.minute)}';
}

String _formatIqd(double value) {
  final whole = value.round().toString();
  final buf = StringBuffer();
  var count = 0;
  for (var i = whole.length - 1; i >= 0; i--) {
    buf.write(whole[i]);
    count++;
    if (count == 3 && i != 0) {
      buf.write(',');
      count = 0;
    }
  }
  return buf.toString().split('').reversed.join();
}
