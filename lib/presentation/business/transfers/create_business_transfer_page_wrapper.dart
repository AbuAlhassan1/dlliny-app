import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_business_transfer_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/business/transfers/utils/transfer_enums.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class CreateBusinessTransferPageWrapper extends StatefulWidget {
  final TransferType type;

  final String? venueId;
  final String? venueLabel;

  const CreateBusinessTransferPageWrapper({
    super.key,
    required this.type,
    this.venueId,
    this.venueLabel,
  });

  static Future<void> pushForBusiness(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const CreateBusinessTransferPageWrapper(type: TransferType.business),
      ),
    );
  }

  static Future<void> pushForVenue(
    BuildContext context, {
    required String venueId,
    required String venueLabel,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateBusinessTransferPageWrapper(
          type: TransferType.venue,
          venueId: venueId,
          venueLabel: venueLabel,
        ),
      ),
    );
  }

  @override
  State<CreateBusinessTransferPageWrapper> createState() =>
      _CreateBusinessTransferPageWrapperState();
}

class _CreateBusinessTransferPageWrapperState
    extends State<CreateBusinessTransferPageWrapper> {
  final _username = TextEditingController();
  final _message = TextEditingController();
  Timer? _debounce;
  UserDto? _resolvedTarget;
  String? _lookupError;
  bool _looking = false;

  BusinessAccess? _pickedBusiness;

  bool _submitting = false;

  bool get _isVenue => widget.type == TransferType.venue;

  String? get _sourceBusinessId =>
      _isVenue ? _resolveVenueBusinessId() : _pickedBusiness?.businessId;

  @override
  void dispose() {
    _username.dispose();
    _message.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String? _resolveVenueBusinessId() {
    final access = context.read<AccessBloc>().myAccess?.data;
    if (access == null) return null;
    for (final b in access.businesses) {
      for (final v in b.venues) {
        if (v.venueId == widget.venueId) return b.businessId;
      }
    }
    return null;
  }

  List<BusinessAccess> _myOwnedBusinesses() {
    final access = context.read<AccessBloc>().myAccess?.data;
    if (access == null) return const [];
    return access.businesses
        .where((b) => b.businessRoleName == 'business_owner' && b.active)
        .toList();
  }

  void _onUsernameChanged(String raw) {
    _debounce?.cancel();
    final cleaned = raw.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) {
      setState(() {
        _resolvedTarget = null;
        _lookupError = null;
        _looking = false;
      });
      return;
    }
    setState(() {
      _resolvedTarget = null;
      _lookupError = null;
      _looking = true;
    });
    _debounce = Timer(const Duration(milliseconds: 450), () => _lookup(cleaned));
  }

  Future<void> _lookup(String username) async {
    final api = serviceLocator.get<ApiService>();
    try {
      final res = await api.getUserProfile(username);
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() {
          _resolvedTarget = null;
          _lookupError = res.error ??
              LocaleKeys.business_transfers_create_lookup_user_not_found.tr();
          _looking = false;
        });
        return;
      }
      setState(() {
        _resolvedTarget = res.data;
        _lookupError = null;
        _looking = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        _resolvedTarget = null;
        _lookupError =
            status == 404
                ? LocaleKeys.business_transfers_create_user_not_found_specific
                      .tr(namedArgs: {'username': username})
                : (e.message ?? LocaleKeys.common_error_generic.tr());
        _looking = false;
      });
    }
  }

  Future<bool> _confirm() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          (_isVenue
                  ? LocaleKeys.business_transfers_create_confirm_title_venue
                  : LocaleKeys.business_transfers_create_confirm_title_business)
              .tr(),
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          _isVenue
              ? LocaleKeys.business_transfers_create_confirm_body_venue.tr(
                  namedArgs: {'username': _resolvedTarget!.username ?? ''},
                )
              : LocaleKeys.business_transfers_create_confirm_body_business.tr(
                  namedArgs: {'username': _resolvedTarget!.username ?? ''},
                ),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocaleKeys.common_back.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.business_transfers_create_submit.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final target = _resolvedTarget;
    final businessId = _sourceBusinessId;
    if (target == null || businessId == null) return;
    if (!await _confirm() || !mounted) return;
    setState(() => _submitting = true);
    final api = serviceLocator.get<ApiService>();
    final note = _message.text.trim();
    try {
      final res = await api.createBusinessTransfer(
        CreateBusinessTransferRequest(
          transferType: widget.type.wire,
          targetUserId: target.id,
          businessId: businessId,
          venueId: _isVenue ? widget.venueId : null,
          message: note.isEmpty ? null : note,
        ),
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        appToast.error(
          res.error ??
              LocaleKeys.business_transfers_create_submit_failed_fallback.tr(),
        );
        setState(() => _submitting = false);
        return;
      }
      appToast.success(
        LocaleKeys.business_transfers_create_submit_success_toast.tr(),
      );
      Navigator.of(context).pop(res.data);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ??
              LocaleKeys.business_transfers_create_submit_failed_fallback.tr());
      appToast.error(msg);
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final myBusinesses = _isVenue ? const <BusinessAccess>[] : _myOwnedBusinesses();
    final canSubmit = _resolvedTarget != null &&
        _sourceBusinessId != null &&
        !_submitting;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          (_isVenue
                  ? LocaleKeys.business_transfers_create_page_title_venue
                  : LocaleKeys.business_transfers_create_page_title_business)
              .tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _DangerBanner(isVenue: _isVenue),
          const SizedBox(height: 16),
          _AssetSection(
            isVenue: _isVenue,
            venueLabel: widget.venueLabel,
            myBusinesses: myBusinesses,
            pickedBusiness: _pickedBusiness,
            sourceBusinessId: _sourceBusinessId,
            onPickBusiness: (b) => setState(() => _pickedBusiness = b),
          ),
          const SizedBox(height: 14),
          AppLabeledField(
            label: LocaleKeys.business_transfers_create_recipient_label.tr(),
            requiredMark: true,
            child: TextField(
              controller: _username,
              onChanged: _onUsernameChanged,
              style: TextStyle(color: c.onSurface),
              decoration: appInputDecoration(
                c,
                hint: '@username',
                suffixIcon: _looking
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: c.onSurfaceSecondary,
                          ),
                        ),
                      )
                    : (_resolvedTarget != null)
                        ? Icon(
                            TablerIcons.circle_check_filled,
                            color: c.success,
                            size: 18,
                          )
                        : null,
              ),
            ),
          ),
          if (_lookupError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Text(
                _lookupError!,
                style: TextStyle(color: c.danger, fontSize: 11),
              ),
            ),
          ],
          if (_resolvedTarget != null) ...[
            const SizedBox(height: 10),
            _ResolvedUserCard(user: _resolvedTarget!),
          ],
          const SizedBox(height: 14),
          AppTextField(
            controller: _message,
            label: LocaleKeys.business_transfers_create_message_label.tr(),
            hint: LocaleKeys.business_transfers_create_message_hint.tr(),
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
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
              child: _submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: c.surface,
                        strokeWidth: 1.5,
                      ),
                    )
                  : Text(LocaleKeys.business_transfers_create_submit.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerBanner extends StatelessWidget {
  final bool isVenue;
  const _DangerBanner({required this.isVenue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.alert_triangle, color: c.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isVenue
                  ? LocaleKeys.business_transfers_create_warning_venue.tr()
                  : LocaleKeys.business_transfers_create_warning_business.tr(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSection extends StatelessWidget {
  final bool isVenue;
  final String? venueLabel;
  final List<BusinessAccess> myBusinesses;
  final BusinessAccess? pickedBusiness;
  final String? sourceBusinessId;
  final ValueChanged<BusinessAccess> onPickBusiness;
  const _AssetSection({
    required this.isVenue,
    required this.venueLabel,
    required this.myBusinesses,
    required this.pickedBusiness,
    required this.sourceBusinessId,
    required this.onPickBusiness,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (isVenue) {
      return AppLabeledField(
        label: LocaleKeys.business_transfers_create_venue_to_transfer_label.tr(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.building_store, color: c.onSurface, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  venueLabel ??
                      LocaleKeys.business_transfers_create_venue_fallback_label.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (sourceBusinessId == null)
                Icon(
                  TablerIcons.alert_circle,
                  color: c.danger,
                  size: 18,
                ),
            ],
          ),
        ),
      );
    }
    if (myBusinesses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          LocaleKeys.business_transfers_create_no_business_to_transfer.tr(),
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
        ),
      );
    }
    return AppLabeledField(
      label: LocaleKeys.business_transfers_create_business_to_transfer_label.tr(),
      requiredMark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in myBusinesses)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _BusinessOption(
                business: b,
                selected: pickedBusiness?.businessId == b.businessId,
                onTap: () => onPickBusiness(b),
              ),
            ),
        ],
      ),
    );
  }
}

class _BusinessOption extends StatelessWidget {
  final BusinessAccess business;
  final bool selected;
  final VoidCallback onTap;
  const _BusinessOption({
    required this.business,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.onSurface.withValues(alpha: 0.06) : c.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.onSurface : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? TablerIcons.circle_check_filled : TablerIcons.circle,
              color: selected ? c.onSurface : c.onSurfaceMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                business.companyName ??
                    LocaleKeys.business_transfers_any_business_fallback.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (business.verified)
              Icon(
                TablerIcons.rosette_discount_check_filled,
                color: c.success,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedUserCard extends StatelessWidget {
  final UserDto user;
  const _ResolvedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
            ),
            child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      TablerIcons.user,
                      color: c.onSurfaceSecondary,
                      size: 18,
                    ),
                  )
                : Icon(
                    TablerIcons.user,
                    color: c.onSurfaceSecondary,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.username ?? '',
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${user.username ?? ''}',
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
