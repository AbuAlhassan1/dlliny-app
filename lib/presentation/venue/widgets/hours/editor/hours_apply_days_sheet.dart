import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

class HoursApplyChoice {
  final String opens;
  final String closes;

  final Set<int> days;
  final ApplyRangeMode mode;

  const HoursApplyChoice({
    required this.opens,
    required this.closes,
    required this.days,
    required this.mode,
  });
}

Future<HoursApplyChoice?> showHoursApplyDaysSheet(
  BuildContext context, {
  required DraftWeek week,
  required String subtitle,
}) => showModalBottomSheet<HoursApplyChoice>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => HoursApplyDaysSheet(week: week, subtitle: subtitle),
);

class HoursApplyDaysSheet extends StatefulWidget {
  final DraftWeek week;
  final String subtitle;

  const HoursApplyDaysSheet({
    super.key,
    required this.week,
    required this.subtitle,
  });

  @override
  State<HoursApplyDaysSheet> createState() => _HoursApplyDaysSheetState();
}

class _HoursApplyDaysSheetState extends State<HoursApplyDaysSheet> {
  String? _opens;
  String? _closes;
  Set<int> _days = const {};
  ApplyRangeMode _mode = ApplyRangeMode.replace;

  static const Set<int> _allDays = {0, 1, 2, 3, 4, 5, 6};

  Future<void> _pickOpens() async {
    final picked = await pickHm(
      context,
      helpText: LocaleKeys.manage_venue_hours_editor_opens_time.tr(),
      initial: _opens,
    );
    if (picked == null || !mounted) return;
    setState(() => _opens = picked);
    if (_closes == null) await _pickCloses();
  }

  Future<void> _pickCloses() async {
    final picked = await pickHm(
      context,
      helpText: LocaleKeys.manage_venue_hours_editor_closes_time.tr(),
      initial: _closes,
      fallback: '17:00',
    );
    if (picked == null || !mounted) return;
    setState(() => _closes = picked);
  }

  void _toggle(int dow) => setState(
    () =>
        _days = _days.contains(dow) ? _days.difference({dow}) : {..._days, dow},
  );

  void _toggleAll() =>
      setState(() => _days = _days.length == 7 ? const {} : _allDays);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mq = MediaQuery.of(context);
    final locale = hoursLocaleOf(context);
    final opens = _opens;
    final closes = _closes;
    final range = opens != null && closes != null
        ? DraftInterval(opens: opens, closes: closes)
        : null;
    final rangeError = range == null ? null : rangeErrorCode(opens!, closes!);
    final conflicts = range == null || rangeError != null || _days.isEmpty
        ? const <int, ApplyRangeConflict>{}
        : widget.week.applyConflicts(range, _days, _mode);
    final replaceHelps =
        conflicts.isNotEmpty &&
        _mode == ApplyRangeMode.add &&
        widget.week
                .applyConflicts(range!, _days, ApplyRangeMode.replace)
                .length <
            conflicts.length;
    final canApply =
        range != null &&
        rangeError == null &&
        _days.isNotEmpty &&
        conflicts.isEmpty;

    String? closesLabel;
    if (closes != null) {
      closesLabel = closes == '00:00'
          ? LocaleKeys.venue_hours_midnight.tr()
          : formatHm(closes, locale);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(subtitle: widget.subtitle),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionLabel(
                        LocaleKeys.manage_venue_hours_editor_apply_days_range
                            .tr(),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TimeField(
                              key: const ValueKey('apply-days-opens'),
                              label: LocaleKeys
                                  .manage_venue_hours_editor_opens_time
                                  .tr(),
                              value: opens == null
                                  ? null
                                  : formatHm(opens, locale),
                              onTap: _pickOpens,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TimeField(
                              key: const ValueKey('apply-days-closes'),
                              label: LocaleKeys
                                  .manage_venue_hours_editor_closes_time
                                  .tr(),
                              value: closesLabel,
                              note:
                                  range != null &&
                                      range.overnight &&
                                      closes != '00:00' &&
                                      rangeError == null
                                  ? LocaleKeys.venue_hours_next_day.tr()
                                  : null,
                              onTap: _pickCloses,
                            ),
                          ),
                        ],
                      ),
                      if (rangeError != null) ...[
                        const SizedBox(height: 10),
                        HoursNote(
                          icon: TablerIcons.alert_triangle,
                          color: c.danger,
                          text: hoursEditorErrorText(rangeError),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _SectionLabel(
                        LocaleKeys.manage_venue_hours_editor_apply_days_days
                            .tr(),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _DayChip(
                            key: const ValueKey('apply-days-all'),
                            label: LocaleKeys
                                .manage_venue_hours_editor_apply_days_all
                                .tr(),
                            selected: _days.length == 7,
                            onTap: _toggleAll,
                          ),
                          for (final dow in kIraqWeekOrder)
                            _DayChip(
                              key: ValueKey('apply-days-day-$dow'),
                              label: weekdayName(dow, locale),
                              selected: _days.contains(dow),
                              conflict: conflicts[dow] == null
                                  ? null
                                  : _conflictReason(
                                      conflicts[dow]!,
                                      dow,
                                      locale,
                                    ),
                              onTap: () => _toggle(dow),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionLabel(
                        LocaleKeys.manage_venue_hours_editor_apply_days_mode
                            .tr(),
                      ),
                      _ModeOption(
                        key: const ValueKey('apply-days-mode-replace'),
                        title: LocaleKeys
                            .manage_venue_hours_editor_apply_mode_replace
                            .tr(),
                        hint: LocaleKeys
                            .manage_venue_hours_editor_apply_mode_replace_hint
                            .tr(),
                        selected: _mode == ApplyRangeMode.replace,
                        onTap: () =>
                            setState(() => _mode = ApplyRangeMode.replace),
                      ),
                      const SizedBox(height: 6),
                      _ModeOption(
                        key: const ValueKey('apply-days-mode-add'),
                        title: LocaleKeys
                            .manage_venue_hours_editor_apply_mode_add
                            .tr(),
                        hint: LocaleKeys
                            .manage_venue_hours_editor_apply_mode_add_hint
                            .tr(),
                        selected: _mode == ApplyRangeMode.add,
                        onTap: () => setState(() => _mode = ApplyRangeMode.add),
                      ),
                      if (conflicts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ConflictNote(
                          conflicts: conflicts,
                          locale: locale,
                          suggestReplace: replaceHelps,
                          onDeselect: () => setState(
                            () => _days = _days.difference(
                              conflicts.keys.toSet(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey('apply-days-apply'),
                    onPressed: canApply
                        ? () => Navigator.of(context).pop(
                            HoursApplyChoice(
                              opens: opens!,
                              closes: closes!,
                              days: Set.unmodifiable(_days),
                              mode: _mode,
                            ),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      disabledBackgroundColor: c.surfaceMuted,
                      disabledForegroundColor: c.onSurfaceDisabled,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      LocaleKeys.manage_venue_hours_editor_apply.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String subtitle;
  const _Header({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.manage_venue_hours_editor_apply_days.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: context.c.onSurface,
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    ),
  );
}

class _TimeField extends StatelessWidget {
  final String label;
  final String? value;
  final String? note;
  final VoidCallback onTap;

  const _TimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final picked = value != null;
    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 64,
          minWidth: double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? LocaleKeys.manage_venue_hours_editor_pick_time.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: picked ? 15 : 13.5,
                  fontWeight: picked ? FontWeight.bold : FontWeight.w600,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      button: true,
      child: picked
          ? Material(
              color: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.border),
              ),
              child: body,
            )
          : DottedBorder(
              options: RoundedRectDottedBorderOptions(
                radius: const Radius.circular(12),
                color: c.warning,
                strokeWidth: 1.2,
                dashPattern: const [5, 4],
                padding: EdgeInsets.zero,
              ),
              child: Material(color: Colors.transparent, child: body),
            ),
    );
  }
}

String _conflictReason(ApplyRangeConflict conflict, int dow, String locale) {
  final other = conflict.other;
  if (conflict.kind == ApplyConflictKind.tooMany) {
    return LocaleKeys.manage_venue_hours_editor_apply_conflict_chip_too_many
        .tr();
  }
  if (other == null || other.dayOfWeek == dow) {
    return LocaleKeys.manage_venue_hours_editor_apply_conflict_chip_same_day
        .tr();
  }
  return LocaleKeys.manage_venue_hours_editor_apply_conflict_chip_other_day.tr(
    namedArgs: {'day': weekdayName(other.dayOfWeek, locale)},
  );
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? conflict;
  final VoidCallback onTap;

  const _DayChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = selected ? c.onPrimary : c.onSurface;
    final flagged = conflict != null;
    final mark = flagged
        ? TablerIcons.alert_triangle
        : selected
        ? TablerIcons.check
        : null;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      value: conflict,
      child: MinTapTarget(
        child: Material(
          color: selected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: flagged
                      ? c.warning
                      : selected
                      ? c.primary
                      : c.border,
                  width: flagged ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mark != null) ...[
                    Icon(mark, size: 14, color: fg),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
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

class _ModeOption extends StatelessWidget {
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    super.key,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: selected ? c.surfaceMuted : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? c.borderStrong : c.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected ? TablerIcons.circle_dot : TablerIcons.circle,
                    size: 20,
                    color: selected ? c.primary : c.onSurfaceSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 13.5,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
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

class _ConflictNote extends StatelessWidget {
  final Map<int, ApplyRangeConflict> conflicts;
  final String locale;
  final bool suggestReplace;
  final VoidCallback onDeselect;

  const _ConflictNote({
    required this.conflicts,
    required this.locale,
    required this.suggestReplace,
    required this.onDeselect,
  });

  String _days(ApplyConflictKind kind) => kIraqWeekOrder
      .where((dow) => conflicts[dow]?.kind == kind)
      .map((dow) {
        final name = weekdayName(dow, locale);
        final other = conflicts[dow]!.other;
        if (other == null || other.dayOfWeek == dow) return name;
        return LocaleKeys.manage_venue_hours_editor_apply_conflict_with_day.tr(
          namedArgs: {
            'day': name,
            'other': weekdayName(other.dayOfWeek, locale),
          },
        );
      })
      .join(locale.startsWith('ar') ? '، ' : ', ');

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final overlap = _days(ApplyConflictKind.overlap);
    final tooMany = _days(ApplyConflictKind.tooMany);
    return Semantics(
      key: const ValueKey('apply-days-conflict'),
      container: true,
      liveRegion: true,
      child: HoursNote(
        icon: TablerIcons.alert_triangle,
        color: c.warning,
        text: [
          if (overlap.isNotEmpty)
            LocaleKeys.manage_venue_hours_editor_apply_conflict_overlap.tr(
              namedArgs: {'days': overlap},
            ),
          if (tooMany.isNotEmpty)
            LocaleKeys.manage_venue_hours_editor_apply_conflict_too_many.tr(
              namedArgs: {'days': tooMany},
            ),
          (suggestReplace
                  ? LocaleKeys.manage_venue_hours_editor_apply_conflict_hint_add
                  : LocaleKeys.manage_venue_hours_editor_apply_conflict_hint)
              .tr(),
        ].join('\n'),
        action: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: onDeselect,
            style: TextButton.styleFrom(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              LocaleKeys.manage_venue_hours_editor_apply_conflict_deselect.tr(),
              style: TextStyle(
                color: c.primary,
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
