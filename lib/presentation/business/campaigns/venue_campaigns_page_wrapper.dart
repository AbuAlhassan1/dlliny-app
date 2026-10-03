import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/campaigns/campaign_detail_page_wrapper.dart';
import 'package:hangout/presentation/business/campaigns/controllers/venue_campaigns_bloc.dart';
import 'package:hangout/presentation/business/campaigns/create_campaign_page_wrapper.dart';
import 'package:hangout/presentation/business/campaigns/widgets/campaign_skeleton.dart';

class VenueCampaignsPageWrapper extends StatelessWidget {
  final VenueResponse venue;
  const VenueCampaignsPageWrapper({super.key, required this.venue});

  static Future<void> push(BuildContext context, VenueResponse venue) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => VenueCampaignsBloc(venueId: venue.id)
            ..add(const LoadVenueCampaigns()),
          child: VenueCampaignsPageWrapper(venue: venue),
        ),
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
          LocaleKeys.business_campaigns_page_title.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        onPressed: () async {
          final created = await CreateCampaignPageWrapper.push(context, venue);
          if (created == true && context.mounted) {
            context
                .read<VenueCampaignsBloc>()
                .add(const LoadVenueCampaigns());
          }
        },
        icon: const Icon(TablerIcons.plus),
        label: Text(
          LocaleKeys.business_campaigns_new_campaign.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      body: BlocBuilder<VenueCampaignsBloc, VenueCampaignsState>(
        builder: (context, state) {
          return switch (state) {
            VenueCampaignsInitial() ||
            VenueCampaignsLoading() => const CampaignSkeletonList(),
            VenueCampaignsError(:final message) => _ErrorBody(
                message: message,
                onRetry: () => context
                    .read<VenueCampaignsBloc>()
                    .add(const LoadVenueCampaigns()),
              ),
            VenueCampaignsLoaded(:final items) => items.isEmpty
                ? const _EmptyBody()
                : _LoadedBody(items: items),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final List<CampaignResponse> items;
  const _LoadedBody({required this.items});

  @override
  Widget build(BuildContext context) {
    final buckets = <String, List<CampaignResponse>>{};
    for (final c in items) {
      buckets.putIfAbsent(c.status, () => []).add(c);
    }
    const order = ['active', 'approved', 'pending', 'rejected', 'completed'];
    final sections = <_Section>[];
    for (final s in order) {
      final list = buckets[s];
      if (list != null && list.isNotEmpty) {
        sections.add(_Section(status: s, items: list));
      }
    }
    for (final entry in buckets.entries) {
      if (!order.contains(entry.key)) {
        sections.add(_Section(status: entry.key, items: entry.value));
      }
    }

    return RefreshIndicator(
      onRefresh: () async => context
          .read<VenueCampaignsBloc>()
          .add(const LoadVenueCampaigns()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: sections.length,
        itemBuilder: (_, i) => _SectionView(section: sections[i]),
      ),
    );
  }
}

class _Section {
  final String status;
  final List<CampaignResponse> items;
  const _Section({required this.status, required this.items});
}

class _SectionView extends StatelessWidget {
  final _Section section;
  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
          child: Row(
            children: [
              _StatusDot(status: section.status),
              const SizedBox(width: 8),
              Text(
                _statusLabel(section.status),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${section.items.length})',
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 12,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ],
          ),
        ),
        for (final c in section.items) ...[
          _CampaignCard(campaign: c),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignResponse campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = campaign.budget <= 0
        ? 0.0
        : (campaign.spent / campaign.budget).clamp(0.0, 1.0);
    return Material(
      color: c.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => CampaignDetailPageWrapper.push(context, campaign),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      campaign.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PlacementPill(type: campaign.type),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: c.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 1.0 ? c.onSurfaceSecondary : c.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatIqd(campaign.spent),
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  Text(
                    ' / ${_formatIqd(campaign.budget)} د.ع',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    TablerIcons.click,
                    size: 14,
                    color: c.onSurfaceSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${campaign.clickCount}',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
              ),
              if (campaign.status == 'rejected' &&
                  campaign.rejectionReason != null &&
                  campaign.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        TablerIcons.alert_triangle,
                        color: c.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.rejectionReason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.onSurfaceSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: c.onSurfaceSecondary,
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

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = switch (status) {
      'active' => c.success,
      'approved' => c.primary,
      'pending' => c.onSurfaceSecondary,
      'rejected' => c.danger,
      'completed' => c.onSurfaceMuted,
      _ => c.onSurfaceSecondary,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.speakerphone,
              size: 56,
              color: c.onSurfaceSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              LocaleKeys.business_campaigns_empty_title.tr(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LocaleKeys.business_campaigns_empty_body.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.alert_triangle,
              size: 48,
              color: c.onSurfaceSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 13,
                height: 1.4,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(TablerIcons.refresh, size: 18),
              label: Text(
                LocaleKeys.common_retry.tr(),
                style: const TextStyle(
                  fontFamily: 'IBMPlexSansArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.onSurface,
                foregroundColor: c.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'active' => LocaleKeys.business_campaigns_status_active.tr(),
      'approved' => LocaleKeys.business_campaigns_status_approved.tr(),
      'pending' => LocaleKeys.business_campaigns_status_pending.tr(),
      'rejected' => LocaleKeys.business_campaigns_status_rejected.tr(),
      'completed' => LocaleKeys.business_campaigns_status_completed.tr(),
      _ => status,
    };

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
