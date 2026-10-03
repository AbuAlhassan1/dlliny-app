import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

class VenueWeeklyHoursTable extends StatefulWidget {
  final ScopeHoursDto scope;
  final RamadanWindowDto? ramadanWindow;

  final String today;

  const VenueWeeklyHoursTable({
    super.key,
    required this.scope,
    required this.today,
    this.ramadanWindow,
  });

  @override
  State<VenueWeeklyHoursTable> createState() => _VenueWeeklyHoursTableState();
}

class _VenueWeeklyHoursTableState extends State<VenueWeeklyHoursTable> {
  HoursSeason? _picked;

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final regular = scope.regular;
    if (regular == null) return const SizedBox.shrink();
    final window = widget.ramadanWindow;
    final ramadan = scope.ramadan;
    final hasToggle = ramadan != null && window != null;
    final season =
        _picked ??
        (hasToggle && window.active
            ? HoursSeason.ramadan
            : HoursSeason.regular);
    final week = season == HoursSeason.ramadan && ramadan != null
        ? ramadan
        : regular;
    final locale = hoursLocaleOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasToggle) ...[
          _SeasonToggle(
            selected: season,
            onChanged: (s) => setState(() => _picked = s),
          ),
          const SizedBox(height: 10),
        ],
        if (ramadan != null && window != null && !window.active) ...[
          Text(
            LocaleKeys.venue_hours_ramadan_starts_on.tr(
              namedArgs: {'date': formatHoursDate(window.startsOn, locale)},
            ),
            style: TextStyle(
              color: context.c.onSurfaceSecondary,
              fontSize: 12,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 8),
        ],
        WeeklyHoursRows(
          week: week,
          todayDow: dayOfWeekOfYmd(widget.today),
          tonightDow: scope.lastNight?.dayOfWeek,
        ),
      ],
    );
  }
}

class WeeklyHoursRows extends StatelessWidget {
  final WeeklyScheduleDto week;

  final int? todayDow;

  final int? tonightDow;

  final Set<int> pendingDays;

  const WeeklyHoursRows({
    super.key,
    required this.week,
    this.todayDow,
    this.tonightDow,
    this.pendingDays = const {},
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final locale = hoursLocaleOf(context);
    final days = daysInIraqOrder(week);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: c.divider),
          _DayRow(
            day: days[i],
            locale: locale,
            isToday: days[i].dayOfWeek == todayDow,
            isTonight: days[i].dayOfWeek == tonightDow,
            pending: pendingDays.contains(days[i].dayOfWeek),
          ),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DayScheduleDto day;
  final String locale;
  final bool isToday;
  final bool isTonight;
  final bool pending;

  const _DayRow({
    required this.day,
    required this.locale,
    required this.isToday,
    required this.isTonight,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final weight = isToday ? FontWeight.bold : FontWeight.w500;
    final muted =
        pending ||
        day.kind == HoursDayKind.closed ||
        (day.kind == HoursDayKind.hours && day.intervals.isEmpty);
    final lines = switch (day.kind) {
      _ when pending => const ['—'],
      HoursDayKind.hours when day.intervals.isNotEmpty => [
        for (final i in day.intervals) formatInterval(i, locale),
      ],
      _ => [formatDayRule(day.kind, day.intervals, locale)],
    };
    final valueStyle = TextStyle(
      color: muted ? c.onSurfaceSecondary : c.onSurface,
      fontSize: 13,
      fontWeight: weight,
      fontFamily: 'IBMPlexSansArabic',
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  weekdayName(day.dayOfWeek, locale),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: weight,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                if (isToday) _Tag(text: LocaleKeys.venue_hours_today.tr()),
                if (isTonight) _Tag(text: LocaleKeys.venue_hours_tonight.tr()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final line in lines)
                  Text(line, style: valueStyle, textAlign: TextAlign.end),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: c.surfaceAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c.onSurfaceAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _SeasonToggle extends StatelessWidget {
  final HoursSeason selected;
  final ValueChanged<HoursSeason> onChanged;

  const _SeasonToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget segment(HoursSeason season, String label) {
      final on = season == selected;
      return Expanded(
        child: Material(
          color: on ? c.surfaceAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: on ? null : () => onChanged(season),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: on ? c.onSurfaceAccent : c.onSurfaceSecondary,
                  fontSize: 12,
                  fontWeight: on ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          segment(
            HoursSeason.ramadan,
            LocaleKeys.venue_hours_ramadan_hours.tr(),
          ),
          const SizedBox(width: 3),
          segment(
            HoursSeason.regular,
            LocaleKeys.venue_hours_regular_hours.tr(),
          ),
        ],
      ),
    );
  }
}
