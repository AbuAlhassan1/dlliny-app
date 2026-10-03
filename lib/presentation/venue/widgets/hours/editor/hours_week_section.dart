import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_apply_days_sheet.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_weekly_hours_table.dart';

const int kRamadanNudgeDays = 14;

class HoursWeekSection extends StatelessWidget {
  final ManageHoursState state;
  const HoursWeekSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final d = state.draft!;
    final isBranch = !d.isVenue;
    final enabled = state.phase == ManageHoursPhase.ready;
    final bloc = context.read<ManageHoursBloc>();
    final locale = hoursLocaleOf(context);
    final error = state.error?.isStatusError ?? false ? null : state.error;

    final children = <Widget>[
      HoursSectionTitle(LocaleKeys.venue_hours_title.tr()),
      const SizedBox(height: 6),
    ];

    if (isBranch) {
      children.add(
        _SwitchRow(
          label: LocaleKeys.manage_venue_hours_editor_branch_own.tr(),
          value: d.hours.own,
          onChanged: enabled
              ? (v) => bloc.add(BranchHoursModeChanged(v))
              : null,
        ),
      );
    }

    if (isBranch && !d.hours.own) {
      final venue = state.drafts[null]!.hours;
      final regular = venue.regular;
      final ramadan = venue.ramadan;
      final noDefault =
          state.model?.venue.regular == null && !(regular?.isComplete ?? false);
      children.addAll([
        HoursNote(
          icon: TablerIcons.info_circle,
          text: LocaleKeys.manage_venue_hours_editor_branch_inherit_hint.tr(),
        ),
        if (noDefault) ...[
          const SizedBox(height: 8),
          HoursNote(
            icon: TablerIcons.clock_question,
            color: c.warning,
            text: LocaleKeys.manage_venue_hours_editor_no_default_hours.tr(),
          ),
        ] else ...[
          if (regular != null) ...[
            const SizedBox(height: 8),
            WeeklyHoursRows(
              week: regular.toDto(),
              pendingDays: regular.incompleteDays,
            ),
          ],
          if (ramadan != null) ...[
            const SizedBox(height: 12),
            HoursSectionTitle(LocaleKeys.venue_hours_ramadan_hours.tr()),
            WeeklyHoursRows(
              week: ramadan.toDto(),
              pendingDays: ramadan.incompleteDays,
            ),
          ],
        ],
      ]);
    } else {
      final everyBranchOwns =
          state.branches.isNotEmpty &&
          state.branches.every(
            (b) => state.drafts[b.locationId]?.hours.own ?? false,
          );
      if (!isBranch && everyBranchOwns) {
        children.addAll([
          HoursNote(
            icon: TablerIcons.info_circle,
            color: c.warning,
            text: LocaleKeys.manage_venue_hours_editor_unused_default_hint.tr(),
          ),
          const SizedBox(height: 10),
        ]);
      }
      final ramadanTab = state.season == HoursSeason.ramadan;
      final ramadanWeek = d.hours.ramadan;
      final window = state.model?.ramadanWindow;
      final nudge =
          ramadanWeek == null &&
          window != null &&
          !window.active &&
          _daysUntil(state.today, window.startsOn) <= kRamadanNudgeDays;

      children.addAll([
        _SeasonTabs(
          selected: state.season,
          onChanged: (s) => bloc.add(HoursSeasonSelected(s)),
        ),
        const SizedBox(height: 10),
        if (nudge) ...[
          HoursNote(
            icon: TablerIcons.moon_stars,
            color: c.warning,
            text: LocaleKeys.manage_venue_hours_editor_ramadan_nudge.tr(),
            action: _LinkButton(
              label: LocaleKeys.manage_venue_hours_editor_add_ramadan.tr(),
              onPressed: enabled
                  ? () => bloc.add(const RamadanScheduleToggled(true))
                  : null,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (ramadanTab) ...[
          HoursNote(
            icon: TablerIcons.moon,
            text: [
              if (window != null) ramadanWindowLabel(window, locale),
              LocaleKeys.manage_venue_hours_editor_ramadan_auto_hint.tr(),
            ].join('\n'),
          ),
          const SizedBox(height: 10),
        ],
        if (ramadanTab && ramadanWeek == null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: enabled
                  ? () => bloc.add(const RamadanScheduleToggled(true))
                  : null,
              icon: Icon(TablerIcons.plus, size: 16, color: c.primary),
              label: Text(
                LocaleKeys.manage_venue_hours_editor_add_ramadan.tr(),
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
        else ...[
          _ApplyToDaysRow(
            week: ramadanTab ? ramadanWeek! : d.hours.regular!,
            subtitle: [
              (ramadanTab
                      ? LocaleKeys.manage_venue_hours_editor_tab_ramadan
                      : LocaleKeys.manage_venue_hours_editor_tab_regular)
                  .tr(),
              if (state.showsScopeChips) _scopeLabel(state, locale),
            ].join(' · '),
            enabled: enabled,
          ),
          _WeekEditor(
            week: ramadanTab ? ramadanWeek! : d.hours.regular!,
            enabled: enabled,
            highlightDow: error == null ? null : _errorDay(error),
          ),
          if (ramadanTab)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: enabled
                    ? () => bloc.add(const RamadanScheduleToggled(false))
                    : null,
                icon: Icon(TablerIcons.trash, size: 16, color: c.danger),
                label: Text(
                  LocaleKeys.manage_venue_hours_editor_remove_ramadan.tr(),
                  style: TextStyle(
                    color: c.danger,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
            ),
        ],
      ]);
    }

    if (error != null) {
      children.addAll([
        const SizedBox(height: 10),
        HoursNote(
          icon: TablerIcons.alert_triangle,
          color: c.danger,
          text: hoursEditorErrorMessage(error, locale),
        ),
      ]);
    }

    return HoursPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  static String _scopeLabel(ManageHoursState state, String locale) {
    final id = state.selectedScope;
    if (id == null) {
      return LocaleKeys.manage_venue_hours_editor_scope_all_branches.tr();
    }
    for (final b in state.branches) {
      if (b.locationId == id) return branchScopeLabel(b, locale);
    }
    return LocaleKeys.venue_branches_branch_fallback.tr();
  }

  static int? _errorDay(HoursEditorError e) =>
      e.dayOfWeek ??
      (e.conflict.isNotEmpty ? e.conflict.first.dayOfWeek : null);

  static int _daysUntil(String? today, String date) {
    final a = today == null ? null : parseYmd(today);
    final b = parseYmd(date);
    if (a == null || b == null) return 1 << 20;
    return b.difference(a).inDays;
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({required this.label, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: c.primary,
        ),
      ],
    );
  }
}

class _SeasonTabs extends StatelessWidget {
  final HoursSeason selected;
  final ValueChanged<HoursSeason> onChanged;

  const _SeasonTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget tab(HoursSeason season, String label) {
      final on = season == selected;
      return Expanded(
        child: Material(
          color: on ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: on ? null : () => onChanged(season),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: on ? c.onPrimary : c.onSurfaceSecondary,
                  fontSize: 13,
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
          tab(
            HoursSeason.regular,
            LocaleKeys.manage_venue_hours_editor_tab_regular.tr(),
          ),
          const SizedBox(width: 3),
          tab(
            HoursSeason.ramadan,
            LocaleKeys.manage_venue_hours_editor_tab_ramadan.tr(),
          ),
        ],
      ),
    );
  }
}

class _ApplyToDaysRow extends StatelessWidget {
  final DraftWeek week;
  final String subtitle;
  final bool enabled;

  const _ApplyToDaysRow({
    required this.week,
    required this.subtitle,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      key: const ValueKey('hours-apply-days'),
      borderRadius: BorderRadius.circular(10),
      onTap: !enabled
          ? null
          : () async {
              final bloc = context.read<ManageHoursBloc>();
              final choice = await showHoursApplyDaysSheet(
                context,
                week: week,
                subtitle: subtitle,
              );
              if (choice == null || bloc.isClosed) return;
              bloc.add(
                HoursRangeApplied(
                  choice.opens,
                  choice.closes,
                  choice.days,
                  mode: choice.mode,
                ),
              );
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Row(
          children: [
            Icon(TablerIcons.calendar_time, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LocaleKeys.manage_venue_hours_editor_apply_days.tr(),
                style: TextStyle(
                  color: c.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekEditor extends StatelessWidget {
  final DraftWeek week;
  final bool enabled;

  final int? highlightDow;

  const _WeekEditor({
    required this.week,
    required this.enabled,
    this.highlightDow,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        for (var i = 0; i < kIraqWeekOrder.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: c.divider),
          _DayEditor(
            key: ValueKey('hours-day-${kIraqWeekOrder[i]}'),
            day: week.day(kIraqWeekOrder[i]),
            enabled: enabled,
            highlighted: highlightDow == kIraqWeekOrder[i],
          ),
        ],
      ],
    );
  }
}

class _DayEditor extends StatelessWidget {
  final DraftDay day;
  final bool enabled;
  final bool highlighted;

  const _DayEditor({
    super.key,
    required this.day,
    required this.enabled,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final locale = hoursLocaleOf(context);
    final bloc = context.read<ManageHoursBloc>();
    final dow = day.dayOfWeek;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: highlighted
          ? BoxDecoration(
              color: c.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  weekdayName(dow, locale),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
              Expanded(
                child: _KindSelector(
                  kind: day.kind,
                  onChanged: enabled
                      ? (k) => bloc.add(HoursDayKindChanged(dow, k))
                      : null,
                ),
              ),
              PopupMenuButton<String>(
                enabled: enabled,
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                icon: Icon(
                  TablerIcons.dots_vertical,
                  size: 18,
                  color: c.onSurfaceSecondary,
                ),
                onSelected: (_) => bloc.add(HoursDayCopiedToAll(dow)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'copy',
                    child: Row(
                      children: [
                        Icon(TablerIcons.copy, size: 16, color: c.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          LocaleKeys.manage_venue_hours_editor_copy_to_all.tr(),
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (day.kind == HoursDayKind.hours) ...[
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < day.intervals.length; i++)
                  _IntervalChip(
                    interval: day.intervals[i],
                    enabled: enabled,
                    onTap: () async {
                      final current = day.intervals[i];
                      final (opens, closes) = await pickInterval(
                        context,
                        opens: current.opens,
                        closes: current.closes,
                      );
                      if (opens == null || bloc.isClosed) return;
                      bloc.add(
                        HoursIntervalChanged(
                          dow,
                          i,
                          opens: opens,
                          closes: closes,
                        ),
                      );
                    },
                    onRemove: day.intervals.length > 1
                        ? () => bloc.add(HoursIntervalRemoved(dow, i))
                        : null,
                  ),
                if (day.intervals.length < kMaxIntervalsPerDay)
                  _AddIntervalChip(
                    onTap: enabled
                        ? () => bloc.add(HoursIntervalAdded(dow))
                        : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  final HoursDayKind kind;
  final ValueChanged<HoursDayKind>? onChanged;

  const _KindSelector({required this.kind, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const kinds = [
      HoursDayKind.closed,
      HoursDayKind.open24h,
      HoursDayKind.hours,
    ];
    Widget option(int index, String label) {
      final k = kinds[index];
      final on = k == kind;
      final first = index == 0;
      final last = index == kinds.length - 1;
      return Expanded(
        child: Semantics(
          container: true,
          button: true,
          selected: on,
          inMutuallyExclusiveGroup: true,
          child: MinTapTarget(
            child: Container(
              padding: EdgeInsetsDirectional.fromSTEB(
                first ? 2 : 0,
                2,
                last ? 2 : 0,
                2,
              ),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadiusDirectional.horizontal(
                  start: first ? const Radius.circular(10) : Radius.zero,
                  end: last ? const Radius.circular(10) : Radius.zero,
                ),
              ),
              child: Material(
                color: on ? c.surfaceAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: on || onChanged == null ? null : () => onChanged!(k),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(0, LocaleKeys.manage_venue_hours_editor_day_closed.tr()),
        option(1, LocaleKeys.manage_venue_hours_editor_day_24h.tr()),
        option(2, LocaleKeys.manage_venue_hours_editor_day_hours.tr()),
      ],
    );
  }
}

class _IntervalChip extends StatelessWidget {
  final DraftInterval interval;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _IntervalChip({
    required this.interval,
    required this.enabled,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final locale = hoursLocaleOf(context);
    final complete = interval.isComplete;
    final String label;
    if (complete) {
      label = formatInterval(
        HoursIntervalDto(
          opens: interval.opens!,
          closes: interval.closes!,
          overnight: interval.overnight,
        ),
        locale,
      );
    } else if (interval.opens != null) {
      label =
          '\u2068${formatHm(interval.opens!, locale)}\u2069 – ${LocaleKeys.manage_venue_hours_editor_pick_time.tr()}';
    } else {
      label = LocaleKeys.manage_venue_hours_editor_pick_time.tr();
    }
    final tappable = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
    final Widget chip = complete
        ? Material(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            child: tappable,
          )
        : DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: const Radius.circular(10),
              color: c.warning,
              strokeWidth: 1.2,
              dashPattern: const [5, 4],
              padding: EdgeInsets.zero,
            ),
            child: tappable,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            container: true,
            button: true,
            child: MinTapTarget(child: chip),
          ),
        ),
        if (onRemove != null)
          IconButton(
            onPressed: enabled ? onRemove : null,
            tooltip: LocaleKeys.manage_venue_hours_editor_remove_interval.tr(),
            icon: Icon(TablerIcons.x, size: 16, color: c.onSurfaceSecondary),
          ),
      ],
    );
  }
}

class _AddIntervalChip extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddIntervalChip({this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      container: true,
      button: true,
      child: MinTapTarget(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Text(
              LocaleKeys.manage_venue_hours_editor_add_interval.tr(),
              style: TextStyle(
                color: c.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _LinkButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: TextStyle(
        color: context.c.primary,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    ),
  );
}
