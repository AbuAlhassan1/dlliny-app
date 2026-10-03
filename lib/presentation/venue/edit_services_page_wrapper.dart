import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/venue_service_management_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_services/manage_services_bloc.dart';
import 'package:hangout/presentation/venue/controllers/services_controller/services_bloc.dart';
import 'package:hangout/presentation/venue/widgets/service_form_sheet.dart';

class EditServicesPageWrapper extends StatelessWidget {
  final String venueId;
  const EditServicesPageWrapper({super.key, required this.venueId});

  static Future<void> push(BuildContext context, String venueId) {
    final publicServicesBloc = context.read<ServicesBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: publicServicesBloc,
          child: BlocProvider(
            create: (_) => ManageServicesBloc(venueId: venueId)
              ..add(const LoadMyServices()),
            child: EditServicesPageWrapper(venueId: venueId),
          ),
        ),
      ),
    );
  }

  void _refreshPublicGrid(BuildContext context) {
    context.read<ServicesBloc>().add(GetServices(venueId));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VenueServiceResponse s,
  ) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          LocaleKeys.manage_venue_services_dialog_delete_title.tr(),
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocaleKeys.manage_venue_services_dialog_delete_body
              .tr(namedArgs: {'name': s.serviceTypeNameAr}),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocaleKeys.common_cancel.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.manage_venue_services_tooltip_delete.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ManageServicesBloc>().add(DeleteServiceRequested(s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.manage_venue_services_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Builder(
            builder: (innerContext) => IconButton(
              tooltip: LocaleKeys.manage_venue_services_tooltip_add_service.tr(),
              onPressed: () => showServiceFormSheet(innerContext),
              icon: Icon(TablerIcons.plus, color: c.onSurface),
            ),
          ),
        ],
      ),
      body: BlocConsumer<ManageServicesBloc, ManageServicesState>(
        listener: (context, state) {
          if (state is ManageServicesActionSucceeded) {
            appToast.success(state.message);
            _refreshPublicGrid(context);
          } else if (state is ManageServicesActionFailed) {
            appToast.error(state.message);
          }
        },
        builder: (context, state) {
          return switch (state) {
            ManageServicesInitial() ||
            ManageServicesLoading() => _Loading(c: c),
            ManageServicesError(:final message) => _ErrorView(message: message),
            ManageServicesLoaded(:final services) ||
            ManageServicesMutating(:final services) ||
            ManageServicesActionSucceeded(:final services) ||
            ManageServicesActionFailed(:final services) =>
              services.isEmpty
                  ? const _EmptyView()
                  : _List(
                      services: services,
                      busy: state is ManageServicesMutating,
                      onEdit: (s) => showServiceFormSheet(context, existing: s),
                      onDelete: (s) => _confirmDelete(context, s),
                    ),
          };
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  final AppColors c;
  const _Loading({required this.c});
  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(color: c.onSurface, strokeWidth: 1.5),
      );
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
              onPressed: () => context.read<ManageServicesBloc>().add(
                const LoadMyServices(),
              ),
              child: Text(LocaleKeys.manage_venue_services_button_retry.tr()),
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
            Icon(
              TablerIcons.list_check,
              color: c.onSurfaceDisabled,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.manage_venue_services_empty_no_services.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (innerContext) => FilledButton.icon(
                onPressed: () => showServiceFormSheet(innerContext),
                icon: Icon(TablerIcons.plus, color: c.surface, size: 16),
                label: Text(LocaleKeys.manage_venue_services_fab_add_service.tr()),
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

class _List extends StatelessWidget {
  final List<VenueServiceResponse> services;
  final bool busy;
  final void Function(VenueServiceResponse) onEdit;
  final void Function(VenueServiceResponse) onDelete;
  const _List({
    required this.services,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: services.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: c.divider,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final s = services[index];
            return _ServiceRow(
              service: s,
              onEdit: () => onEdit(s),
              onDelete: () => onDelete(s),
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

class _ServiceRow extends StatelessWidget {
  final VenueServiceResponse service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServiceRow({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = service;
    final hasImage = s.imageUrl != null && s.imageUrl!.isNotEmpty;
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: s.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        TablerIcons.tool,
                        color: c.onSurfaceSecondary,
                        size: 20,
                      ),
                    )
                  : Icon(
                      TablerIcons.tool,
                      color: c.onSurfaceSecondary,
                      size: 20,
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
                          s.serviceTypeNameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!s.active) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LocaleKeys.manage_venue_services_label_unpublished.tr(),
                            style: TextStyle(
                              color: c.onSurfaceSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.price != null
                        ? LocaleKeys.manage_venue_services_price_iqd.tr(
                            namedArgs: {'price': s.price!.toStringAsFixed(0)},
                          )
                        : s.serviceTypeNameEn,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: LocaleKeys.manage_venue_services_tooltip_edit.tr(),
              onPressed: onEdit,
              icon: Icon(TablerIcons.pencil, color: c.onSurface, size: 18),
            ),
            IconButton(
              tooltip: LocaleKeys.manage_venue_services_tooltip_delete.tr(),
              onPressed: onDelete,
              icon: Icon(TablerIcons.trash, color: c.danger, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
