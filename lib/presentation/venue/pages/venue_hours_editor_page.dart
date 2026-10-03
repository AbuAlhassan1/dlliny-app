import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_scope_chips.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_status_section.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_week_section.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

class VenueHoursEditorPage extends StatelessWidget {
  final String venueId;

  const VenueHoursEditorPage({super.key, required this.venueId});

  static Future<bool?> push(BuildContext context, String venueId) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VenueHoursEditorPage(venueId: venueId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageHoursBloc>(
      create: (_) =>
          ManageHoursBloc(venueId: venueId)
            ..add(const ManageHoursLoadRequested()),
      child: const ScaffoldMessenger(child: _EditorView()),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  bool _leaving = false;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _appliedBar;

  void _showApplied(BuildContext context, int days) {
    final c = context.c;
    final bloc = context.read<ManageHoursBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final persist = MediaQuery.accessibleNavigationOf(context);
    if (_appliedBar != null) messenger.removeCurrentSnackBar();
    final bar = messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('hours-applied-snackbar'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceAccent,
        duration: const Duration(seconds: 6),
        persist: persist,
        showCloseIcon: persist,
        closeIconColor: c.onSurfaceAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          LocaleKeys.manage_venue_hours_editor_applied_days.plural(days),
          style: TextStyle(
            color: c.onSurfaceAccent,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        action: SnackBarAction(
          label: LocaleKeys.manage_venue_hours_editor_undo.tr(),
          textColor: c.onSurfaceAccent,
          onPressed: () {
            if (!bloc.isClosed) bloc.add(const HoursRangeUndone());
          },
        ),
      ),
    );
    _appliedBar = bar;
    bar.closed.then((_) {
      if (identical(_appliedBar, bar)) _appliedBar = null;
    });
  }

  void _hideApplied(BuildContext context) {
    if (_appliedBar == null) return;
    _appliedBar = null;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _onEffect(BuildContext context, ManageHoursState state) async {
    final bloc = context.read<ManageHoursBloc>();
    switch (state.effect) {
      case HoursAppliedToDays(:final days):
        _showApplied(context, days);
      case HoursConfirmNeeded(:final reason):
        final ok = await confirmHoursDialog(
          context,
          title: switch (reason) {
            HoursConfirmReason.allClosed =>
              LocaleKeys.manage_venue_hours_editor_all_closed_confirm_title
                  .tr(),
            HoursConfirmReason.branchNoRamadan =>
              LocaleKeys.manage_venue_hours_editor_branch_no_ramadan_title.tr(),
          },
          body: switch (reason) {
            HoursConfirmReason.allClosed =>
              LocaleKeys.manage_venue_hours_editor_all_closed_confirm_body.tr(),
            HoursConfirmReason.branchNoRamadan =>
              LocaleKeys.manage_venue_hours_editor_branch_no_ramadan_body.tr(),
          },
          confirm: LocaleKeys.common_save.tr(),
        );
        if (ok && !bloc.isClosed) bloc.add(HoursSaveConfirmed(reason));
      case HoursSaveFailed(:final error):
        appToast.error(hoursEditorErrorMessage(error, hoursLocaleOf(context)));
      case HoursSaved():
        appToast.success(LocaleKeys.manage_venue_hours_editor_saved.tr());
        _leaving = true;
        Navigator.of(context).pop(true);
      case HoursCleared():
        appToast.success(LocaleKeys.manage_venue_hours_editor_cleared.tr());
      case null:
        break;
    }
  }

  Future<void> _onPopBlocked(
    BuildContext context,
    ManageHoursState state,
  ) async {
    if (state.isDirty) {
      final ok = await confirmHoursDialog(
        context,
        title: LocaleKeys.manage_venue_hours_editor_discard_title.tr(),
        body: LocaleKeys.manage_venue_hours_editor_discard_body.tr(),
        confirm: LocaleKeys.manage_venue_hours_editor_discard_confirm.tr(),
        destructive: true,
      );
      if (!ok || !context.mounted) return;
    }
    setState(() => _leaving = true);
    Navigator.of(context).pop(state.changedOnServer ? true : null);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final bloc = context.read<ManageHoursBloc>();
    final ok = await confirmHoursDialog(
      context,
      title: LocaleKeys.manage_venue_hours_editor_clear_hours.tr(),
      body: LocaleKeys.manage_venue_hours_editor_clear_hours_confirm_body.tr(),
      confirm: LocaleKeys.manage_venue_hours_editor_clear_hours.tr(),
      destructive: true,
    );
    if (ok && !bloc.isClosed) bloc.add(const HoursClearRequested());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<ManageHoursBloc, ManageHoursState>(
      listenWhen: (prev, next) =>
          (next.effect != null && !identical(prev.effect, next.effect)) ||
          (prev.canUndoApply && !next.canUndoApply),
      listener: (context, state) {
        if (!state.canUndoApply) _hideApplied(context);
        _onEffect(context, state);
      },
      builder: (context, state) {
        final canClear =
            state.phase == ManageHoursPhase.ready &&
            state.selectedScope == null &&
            state.model?.venue.regular != null;
        return PopScope<Object?>(
          canPop: _leaving || (!state.isDirty && !state.changedOnServer),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onPopBlocked(context, state);
          },
          child: Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
              backgroundColor: c.background,
              foregroundColor: c.onSurface,
              elevation: 0,
              title: Text(
                LocaleKeys.manage_venue_hours_editor_title.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              actions: [
                if (canClear)
                  PopupMenuButton<String>(
                    icon: const Icon(TablerIcons.dots_vertical),
                    onSelected: (_) => _confirmClear(context),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(TablerIcons.trash, size: 16, color: c.danger),
                            const SizedBox(width: 8),
                            Text(
                              LocaleKeys.manage_venue_hours_editor_clear_hours
                                  .tr(),
                              style: TextStyle(
                                color: c.danger,
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
            body: switch (state.phase) {
              ManageHoursPhase.loading => Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
              ManageHoursPhase.loadFailed => _LoadFailed(state: state),
              _ => _EditorBody(state: state),
            },
            bottomNavigationBar:
                state.phase == ManageHoursPhase.ready ||
                    state.phase == ManageHoursPhase.saving
                ? _SaveBar(state: state)
                : null,
          ),
        );
      },
    );
  }
}

class _EditorBody extends StatelessWidget {
  final ManageHoursState state;
  const _EditorBody({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.draft == null) return const SizedBox.shrink();
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        if (state.showsScopeChips) ...[
          HoursScopeChips(state: state),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HoursStatusSection(state: state),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HoursWeekSection(state: state),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  final ManageHoursState state;
  const _SaveBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final saving = state.phase == ManageHoursPhase.saving;
    return Container(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.showsIncompleteHint) ...[
                Text(
                  hoursEditorErrorText(VenueErrorCodes.hoursIntervalIncomplete),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: state.canSave
                      ? () => context.read<ManageHoursBloc>().add(
                          const HoursSaveRequested(),
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
                  child: saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: c.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          LocaleKeys.common_save.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'IBMPlexSansArabic',
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

class _LoadFailed extends StatelessWidget {
  final ManageHoursState state;
  const _LoadFailed({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.alert_circle, color: c.onSurfaceSecondary),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.common_error_generic.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.read<ManageHoursBloc>().add(
                const ManageHoursLoadRequested(),
              ),
              child: Text(
                LocaleKeys.common_retry.tr(),
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
