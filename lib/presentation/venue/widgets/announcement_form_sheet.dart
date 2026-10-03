import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/request/create_announcement_request.dart';
import 'package:hangout/domain/dto/request/update_announcement_request.dart';
import 'package:hangout/domain/dto/response/announcement_management_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/controllers/manage_announcements/manage_announcements_bloc.dart';

Future<void> showAnnouncementFormSheet(
  BuildContext context, {
  AnnouncementResponse? existing,
}) {
  final bloc = context.read<ManageAnnouncementsBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _AnnouncementFormSheet(existing: existing),
    ),
  );
}

class _AnnouncementFormSheet extends StatefulWidget {
  final AnnouncementResponse? existing;
  const _AnnouncementFormSheet({this.existing});

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  late final TextEditingController _titleAr;
  late final TextEditingController _titleEn;
  late final TextEditingController _bodyAr;
  late final TextEditingController _bodyEn;
  late bool _pinned;

  DateTime? _expiresAt;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleAr = TextEditingController(text: ex?.titleAr ?? '');
    _titleEn = TextEditingController(text: ex?.titleEn ?? '');
    _bodyAr = TextEditingController(text: ex?.bodyAr ?? '');
    _bodyEn = TextEditingController(text: ex?.bodyEn ?? '');
    _pinned = ex?.pinned ?? false;
    _expiresAt = ex?.expiresAt != null ? DateTime.tryParse(ex!.expiresAt!) : null;
  }

  @override
  void dispose() {
    _titleAr.dispose();
    _titleEn.dispose();
    _bodyAr.dispose();
    _bodyEn.dispose();
    super.dispose();
  }

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final initial = _expiresAt ?? now.add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _expiresAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final titleAr = _titleAr.text.trim();
    final bodyAr = _bodyAr.text.trim();
    if (titleAr.isEmpty || bodyAr.isEmpty) return;
    final titleEn = _titleEn.text.trim();
    final bodyEn = _bodyEn.text.trim();
    final expiresIso = _expiresAt?.toUtc().toIso8601String();
    final bloc = context.read<ManageAnnouncementsBloc>();
    if (_isEdit) {
      bloc.add(UpdateAnnouncementSubmitted(
        announcementId: widget.existing!.id,
        body: UpdateAnnouncementRequest(
          titleAr: titleAr,
          titleEn: titleEn.isEmpty ? null : titleEn,
          bodyAr: bodyAr,
          bodyEn: bodyEn.isEmpty ? null : bodyEn,
          pinned: _pinned != widget.existing!.pinned ? _pinned : null,
          expiresAt: expiresIso,
        ),
      ));
    } else {
      bloc.add(CreateAnnouncementSubmitted(
        CreateAnnouncementRequest(
          titleAr: titleAr,
          titleEn: titleEn.isEmpty ? null : titleEn,
          bodyAr: bodyAr,
          bodyEn: bodyEn.isEmpty ? null : bodyEn,
          pinned: _pinned,
          expiresAt: expiresIso,
        ),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canSubmit = _titleAr.text.trim().isNotEmpty &&
        _bodyAr.text.trim().isNotEmpty;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (_isEdit
                              ? LocaleKeys.venue_announcement_form_title_edit
                              : LocaleKeys.venue_announcement_form_title_new)
                          .tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _titleAr,
                        label: LocaleKeys.venue_announcement_form_label_title_ar.tr(),
                        requiredMark: true,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _titleEn,
                        label: LocaleKeys.venue_announcement_form_label_title_en.tr(),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _bodyAr,
                        label: LocaleKeys.venue_announcement_form_label_body_ar.tr(),
                        requiredMark: true,
                        maxLines: 5,
                        minLines: 3,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _bodyEn,
                        label: LocaleKeys.venue_announcement_form_label_body_en.tr(),
                        maxLines: 5,
                        minLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _PinnedToggle(
                        pinned: _pinned,
                        onChanged: (v) => setState(() => _pinned = v),
                      ),
                      const SizedBox(height: 12),
                      _ExpiresAtField(
                        expiresAt: _expiresAt,
                        onPick: _pickExpiresAt,
                        onClear: () => setState(() => _expiresAt = null),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          LocaleKeys.venue_announcement_form_button_cancel.tr(),
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.onSurface,
                          foregroundColor: c.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text((_isEdit
                                ? LocaleKeys.venue_announcement_form_button_save
                                : LocaleKeys.venue_announcement_form_button_publish)
                            .tr()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedToggle extends StatelessWidget {
  final bool pinned;
  final ValueChanged<bool> onChanged;
  const _PinnedToggle({required this.pinned, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.pin, color: c.onSurfaceSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.venue_announcement_form_pin_top_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  LocaleKeys.venue_announcement_form_pin_top_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: pinned,
            onChanged: onChanged,
            activeThumbColor: c.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ExpiresAtField extends StatelessWidget {
  final DateTime? expiresAt;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _ExpiresAtField({
    required this.expiresAt,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final has = expiresAt != null;
    return AppLabeledField(
      label: LocaleKeys.venue_announcement_form_label_expires_optional.tr(),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.calendar, color: c.onSurfaceSecondary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  has ? _format(expiresAt!) : LocaleKeys.venue_announcement_form_no_expiry.tr(),
                  style: TextStyle(
                    color: has ? c.onSurface : c.onSurfaceMuted,
                    fontSize: 13,
                    fontWeight: has ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (has)
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(100),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      TablerIcons.x,
                      color: c.onSurfaceSecondary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }
}
