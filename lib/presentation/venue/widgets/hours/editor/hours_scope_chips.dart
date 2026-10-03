import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

class HoursScopeChips extends StatelessWidget {
  final ManageHoursState state;
  const HoursScopeChips({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final locale = hoursLocaleOf(context);
    final bloc = context.read<ManageHoursBloc>();
    bool overrides(String id) {
      final d = state.drafts[id];
      return d != null && (d.hours.own || d.status.own);
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ScopeChip(
            label: LocaleKeys.manage_venue_hours_editor_scope_all_branches.tr(),
            selected: state.selectedScope == null,
            unsaved: state.scopeDirty(null),
            onTap: () => bloc.add(const HoursScopeSelected(null)),
          ),
          for (final b in state.branches)
            if (b.locationId != null) ...[
              const SizedBox(width: 8),
              _ScopeChip(
                label: branchScopeLabel(b, locale),
                selected: state.selectedScope == b.locationId,
                overrides: overrides(b.locationId!),
                unsaved: state.scopeDirty(b.locationId),
                onTap: () => bloc.add(HoursScopeSelected(b.locationId)),
              ),
            ],
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool overrides;

  final bool unsaved;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.overrides = false,
    this.unsaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: selected ? c.primary : c.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? c.primary : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overrides) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: selected ? c.onPrimary : c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? c.onPrimary : c.onSurface,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              if (unsaved) ...[
                const SizedBox(width: 6),
                Semantics(
                  label: LocaleKeys.manage_venue_hours_editor_unsaved_changes
                      .tr(),
                  child: Container(
                    key: const ValueKey('hours-scope-unsaved'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.warning,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c.onPrimary : c.surface,
                        width: 1,
                      ),
                    ),
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
