import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

class HoursStatusSection extends StatelessWidget {
  final ManageHoursState state;
  const HoursStatusSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final draft = state.draft!.status;
    final isBranch = state.selectedScope != null;
    final stored = isBranch
        ? state.model?.branch(state.selectedScope!)
        : state.model?.venue;
    final enabled = state.phase == ManageHoursPhase.ready;
    final bloc = context.read<ManageHoursBloc>();
    final selected = draft.own ? draft.status : null;
    final expired =
        (stored?.statusExpired ?? false) &&
        draft == state.initial[state.selectedScope]?.status;
    final locale = hoursLocaleOf(context);

    void choose(String status) {
      if (!enabled || selected == status) return;
      bloc.add(OperatingStatusChanged(status));
    }

    return HoursPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HoursSectionTitle(
            (isBranch
                    ? LocaleKeys.manage_venue_hours_editor_status_section_branch
                    : LocaleKeys.manage_venue_hours_editor_status_section)
                .tr(),
          ),
          const SizedBox(height: 4),
          if (isBranch)
            _Option(
              label: LocaleKeys.manage_venue_hours_editor_status_inherit.tr(),
              selected: !draft.own,
              onTap: enabled && draft.own
                  ? () => bloc.add(const BranchStatusModeChanged(false))
                  : null,
            ),
          _Option(
            label: LocaleKeys.manage_venue_hours_editor_status_open.tr(),
            selected: selected == VenueOperatingStatus.open,
            onTap: () => choose(VenueOperatingStatus.open),
          ),
          _Option(
            label: LocaleKeys.manage_venue_hours_editor_status_temp_closed.tr(),
            selected: selected == VenueOperatingStatus.temporarilyClosed,
            onTap: () => choose(VenueOperatingStatus.temporarilyClosed),
          ),
          if (selected == VenueOperatingStatus.temporarilyClosed)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 30, bottom: 6),
              child: _ReopenDate(
                value: draft.reopensOn,
                today: state.today,
                enabled: enabled,
              ),
            ),
          _Option(
            label: LocaleKeys.manage_venue_hours_editor_status_perm_closed.tr(),
            selected: selected == VenueOperatingStatus.permanentlyClosed,
            onTap: () async {
              if (!enabled ||
                  selected == VenueOperatingStatus.permanentlyClosed) {
                return;
              }
              final ok = await confirmHoursDialog(
                context,
                title: LocaleKeys
                    .manage_venue_hours_editor_perm_close_confirm_title
                    .tr(),
                body: LocaleKeys
                    .manage_venue_hours_editor_perm_close_confirm_body
                    .tr(),
                confirm: LocaleKeys
                    .manage_venue_hours_editor_perm_close_confirm_action
                    .tr(),
                destructive: true,
              );
              if (ok) {
                bloc.add(
                  const OperatingStatusChanged(
                    VenueOperatingStatus.permanentlyClosed,
                  ),
                );
              }
            },
          ),
          if (state.error?.isStatusError ?? false) ...[
            const SizedBox(height: 6),
            HoursNote(
              icon: TablerIcons.alert_triangle,
              color: context.c.danger,
              text: hoursEditorErrorMessage(state.error!, locale),
            ),
          ],
          if (expired && stored?.reopensOn != null) ...[
            const SizedBox(height: 6),
            HoursNote(
              icon: TablerIcons.info_circle,
              color: context.c.warning,
              text: LocaleKeys.manage_venue_hours_editor_status_expired.tr(
                namedArgs: {
                  'date': formatHoursDate(stored!.reopensOn!, locale),
                },
              ),
              action: TextButton(
                onPressed: enabled
                    ? () => bloc.add(
                        const OperatingStatusChanged(VenueOperatingStatus.open),
                      )
                    : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  LocaleKeys.manage_venue_hours_editor_set_open.tr(),
                  style: TextStyle(
                    color: context.c.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _Option({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(
                selected ? TablerIcons.circle_dot_filled : TablerIcons.circle,
                color: selected ? c.primary : c.onSurfaceSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    fontFamily: 'IBMPlexSansArabic',
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

class _ReopenDate extends StatelessWidget {
  final String? value;

  final String? today;
  final bool enabled;

  const _ReopenDate({
    required this.value,
    required this.today,
    required this.enabled,
  });

  Future<void> _pick(BuildContext context) async {
    final base = today == null ? null : parseYmd(today!);
    if (base == null) return;
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final first = day(base.add(const Duration(days: 1)));
    final last = day(base.add(const Duration(days: kMaxReopenDaysAhead)));
    final current = value == null ? null : parseYmd(value!);
    var initial = current == null ? first : day(current);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final bloc = context.read<ManageHoursBloc>();
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      currentDate: day(base),
      initialDate: initial,
      helpText: LocaleKeys.manage_venue_hours_editor_reopen_date.tr(),
    );
    if (picked == null || bloc.isClosed) return;
    bloc.add(
      OperatingStatusChanged(
        VenueOperatingStatus.temporarilyClosed,
        reopensOn: formatYmd(picked),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final locale = hoursLocaleOf(context);
    final has = value != null;
    return Row(
      children: [
        Flexible(
          child: OutlinedButton.icon(
            onPressed: enabled ? () => _pick(context) : null,
            icon: Icon(TablerIcons.calendar_event, size: 16, color: c.primary),
            label: Text(
              has
                  ? LocaleKeys.venue_hours_reopens_on.tr(
                      namedArgs: {'date': formatHoursDate(value!, locale)},
                    )
                  : LocaleKeys.manage_venue_hours_editor_reopen_date.tr(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: has ? c.onSurface : c.onSurfaceSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (has)
          IconButton(
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onPressed: enabled
                ? () => context.read<ManageHoursBloc>().add(
                    const OperatingStatusChanged(
                      VenueOperatingStatus.temporarilyClosed,
                    ),
                  )
                : null,
            icon: Icon(TablerIcons.x, size: 18, color: c.onSurfaceSecondary),
          ),
      ],
    );
  }
}
