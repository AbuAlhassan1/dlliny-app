import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/hub/controllers/my_upcoming_hangouts/my_upcoming_hangouts_bloc.dart';

class MyUpcomingHangoutsSection extends StatelessWidget {
  const MyUpcomingHangoutsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyUpcomingHangoutsBloc, MyUpcomingHangoutsState>(
      builder: (context, state) {
        if (state is MyUpcomingHangoutsInitial ||
            state is MyUpcomingHangoutsEmpty ||
            state is MyUpcomingHangoutsError) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(),
              const SizedBox(height: 10),
              switch (state) {
                MyUpcomingHangoutsLoaded(:final items) => _Carousel(items: items),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 8),
      child: Row(
        children: [
          Icon(TablerIcons.calendar_event, size: 16, color: c.onSurface),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.hub_my_upcoming_hangouts_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  final List<HangoutFeedItem> items;
  const _Carousel({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: UpcomingHangoutTile.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => UpcomingHangoutTile(item: items[i]),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: UpcomingHangoutTile.height,
      child: Center(
        child: CircularProgressIndicator(color: c.onSurface, strokeWidth: 1),
      ),
    );
  }
}

class UpcomingHangoutTile extends StatelessWidget {
  static const double width = 260;
  static const double height = 96;

  final HangoutFeedItem item;
  const UpcomingHangoutTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final venue = item.venue ?? item.organizerVenue;
    return SizedBox(
      width: width,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HangoutDetailsPageWrapper(hangoutId: item.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateTile(scheduledAt: item.scheduledAt),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _venueLabel(context, venue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      if (_branchLine(context, item.branch) != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _branchLine(context, item.branch)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const Spacer(),
                      _AttendeesRow(count: item.attendees.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _venueLabel(BuildContext context, HangoutOrganizerVenue? venue) {
    if (venue == null) return '';
    return context.pickBilingual(
      ar: venue.nameAr,
      en: venue.nameEn,
      fallback: venue.nameAr ?? venue.nameEn ?? '',
    );
  }

  String? _branchLine(BuildContext context, HangoutFeedBranch? branch) {
    if (branch == null) return null;
    final label = context.pickBilingual(
      ar: branch.labelAr,
      en: branch.labelEn,
      fallback: '',
    );
    if (label.isNotEmpty) return label;
    final address = context.pickBilingual(
      ar: branch.addressAr,
      en: branch.addressEn,
      fallback: '',
    );
    if (address.isNotEmpty) return address;
    return null;
  }
}

class _DateTile extends StatelessWidget {
  final String scheduledAt;
  const _DateTile({required this.scheduledAt});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dt = DateTime.tryParse(scheduledAt)?.toLocal();
    final locale = context.locale.toString();
    final day = dt == null ? '—' : DateFormat('d', locale).format(dt);
    final month = dt == null ? '' : DateFormat('MMM', locale).format(dt);
    final time = dt == null ? '' : DateFormat('h:mm a', locale).format(dt);
    return Container(
      width: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            width: double.infinity,
            color: c.primary,
            child: Text(
              month,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AttendeesRow extends StatelessWidget {
  final int count;
  const _AttendeesRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(TablerIcons.users, size: 11, color: c.onSurfaceSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            LocaleKeys.hub_my_upcoming_hangouts_attendees_count.tr(
              namedArgs: {'n': '$count'},
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

