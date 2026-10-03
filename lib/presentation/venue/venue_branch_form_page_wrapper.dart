import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/request/create_venue_location_request.dart';
import 'package:hangout/domain/dto/request/update_venue_location_request.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_branches/venue_branches_bloc.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_city_and_district_field.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_textfield.dart';
import 'package:hangout/presentation/venues/widgets/map_location_picker.dart';

class VenueBranchFormPageWrapper extends StatefulWidget {
  final VenueLocationResponse? branch;
  const VenueBranchFormPageWrapper({super.key, this.branch});
  bool get isEditing => branch != null;

  static Future<void> pushCreate(
    BuildContext context, {
    required VenueBranchesBloc bloc,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const VenueBranchFormPageWrapper(),
        ),
      ),
    );
  }

  static Future<void> pushEdit(
    BuildContext context, {
    required VenueBranchesBloc bloc,
    required VenueLocationResponse branch,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: VenueBranchFormPageWrapper(branch: branch),
        ),
      ),
    );
  }

  @override
  State<VenueBranchFormPageWrapper> createState() =>
      _VenueBranchFormPageWrapperState();
}

class _VenueBranchFormPageWrapperState
    extends State<VenueBranchFormPageWrapper> {
  late final TextEditingController _labelArController;
  late final TextEditingController _labelEnController;
  late final TextEditingController _addressArController;
  late final TextEditingController _addressEnController;
  late final TextEditingController _cityIdController;
  late final TextEditingController _districtIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late bool _isPrimary;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _labelArController = TextEditingController(text: b?.labelAr ?? '');
    _labelEnController = TextEditingController(text: b?.labelEn ?? '');
    _addressArController = TextEditingController(text: b?.addressAr ?? '');
    _addressEnController = TextEditingController(text: b?.addressEn ?? '');
    _cityIdController = TextEditingController(
      text: b?.cityId?.toString() ?? '',
    );
    _districtIdController = TextEditingController(
      text: b?.districtId?.toString() ?? '',
    );
    _phoneController = TextEditingController(text: b?.phone ?? '');
    _latitudeController = TextEditingController(
      text: b == null ? '' : b.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: b == null ? '' : b.longitude.toString(),
    );
    _isPrimary = b?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _labelArController.dispose();
    _labelEnController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _cityIdController.dispose();
    _districtIdController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  int? _parseInt(String s) => s.isEmpty ? null : int.tryParse(s);
  double? _parseDouble(String s) => s.isEmpty ? null : double.tryParse(s);

  String? _nullableText(TextEditingController c) =>
      c.text.isEmpty ? null : c.text;

  bool _validateForCreate() {
    final lat = _parseDouble(_latitudeController.text);
    final lng = _parseDouble(_longitudeController.text);
    if (lat == null || lng == null) {
      appToast.error(LocaleKeys.manage_venue_branch_form_error_location_required.tr());
      return false;
    }
    return true;
  }

  void _submit() {
    final bloc = context.read<VenueBranchesBloc>();
    if (widget.isEditing) {
      final request = UpdateVenueLocationRequest(
        labelAr: _nullableText(_labelArController),
        labelEn: _nullableText(_labelEnController),
        addressAr: _nullableText(_addressArController),
        addressEn: _nullableText(_addressEnController),
        cityId: _parseInt(_cityIdController.text),
        districtId: _parseInt(_districtIdController.text),
        phone: _nullableText(_phoneController),
        latitude: _parseDouble(_latitudeController.text),
        longitude: _parseDouble(_longitudeController.text),
        isPrimary: (_isPrimary && widget.branch?.isPrimary != true)
            ? true
            : null,
      );
      bloc.add(
        UpdateVenueBranch(locationId: widget.branch!.id, request: request),
      );
    } else {
      if (!_validateForCreate()) return;
      final request = CreateVenueLocationRequest(
        labelAr: _nullableText(_labelArController),
        labelEn: _nullableText(_labelEnController),
        addressAr: _nullableText(_addressArController),
        addressEn: _nullableText(_addressEnController),
        cityId: _parseInt(_cityIdController.text),
        districtId: _parseInt(_districtIdController.text),
        phone: _nullableText(_phoneController),
        latitude: _parseDouble(_latitudeController.text)!,
        longitude: _parseDouble(_longitudeController.text)!,
        isPrimary: _isPrimary ? true : null,
      );
      bloc.add(CreateVenueBranch(request));
    }
  }

  Future<void> _confirmAndDelete() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.surfaceElevated,
          title: Text(
            LocaleKeys.manage_venue_branch_form_dialog_delete_title.tr(),
            style: TextStyle(color: cc.onSurface),
          ),
          content: Text(
            LocaleKeys.manage_venue_branch_form_dialog_delete_body.tr(),
            style: TextStyle(color: cc.onSurfaceSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                LocaleKeys.manage_venue_branch_form_button_cancel.tr(),
                style: TextStyle(color: cc.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                LocaleKeys.manage_venue_branch_form_button_delete.tr(),
                style: TextStyle(color: cc.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    context.read<VenueBranchesBloc>().add(DeleteVenueBranch(widget.branch!.id));
    c.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isCurrentPrimary = widget.branch?.isPrimary == true;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          (widget.isEditing
                  ? LocaleKeys.manage_venue_branch_form_page_title_edit
                  : LocaleKeys.manage_venue_branch_form_page_title_add)
              .tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (widget.isEditing && !isCurrentPrimary)
            IconButton(
              tooltip: LocaleKeys.manage_venue_branch_form_tooltip_delete.tr(),
              onPressed: _confirmAndDelete,
              icon: Icon(TablerIcons.trash, color: c.danger),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<VenueBranchesBloc, VenueBranchesState>(
          listenWhen: (_, s) =>
              s is VenueBranchOperated || s is VenueBranchOperationError,
          listener: (context, state) {
            if (state is VenueBranchOperated) {
              Navigator.of(context).pop();
            } else if (state is VenueBranchOperationError) {
              appToast.error(state.message);
            }
          },
          builder: (context, state) {
            final saving = state is VenueBranchOperating;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(text: LocaleKeys.manage_venue_branch_form_section_name.tr()),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: _labelArController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_branch_form_label_name_ar.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: _labelEnController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_branch_form_label_name_en.tr(),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(text: LocaleKeys.manage_venue_branch_form_section_location.tr()),
                        const SizedBox(height: 16),
                        AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: MapLocationPicker(
                                latitudeController: _latitudeController,
                                longitudeController: _longitudeController,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: _addressArController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_branch_form_label_address_ar.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: _addressEnController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_branch_form_label_address_en.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueCityAndDistrictField(
                          cityController: _cityIdController,
                          districtController: _districtIdController,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(text: LocaleKeys.manage_venue_branch_form_section_contact_info.tr()),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: _phoneController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_branch_form_label_phone.tr(),
                        ),
                        const SizedBox(height: 24),
                        _PrimaryToggle(
                          isPrimary: _isPrimary,
                          enabled: !isCurrentPrimary,
                          onChanged: (v) => setState(() => _isPrimary = v),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        child: saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.onPrimary,
                                ),
                              )
                            : Text(
                                (widget.isEditing
                                        ? LocaleKeys.manage_venue_branch_form_button_save_changes
                                        : LocaleKeys.manage_venue_branch_form_button_add_branch)
                                    .tr(),
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexSansArabic',
                                )
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrimaryToggle extends StatelessWidget {
  final bool isPrimary;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PrimaryToggle({
    required this.isPrimary,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (enabled
                          ? LocaleKeys.manage_venue_branch_form_make_primary_enabled
                          : LocaleKeys.manage_venue_branch_form_make_primary_disabled)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (enabled
                          ? LocaleKeys.manage_venue_branch_form_make_primary_subtitle_enabled
                          : LocaleKeys.manage_venue_branch_form_make_primary_subtitle_disabled)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: isPrimary,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: c.primary,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(child: Divider(color: c.divider)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.divider)),
      ],
    );
  }
}
