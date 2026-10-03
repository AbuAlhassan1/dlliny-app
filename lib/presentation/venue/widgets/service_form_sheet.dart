import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_content_response.dart';
import 'package:hangout/domain/dto/response/venue_service_management_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/image_picker.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/controllers/manage_services/manage_services_bloc.dart';

Future<void> showServiceFormSheet(
  BuildContext context, {
  VenueServiceResponse? existing,
}) {
  final bloc = context.read<ManageServicesBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _ServiceFormSheet(existing: existing),
    ),
  );
}

class _ServiceFormSheet extends StatefulWidget {
  final VenueServiceResponse? existing;
  const _ServiceFormSheet({this.existing});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  late final TextEditingController _priceController;
  VenueServiceTypeDto? _pickedType;
  File? _pickedImage;
  bool _clearImage = false;
  bool _active = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _priceController = TextEditingController(
      text: ex?.price?.toStringAsFixed(0) ?? '',
    );
    _active = ex?.active ?? true;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickType() async {
    final bloc = context.read<ManageServicesBloc>();
    final picked = await showModalBottomSheet<VenueServiceTypeDto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceTypePickerSheet(loader: bloc.loadServiceTypesOnce),
    );
    if (picked != null) {
      setState(() => _pickedType = picked);
    }
  }

  Future<void> _pickImage() async {
    final file = await pickImage();
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _clearImage = false;
      });
    }
  }

  double? _priceFromText() {
    final t = _priceController.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  void _submit() {
    final bloc = context.read<ManageServicesBloc>();
    final ex = widget.existing;
    if (ex == null) {
      if (_pickedType == null) return;
      bloc.add(AddServiceSubmitted(
        serviceTypeId: _pickedType!.id,
        price: _priceFromText(),
        image: _pickedImage,
      ));
    } else {
      bloc.add(UpdateServiceSubmitted(
        serviceId: ex.id,
        price: _priceFromText(),
        active: _active != ex.active ? _active : null,
        image: _pickedImage,
        keepExistingImage: _pickedImage == null && !_clearImage,
        clearImage: _clearImage && _pickedImage == null,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ex = widget.existing;
    final canSubmit = _isEdit || _pickedType != null;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 16),
                Text(
                  (_isEdit
                          ? LocaleKeys.venue_service_form_title_edit
                          : LocaleKeys.venue_service_form_title_new)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _typeTile(c, ex),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _priceController,
                  label: LocaleKeys.venue_service_form_label_price.tr(),
                  hint: LocaleKeys.venue_service_form_hint_price_optional.tr(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                ),
                const SizedBox(height: 14),
                _imagePicker(c, ex),
                if (_isEdit) ...[
                  const SizedBox(height: 14),
                  _activeSwitch(c),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          LocaleKeys.venue_service_form_button_cancel.tr(),
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
                                ? LocaleKeys.venue_service_form_button_save
                                : LocaleKeys.venue_service_form_button_add)
                            .tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTile(AppColors c, VenueServiceResponse? ex) {
    final nameAr = ex?.serviceTypeNameAr ?? _pickedType?.nameAr;
    final nameEn = ex?.serviceTypeNameEn ?? _pickedType?.nameEn;
    final placeholder = nameAr == null;
    return AppLabeledField(
      label: LocaleKeys.venue_service_form_label_service_type.tr(),
      requiredMark: !_isEdit,
      child: InkWell(
        onTap: _isEdit ? null : _pickType,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: placeholder
                    ? Text(
                        LocaleKeys.venue_service_form_hint_select_type.tr(),
                        style: TextStyle(color: c.onSurfaceMuted),
                      )
                    : Row(
                        children: [
                          Flexible(
                            child: Text(
                              nameAr,
                              style: TextStyle(
                                color: c.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (nameEn != null && nameEn.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                nameEn,
                                style: TextStyle(
                                  color: c.onSurfaceSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              if (!_isEdit)
                Icon(
                  TablerIcons.chevron_down,
                  color: c.onSurfaceSecondary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker(AppColors c, VenueServiceResponse? ex) {
    final existingUrl = ex?.imageUrl;
    final hasNewPick = _pickedImage != null;
    final hasExisting = !_clearImage && existingUrl != null && existingUrl.isNotEmpty;
    return AppLabeledField(
      label: LocaleKeys.venue_service_form_label_image_optional.tr(),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: hasNewPick
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : hasExisting
                    ? CachedNetworkImage(
                        imageUrl: existingUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          TablerIcons.photo_off,
                          color: c.onSurfaceDisabled,
                          size: 20,
                        ),
                      )
                    : Icon(
                        TablerIcons.photo,
                        color: c.onSurfaceDisabled,
                        size: 22,
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(TablerIcons.upload, color: c.onSurface, size: 14),
                  label: Text(
                    (hasNewPick || hasExisting
                            ? LocaleKeys.venue_service_form_button_change
                            : LocaleKeys.venue_service_form_button_pick)
                        .tr(),
                    style: TextStyle(color: c.onSurface, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (hasNewPick || hasExisting)
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _clearImage = true;
                    }),
                    icon: Icon(TablerIcons.x, color: c.danger, size: 14),
                    label: Text(
                      LocaleKeys.venue_service_form_button_remove.tr(),
                      style: TextStyle(color: c.danger, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeSwitch(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.venue_service_form_active_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  LocaleKeys.venue_service_form_active_subtitle.tr(),
                  style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            activeThumbColor: c.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ServiceTypePickerSheet extends StatefulWidget {
  final Future<List<VenueServiceTypeDto>> Function() loader;
  const _ServiceTypePickerSheet({required this.loader});

  @override
  State<_ServiceTypePickerSheet> createState() =>
      _ServiceTypePickerSheetState();
}

class _ServiceTypePickerSheetState extends State<_ServiceTypePickerSheet> {
  late Future<List<VenueServiceTypeDto>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.venue_service_form_validation_select_type.tr(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: FutureBuilder<List<VenueServiceTypeDto>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: c.onSurface,
                        strokeWidth: 1.5,
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          LocaleKeys.venue_service_form_error_load_types.tr(),
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      ),
                    );
                  }
                  final grouped = <String, List<VenueServiceTypeDto>>{};
                  for (final t in snapshot.data!) {
                    (grouped[t.category] ??= []).add(t);
                  }
                  for (final list in grouped.values) {
                    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                  }
                  final keys = grouped.keys.toList();
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: keys.length,
                    itemBuilder: (context, idx) {
                      final cat = keys[idx];
                      final items = grouped[cat]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              _categoryLabel(cat),
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...items.map(
                            (t) => InkWell(
                              onTap: () => Navigator.of(context).pop(t),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              t.nameAr,
                                              style: TextStyle(
                                                color: c.onSurface,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              t.nameEn,
                                              style: TextStyle(
                                                color: c.onSurfaceSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      TablerIcons.chevron_left,
                                      color: c.onSurfaceMuted,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(String code) {
  switch (code) {
    case 'FOOD_AND_DRINKS':
      return LocaleKeys.venue_service_form_category_food_drink.tr();
    case 'ATMOSPHERE':
      return LocaleKeys.venue_service_form_category_atmosphere.tr();
    case 'FACILITIES':
      return LocaleKeys.venue_service_form_category_facilities.tr();
    case 'ENTERTAINMENT':
      return LocaleKeys.venue_service_form_category_entertainment.tr();
    case 'WELLNESS':
      return LocaleKeys.venue_service_form_category_wellness.tr();
    case 'EVENTS':
      return LocaleKeys.venue_service_form_category_events.tr();
    default:
      return code;
  }
}
