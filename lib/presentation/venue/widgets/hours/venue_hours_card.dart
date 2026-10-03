import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_hours_editor_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_weekly_hours_table.dart';
import 'package:hangout/presentation/venue/widgets/venue_about_constants.dart';

class VenueHoursCard extends StatefulWidget {
  final VenueResponse venue;

  final VoidCallback? onShowBranches;

  const VenueHoursCard({super.key, required this.venue, this.onShowBranches});

  @override
  State<VenueHoursCard> createState() => _VenueHoursCardState();
}

class _VenueHoursCardState extends State<VenueHoursCard> {
  bool _expanded = false;

  Future<void> _openEditor() async {
    final venueBloc = context.read<VenueBloc>();
    final hoursBloc = maybeVenueHoursBloc(context);
    final saved = await VenueHoursEditorPage.push(context, widget.venue.id);
    if (saved != true) return;
    if (!venueBloc.isClosed) venueBloc.add(GetVenueDetails(widget.venue.id));
    if (hoursBloc != null && !hoursBloc.isClosed) {
      hoursBloc.add(const VenueHoursRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoursBloc = maybeVenueHoursBloc(context);
    if (hoursBloc == null) return _build(context, widget.venue.openingHours);
    return BlocBuilder<VenueHoursBloc, VenueHoursState>(
      bloc: hoursBloc,
      builder: (context, state) =>
          _build(context, state.dto ?? widget.venue.openingHours),
    );
  }

  Widget _build(BuildContext context, VenueOpeningHoursDto? oh) {
    if (oh == null) return const SizedBox.shrink();
    final canEdit = userHasOnVenue(
      context,
      VenuePerm.hoursManage,
      widget.venue.id,
    );
    final scope = oh.summary;
    if (!isStatusVisible(scope.status)) {
      if (!canEdit) return const SizedBox.shrink();
      return Padding(
        padding: kVenueAboutPartPadding,
        child: _AddHoursCta(onTap: _openEditor),
      );
    }

    final c = context.c;
    final locale = hoursLocaleOf(context);
    final row = hoursRowFor(scope);
    final eve = row?.day.ramadanEveIntervals ?? const <HoursIntervalDto>[];
    final updated = scope.hoursUpdatedAt == null
        ? null
        : updatedOnLabel(scope.hoursUpdatedAt!, locale);

    return Padding(
      padding: kVenueAboutPartPadding,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(onEdit: canEdit ? _openEditor : null),
            VenueOpenStatusLine(status: scope.status, fontSize: 15),
            if (showsRamadanBadge(scope)) ...[
              const SizedBox(height: 8),
              const _RamadanBadge(),
            ],
            if (row != null) ...[
              const SizedBox(height: 10),
              _HoursRow(
                label: hoursRowLabelText(row.label),
                value: formatDayRule(
                  row.day.kind,
                  row.day.intervals,
                  locale,
                  separator: '\n',
                ),
              ),
              if (eve.isNotEmpty) ...[
                const SizedBox(height: 6),
                _HoursRow(
                  label: LocaleKeys.venue_hours_ramadan_first_night.tr(),
                  value: eve.map((i) => formatInterval(i, locale)).join('\n'),
                ),
              ],
            ],
            if (showsRamadanStartsTonight(scope)) ...[
              const SizedBox(height: 8),
              _Hint(
                icon: TablerIcons.moon,
                text: LocaleKeys.venue_hours_ramadan_starts_tonight.tr(),
              ),
            ],
            if (oh.variesByBranch) ...[
              const SizedBox(height: 8),
              _Hint(
                icon: TablerIcons.building_store,
                text: LocaleKeys.venue_hours_varies_by_branch.tr(),
                onTap: widget.onShowBranches,
              ),
            ],
            if (showsWeeklyHours(scope)) ...[
              const SizedBox(height: 6),
              _ExpandToggle(
                expanded: _expanded,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: AlignmentDirectional.topCenter,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(top: 4),
                        child: VenueWeeklyHoursTable(
                          scope: scope,
                          today: baghdadToday(oh),
                          ramadanWindow: oh.ramadanWindow,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
            if (updated != null) ...[
              const SizedBox(height: 6),
              Text(
                updated,
                style: TextStyle(
                  color: c.onSurfaceMuted,
                  fontSize: 11,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onEdit;
  const _Header({this.onEdit});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
      child: Row(
        children: [
          Icon(TablerIcons.clock, color: c.onSurface, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.venue_hours_title.tr(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: Icon(TablerIcons.pencil, color: c.primary, size: 14),
              label: Text(
                LocaleKeys.venue_hours_edit.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                minimumSize: const Size(48, 32),
                tapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.standard,
              ),
            ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String label;
  final String value;
  const _HoursRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            label,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}

class _RamadanBadge extends StatelessWidget {
  const _RamadanBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 10, 3),
        decoration: BoxDecoration(
          color: c.surfaceAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.moon_stars, color: c.onSurfaceAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              LocaleKeys.venue_hours_ramadan_active.tr(),
              style: TextStyle(
                color: c.onSurfaceAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _Hint({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = onTap == null ? c.onSurfaceSecondary : c.primary;
    final content = Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: content,
      ),
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _ExpandToggle({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              expanded
                  ? LocaleKeys.venue_hours_hide_week.tr()
                  : LocaleKeys.venue_hours_show_week.tr(),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              expanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
              color: c.onSurfaceSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddHoursCta extends StatelessWidget {
  final VoidCallback onTap;
  const _AddHoursCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.clock_plus, color: c.onSurface, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocaleKeys.venue_hours_add_cta.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? TablerIcons.chevron_left
                    : TablerIcons.chevron_right,
                color: c.onSurfaceSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
