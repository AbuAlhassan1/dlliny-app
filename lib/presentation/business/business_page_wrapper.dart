import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/business/controllers/my_businesses_bloc.dart';
import 'package:hangout/presentation/business/transfers/business_transfers_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:hangout/presentation/venues/venues_page_wrapper.dart';

class BusinessPageWrapper extends StatefulWidget {
  const BusinessPageWrapper({super.key});

  @override
  State<BusinessPageWrapper> createState() => _BusinessPageWrapperState();
}

class _BusinessPageWrapperState extends State<BusinessPageWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccessBloc>().add(GetMyAccess());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyBusinessesBloc()..add(GetMyBusinesses()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            LocaleKeys.business_page_title.tr(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: LocaleKeys.business_transfers_tooltip.tr(),
              onPressed: () => BusinessTransfersPageWrapper.push(context),
              icon: const Icon(TablerIcons.transfer),
            ),
          ],
        ),
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBusinessesBloc, MyBusinessesState>(
      builder: (context, bizState) {
        final bizLoading = bizState is MyBusinessesInitial ||
            bizState is GetMyBusinessesLoading;
        final access = context.watch<AccessBloc>().myAccess?.data;

        if (bizLoading && access == null) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 1.5),
          );
        }

        final businesses = bizState is GetMyBusinessesLoaded
            ? bizState.response
            : const <BusinessAccountResponse>[];
        final ownedBizIds = {for (final b in businesses) b.id};

        final allVenues = _collectVenues(access);
        final hasBusinesses = businesses.isNotEmpty;
        final hasVenues = allVenues.isNotEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MyBusinessesBloc>().add(GetMyBusinesses());
            context.read<AccessBloc>().add(GetMyAccess());
          },
          child: !hasBusinesses && !hasVenues
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    _EmptyState(),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
                  children: [
                    if (hasBusinesses) ...[
                      _SectionHeader(
                        text: LocaleKeys.business_section_my_business.tr(),
                      ),
                      const SizedBox(height: 8),
                      for (final biz in businesses) ...[
                        _BusinessCard(business: biz),
                        const SizedBox(height: 10),
                      ],
                    ],
                    if (hasVenues) ...[
                      if (hasBusinesses) const SizedBox(height: 14),
                      _SectionHeader(
                        text: LocaleKeys.business_section_managed.tr(),
                      ),
                      const SizedBox(height: 8),
                      for (final ctx in allVenues) ...[
                        _VenueAccessCard(
                          venue: ctx.venue,
                          parentBusinessName: ctx.parentBusinessName,
                          subtle: ctx.parentBusinessId != null &&
                              ownedBizIds.contains(ctx.parentBusinessId),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
        );
      },
    );
  }

  List<_VenueContext> _collectVenues(UserAccessResponse? access) {
    if (access == null) return const [];
    final out = <_VenueContext>[];
    for (final biz in access.businesses) {
      for (final v in biz.venues) {
        out.add(_VenueContext(
          venue: v,
          parentBusinessId: biz.businessId,
          parentBusinessName: biz.companyName,
        ));
      }
    }
    for (final v in access.orphanVenues) {
      out.add(_VenueContext(venue: v));
    }
    return out;
  }
}

class _VenueContext {
  final VenueAccess venue;
  final String? parentBusinessId;
  final String? parentBusinessName;
  const _VenueContext({
    required this.venue,
    this.parentBusinessId,
    this.parentBusinessName,
  });
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Text(
        text,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _BusinessCard extends StatelessWidget {
  final BusinessAccountResponse business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VenuesPageWrapper(business: business),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.companyName?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    business.createdAt.split('T').first,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(
                    active: business.active,
                    activeLabel: LocaleKeys.business_active_badge_yes.tr(),
                    inactiveLabel: LocaleKeys.business_active_badge_no.tr(),
                    activeBg: const Color(0xFFCAF0CB),
                    inactiveBg: const Color(0xFFFFC9C9),
                    activeFg: Colors.green,
                    inactiveFg: Colors.red,
                  ),
                  const SizedBox(height: 5),
                  _StatusPill(
                    active: business.verified,
                    activeLabel: LocaleKeys.business_verified_badge_yes.tr(),
                    inactiveLabel: LocaleKeys.business_verified_badge_no.tr(),
                    activeBg: const Color.fromARGB(255, 150, 205, 250),
                    inactiveBg: const Color.fromARGB(255, 255, 255, 255),
                    activeFg: Colors.blue,
                    inactiveFg: Colors.grey,
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

class _StatusPill extends StatelessWidget {
  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeBg;
  final Color inactiveBg;
  final Color activeFg;
  final Color inactiveFg;

  const _StatusPill({
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.activeBg,
    required this.inactiveBg,
    required this.activeFg,
    required this.inactiveFg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: active ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            color: active ? activeFg : inactiveFg,
            size: 10,
          ),
          const SizedBox(width: 5),
          Text(
            active ? activeLabel : inactiveLabel,
            style: TextStyle(
              fontSize: 14,
              color: active ? activeFg : inactiveFg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueAccessCard extends StatelessWidget {
  final VenueAccess venue;
  final String? parentBusinessName;

  final bool subtle;

  const _VenueAccessCard({
    required this.venue,
    required this.parentBusinessName,
    required this.subtle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Opacity(
      opacity: subtle ? 0.55 : 1.0,
      child: Material(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VenuePageWrapper(venueId: venue.venueId),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _VenueLogo(url: venue.logoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      if (parentBusinessName != null &&
                          parentBusinessName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          parentBusinessName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 11,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!subtle) ...[
                  const SizedBox(width: 8),
                  _RolePill(role: venue.venueRoleName),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueLogo extends StatelessWidget {
  final String? url;
  const _VenueLogo({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = Icon(
      TablerIcons.building_store,
      color: c.onSurfaceSecondary,
      size: 22,
    );
    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: 144,
              errorWidget: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}

class _RolePill extends StatelessWidget {
  final String? role;
  const _RolePill({required this.role});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final r = role ?? '';
    final (label, color) = switch (r) {
      'owner' || 'business_owner' => (LocaleKeys.business_role_owner.tr(), c.success),
      'manager' || 'business_manager' => (LocaleKeys.business_role_manager.tr(), c.primary),
      'staff' || 'business_staff' => (LocaleKeys.business_role_staff.tr(), c.onSurfaceSecondary),
      _ => (null, c.onSurfaceSecondary),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              TablerIcons.building_skyscraper,
              size: 56,
              color: c.onSurfaceSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              LocaleKeys.business_empty_no_business_title.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LocaleKeys.business_empty_no_business_body.tr(),
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
