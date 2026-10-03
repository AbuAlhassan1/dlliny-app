import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/staff_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/controllers/manage_staff/manage_staff_bloc.dart';

Future<void> showAssignVenueStaffSheet(
  BuildContext context, {
  VenueStaffResponse? existing,
}) {
  final bloc = context.read<ManageStaffBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _AssignVenueStaffSheet(existing: existing),
    ),
  );
}

class _AssignVenueStaffSheet extends StatefulWidget {
  final VenueStaffResponse? existing;
  const _AssignVenueStaffSheet({this.existing});

  @override
  State<_AssignVenueStaffSheet> createState() => _AssignVenueStaffSheetState();
}

class _AssignVenueStaffSheetState extends State<_AssignVenueStaffSheet> {
  final TextEditingController _username = TextEditingController();
  Timer? _debounce;

  UserDto? _resolved;
  String? _lookupError;
  bool _looking = false;

  List<AssignableVenueRole>? _roles;
  String? _rolesError;
  AssignableVenueRole? _pickedRole;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _username.text = '@${widget.existing!.username}';
    }
    _loadRoles();
  }

  @override
  void dispose() {
    _username.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await context.read<ManageStaffBloc>().rolesOnce();
      if (!mounted) return;
      final filtered =
          roles.where((r) => r.name.toLowerCase() != 'owner').toList();
      setState(() {
        _roles = filtered;
        if (_isEdit) {
          _pickedRole = filtered.firstWhere(
            (r) => r.id == widget.existing!.roleId,
            orElse: () => filtered.first,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _rolesError = e.toString());
    }
  }

  void _onUsernameChanged(String raw) {
    _debounce?.cancel();
    if (_isEdit) return;
    final cleaned = raw.trim().replaceFirst(RegExp(r'^@+'), '');
    if (cleaned.isEmpty) {
      setState(() {
        _resolved = null;
        _lookupError = null;
        _looking = false;
      });
      return;
    }
    setState(() {
      _resolved = null;
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
          _resolved = null;
          _lookupError = res.error ?? LocaleKeys.venue_assign_staff_error_user_not_found.tr();
          _looking = false;
        });
        return;
      }
      setState(() {
        _resolved = res.data;
        _lookupError = null;
        _looking = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        _resolved = null;
        _lookupError =
            status == 404
                ? LocaleKeys.venue_assign_staff_error_user_not_found_specific
                    .tr(namedArgs: {'username': username})
                : (e.message ?? LocaleKeys.venue_assign_staff_error_generic.tr());
        _looking = false;
      });
    }
  }

  void _submit() {
    final role = _pickedRole;
    if (role == null) return;
    final userId = _isEdit ? widget.existing!.userId : _resolved?.id;
    if (userId == null) return;
    context.read<ManageStaffBloc>().add(
          AssignStaffSubmitted(userId: userId, roleId: role.id),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final canSubmit = _pickedRole != null && (_isEdit || _resolved != null);
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
                          ? LocaleKeys.venue_assign_staff_title_edit
                          : LocaleKeys.venue_assign_staff_title_new)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                AppLabeledField(
                  label: LocaleKeys.venue_assign_staff_label_username.tr(),
                  requiredMark: !_isEdit,
                  child: TextField(
                    controller: _username,
                    enabled: !_isEdit,
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
                          : (!_isEdit && _resolved != null)
                              ? Icon(
                                  TablerIcons.circle_check_filled,
                                  color: c.success,
                                  size: 18,
                                )
                              : null,
                    ),
                  ),
                ),
                if (_lookupError != null && !_isEdit) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      _lookupError!,
                      style: TextStyle(color: c.danger, fontSize: 11),
                    ),
                  ),
                ],
                if (_resolved != null && !_isEdit) ...[
                  const SizedBox(height: 10),
                  _ResolvedUserCard(user: _resolved!),
                ],
                const SizedBox(height: 16),
                if (_rolesError != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rolesError!,
                      style: TextStyle(color: c.danger, fontSize: 12),
                    ),
                  )
                else if (_roles == null)
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onSurfaceSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  AppLabeledField(
                    label: LocaleKeys.venue_assign_staff_label_role.tr(),
                    requiredMark: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final role in _roles!)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _RoleOption(
                              role: role,
                              selected: _pickedRole?.id == role.id,
                              onTap: () => setState(() => _pickedRole = role),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          LocaleKeys.venue_assign_staff_button_cancel.tr(),
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
                                ? LocaleKeys.venue_assign_staff_button_save
                                : LocaleKeys.venue_assign_staff_button_add)
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

class _RoleOption extends StatelessWidget {
  final AssignableVenueRole role;
  final bool selected;
  final VoidCallback onTap;
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  String get _displayName {
    switch (role.name.toLowerCase()) {
      case 'manager':
        return LocaleKeys.venue_assign_staff_role_manager.tr();
      case 'staff':
        return LocaleKeys.venue_assign_staff_role_staff.tr();
      default:
        return role.name;
    }
  }

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
              selected
                  ? TablerIcons.circle_check_filled
                  : TablerIcons.circle,
              color: selected ? c.onSurface : c.onSurfaceMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (role.description != null &&
                      role.description!.isNotEmpty)
                    Text(
                      role.description!,
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
      ),
    );
  }
}
