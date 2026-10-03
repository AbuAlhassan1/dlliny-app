import 'package:easy_localization/easy_localization.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

const List<int> kIraqWeekOrder = [6, 0, 1, 2, 3, 4, 5];

String weekdayName(int dow, String locale) =>
    DateFormat('EEEE', locale).format(DateTime(2026, 10, 4 + dow % 7));

String formatHm(String hhmm, String locale) {
  final t = _parseHm(hhmm);
  if (t == null) return hhmm;
  return DateFormat('h:mm a', locale).format(DateTime(2000, 1, 1, t.$1, t.$2));
}

String formatInterval(HoursIntervalDto i, String locale) {
  final midnight = i.closes == '00:00';
  final close = midnight
      ? LocaleKeys.venue_hours_midnight.tr()
      : formatHm(i.closes, locale);
  final tail = (i.overnight && !midnight)
      ? ' ${LocaleKeys.venue_hours_next_day.tr()}'
      : '';
  return '\u2068${formatHm(i.opens, locale)}\u2069 – \u2068$close\u2069$tail';
}

String formatDayRule(
  HoursDayKind kind,
  List<HoursIntervalDto> intervals,
  String locale, {
  String? separator,
}) {
  switch (kind) {
    case HoursDayKind.closed:
      return LocaleKeys.venue_hours_day_closed.tr();
    case HoursDayKind.open24h:
      return LocaleKeys.venue_hours_open_24h.tr();
    case HoursDayKind.hours:
      if (intervals.isEmpty) return LocaleKeys.venue_hours_day_closed.tr();
      final sep = separator ?? (locale.startsWith('ar') ? '، ' : ', ');
      return intervals.map((i) => formatInterval(i, locale)).join(sep);
  }
}

String formatHoursDate(String ymd, String locale) {
  final d = parseYmd(ymd);
  if (d == null) return ymd;
  return DateFormat('d MMM', locale).format(DateTime(d.year, d.month, d.day));
}

String statusLabel(OpenStatusDto s, String locale) {
  switch (s.state) {
    case OpenState.permanentlyClosed:
      return LocaleKeys.venue_hours_permanently_closed.tr();
    case OpenState.temporarilyClosed:
      final closed = LocaleKeys.venue_hours_temporarily_closed.tr();
      final reopens = s.reopensOn;
      if (reopens == null) return closed;
      return '$closed · ${LocaleKeys.venue_hours_reopens_on.tr(namedArgs: {'date': formatHoursDate(reopens, locale)})}';
    case OpenState.unknown:
      return '';
    case OpenState.open:
      if (s.alwaysOpen) return LocaleKeys.venue_hours_open_24h.tr();
      final closes = s.closesAt;
      if (s.closingSoon) {
        final soon = LocaleKeys.venue_hours_closes_soon.tr();
        return closes == null ? soon : '$soon · ${_closeTime(closes, locale)}';
      }
      final open = LocaleKeys.venue_hours_open_now.tr();
      return closes == null ? open : '$open · ${_closes(closes, locale)}';
    case OpenState.closed:
      final opens = s.opensAt;
      final closed = LocaleKeys.venue_hours_closed_now.tr();
      if (opens == null) return closed;
      if (s.openingSoon) {
        return '${LocaleKeys.venue_hours_opens_soon.tr()} · ${formatHm(opens.localTime, locale)}';
      }
      return '$closed · ${_opens(opens, locale)}';
  }
}

String _closeTime(HoursMomentDto m, String locale) => m.localTime == '00:00'
    ? LocaleKeys.venue_hours_midnight.tr()
    : formatHm(m.localTime, locale);

String _closes(HoursMomentDto m, String locale) {
  if (m.localTime == '00:00') {
    final d = m.dayOffset - 1;
    if (d <= 0) return LocaleKeys.venue_hours_closes_at_midnight.tr();
    if (d == 1) return LocaleKeys.venue_hours_closes_tomorrow_at_midnight.tr();
    return LocaleKeys.venue_hours_closes_day_at_midnight.tr(
      namedArgs: {'day': weekdayName((m.dayOfWeek + 6) % 7, locale)},
    );
  }
  final t = formatHm(m.localTime, locale);
  if (m.dayOffset <= 0 ||
      (m.dayOffset == 1 && m.localTime.compareTo('06:00') < 0)) {
    return LocaleKeys.venue_hours_closes_at.tr(namedArgs: {'time': t});
  }
  if (m.dayOffset == 1) {
    return LocaleKeys.venue_hours_closes_tomorrow_at.tr(namedArgs: {'time': t});
  }
  return LocaleKeys.venue_hours_closes_day_at.tr(
    namedArgs: {'day': weekdayName(m.dayOfWeek, locale), 'time': t},
  );
}

String _opens(HoursMomentDto m, String locale) {
  final t = formatHm(m.localTime, locale);
  final day = weekdayName(m.dayOfWeek, locale);
  return switch (m.dayOffset) {
    <= 0 => LocaleKeys.venue_hours_opens_at.tr(namedArgs: {'time': t}),
    1 => LocaleKeys.venue_hours_opens_tomorrow_at.tr(namedArgs: {'time': t}),
    < 7 => LocaleKeys.venue_hours_opens_day_at.tr(
      namedArgs: {'day': day, 'time': t},
    ),
    _ => LocaleKeys.venue_hours_opens_next_week_day_at.tr(
      namedArgs: {'day': day, 'time': t},
    ),
  };
}

enum HoursStatusTone { success, warning, muted, danger }

HoursStatusTone? statusTone(OpenStatusDto s) => switch (s.state) {
  OpenState.open =>
    s.closingSoon && !s.alwaysOpen
        ? HoursStatusTone.warning
        : HoursStatusTone.success,
  OpenState.closed =>
    s.openingSoon && s.opensAt != null
        ? HoursStatusTone.warning
        : HoursStatusTone.muted,
  OpenState.temporarilyClosed => HoursStatusTone.warning,
  OpenState.permanentlyClosed => HoursStatusTone.danger,
  OpenState.unknown => null,
};

bool isStatusVisible(OpenStatusDto? s) =>
    s != null && s.state != OpenState.unknown;

enum HoursRowLabel { today, tonight }

class HoursRowChoice {
  final HoursRowLabel label;
  final TodayHoursDto day;
  const HoursRowChoice(this.label, this.day);
}

HoursRowChoice? hoursRowFor(ScopeHoursDto scope) {
  switch (scope.status.state) {
    case OpenState.temporarilyClosed:
    case OpenState.permanentlyClosed:
      return null;
    case OpenState.open:
      final last = scope.lastNight;
      if (last != null) return HoursRowChoice(HoursRowLabel.tonight, last);
    case OpenState.closed:
    case OpenState.unknown:
      break;
  }
  final today = scope.today;
  return today == null ? null : HoursRowChoice(HoursRowLabel.today, today);
}

bool showsWeeklyHours(ScopeHoursDto scope) =>
    scope.regular != null && scope.status.state != OpenState.permanentlyClosed;

String hoursRowLabelText(HoursRowLabel label) => switch (label) {
  HoursRowLabel.today => LocaleKeys.venue_hours_today.tr(),
  HoursRowLabel.tonight => LocaleKeys.venue_hours_tonight.tr(),
};

HoursSeason? badgeSeason(ScopeHoursDto scope) => switch (scope.status.state) {
  OpenState.open => scope.status.spanSeason,
  OpenState.closed => scope.today?.season,
  _ => null,
};

bool showsRamadanBadge(ScopeHoursDto scope) =>
    badgeSeason(scope) == HoursSeason.ramadan;

bool showsRamadanStartsTonight(ScopeHoursDto scope) =>
    (scope.status.state == OpenState.open ||
        scope.status.state == OpenState.closed) &&
    !showsRamadanBadge(scope) &&
    (scope.today?.ramadanEveIntervals.isNotEmpty ?? false);

String baghdadToday(VenueOpeningHoursDto oh) =>
    oh.summary.today?.date ?? oh.evaluatedAt.substring(0, 10);

int? dayOfWeekOfYmd(String ymd) {
  final d = parseYmd(ymd);
  return d == null ? null : d.weekday % 7;
}

List<DayScheduleDto> daysInIraqOrder(WeeklyScheduleDto week) => [
  for (final dow in kIraqWeekOrder)
    week.day(dow) ?? DayScheduleDto(dayOfWeek: dow),
];

DateTime? parseYmd(String ymd) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(ymd);
  if (m == null) return null;
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

String formatYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String? baghdadDateOf(String isoInstant) {
  final t = DateTime.tryParse(isoInstant);
  if (t == null) return null;
  return formatYmd(t.toUtc().add(const Duration(hours: 3)));
}

String? updatedOnLabel(String isoInstant, String locale) {
  final ymd = baghdadDateOf(isoInstant);
  if (ymd == null) return null;
  return LocaleKeys.venue_hours_updated_on.tr(
    namedArgs: {'date': formatHoursDate(ymd, locale)},
  );
}

String ramadanWindowLabel(RamadanWindowDto w, String locale) =>
    LocaleKeys.manage_venue_hours_editor_ramadan_window.tr(
      namedArgs: {
        'start': formatHoursDate(w.startsOn, locale),
        'end': formatHoursDate(w.endsOn, locale),
      },
    );

(int, int)? _parseHm(String hhmm) {
  final m = RegExp(r'^(\d{2}):(\d{2})').firstMatch(hhmm);
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return (h, min);
}
