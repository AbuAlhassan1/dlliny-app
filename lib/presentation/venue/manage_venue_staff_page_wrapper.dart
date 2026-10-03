import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/staff_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_staff/manage_staff_bloc.dart';
import 'package:hangout/presentation/venue/widgets/assign_venue_staff_sheet.dart';

class ManageVenueStaffPageWrapper extends StatelessWidget {
  final String venueId;
  const ManageVenueStaffPageWrapper({super.key, required this.venueId});

  static Future<void> push(BuildContext context, String venueId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageVenueStaffPageWrapper(venueId: venueId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) =>
          ManageStaffBloc(venueId: venueId)..add(const LoadStaff()),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Text(
            LocaleKeys.manage_venue_staff_page_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Builder(
              builder: (inner) => IconButton(
                tooltip: LocaleKeys.manage_venue_staff_tooltip_add_member.tr(),
                onPressed: () => showAssignVenueStaffSheet(inner),
                icon: Icon(TablerIcons.plus, color: c.onSurface),
              ),
            ),
          ],
        ),
        body: BlocConsumer<ManageStaffBloc, ManageStaffState>(
          listener: (context, state) {
            if (state is ManageStaffActionSucceeded) {
              appToast.success(state.message);
            } else if (state is ManageStaffActionFailed) {
              appToast.error(state.message);
            }
          },
          builder: (context, state) {
            return switch (state) {
              ManageStaffInitial() ||
              ManageStaffLoading() => Center(
                  child: CircularProgressIndicator(
                    color: c.onSurface,
                    strokeWidth: 1.5,
                  ),
                ),
              ManageStaffError(:final message) =>
                _ErrorView(message: message),
              ManageStaffLoaded(:final staff) ||
              ManageStaffMutating(:final staff) ||
              ManageStaffActionSucceeded(:final staff) ||
              ManageStaffActionFailed(:final staff) =>
                staff.isEmpty
                    ? const _EmptyView()
                    : _StaffList(
                        staff: staff,
                        busy: state is ManageStaffMutating,
                      ),
            };
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.alert_triangle,
              color: c.onSurfaceDisabled,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () =>
                  context.read<ManageStaffBloc>().add(const LoadStaff()),
              child: Text(LocaleKeys.manage_venue_staff_button_retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.users, color: c.onSurfaceDisabled, size: 32),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.manage_venue_staff_empty.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (inner) => FilledButton.icon(
                onPressed: () => showAssignVenueStaffSheet(inner),
                icon: Icon(TablerIcons.plus, color: c.surface, size: 16),
                label: Text(LocaleKeys.manage_venue_staff_fab_add_member.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: c.onSurface,
                  foregroundColor: c.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffList extends StatelessWidget {
  final List<VenueStaffResponse> staff;
  final bool busy;
  const _StaffList({required this.staff, required this.busy});

  Future<void> _confirmRevoke(
    BuildContext context,
    VenueStaffResponse member,
  ) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          LocaleKeys.manage_venue_staff_dialog_remove_title.tr(),
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocaleKeys.manage_venue_staff_dialog_remove_body
              .tr(namedArgs: {'username': member.username}),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocaleKeys.manage_venue_staff_button_cancel.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.manage_venue_staff_button_remove.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ManageStaffBloc>().add(RevokeStaffRequested(member.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: staff.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: c.divider,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final member = staff[index];
            final isOwner = member.roleName.toLowerCase() == 'owner';
            return _StaffRow(
              member: member,
              readOnly: isOwner,
              onEdit: isOwner
                  ? null
                  : () => showAssignVenueStaffSheet(
                        context,
                        existing: member,
                      ),
              onRevoke: isOwner
                  ? null
                  : () => _confirmRevoke(context, member),
            );
          },
        ),
        if (busy)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: c.background.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StaffRow extends StatelessWidget {
  final VenueStaffResponse member;
  final bool readOnly;
  final VoidCallback? onEdit;
  final VoidCallback? onRevoke;
  const _StaffRow({
    required this.member,
    required this.readOnly,
    required this.onEdit,
    required this.onRevoke,
  });

  String _localizedRole() {
    switch (member.roleName.toLowerCase()) {
      case 'owner':
        return LocaleKeys.manage_venue_staff_role_owner.tr();
      case 'manager':
        return LocaleKeys.manage_venue_staff_role_manager.tr();
      case 'staff':
        return LocaleKeys.manage_venue_staff_role_staff.tr();
      default:
        return member.roleName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final roleLabel = _localizedRole();
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: member.avatarUrl!,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.displayName ?? member.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: readOnly
                              ? c.success.withValues(alpha: 0.12)
                              : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: readOnly
                                ? c.success
                                : c.onSurfaceSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${member.username}',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!readOnly) ...[
              IconButton(
                tooltip: LocaleKeys.manage_venue_staff_tooltip_edit_role.tr(),
                onPressed: onEdit,
                icon: Icon(TablerIcons.pencil, color: c.onSurface, size: 18),
              ),
              IconButton(
                tooltip: LocaleKeys.manage_venue_staff_tooltip_remove.tr(),
                onPressed: onRevoke,
                icon: Icon(TablerIcons.trash, color: c.danger, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
