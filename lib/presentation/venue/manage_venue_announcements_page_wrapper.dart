import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/domain/dto/request/update_announcement_request.dart';
import 'package:hangout/domain/dto/response/announcement_management_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_announcements/manage_announcements_bloc.dart';
import 'package:hangout/presentation/venue/widgets/announcement_form_sheet.dart';

class ManageVenueAnnouncementsPageWrapper extends StatelessWidget {
  final String venueId;
  const ManageVenueAnnouncementsPageWrapper({
    super.key,
    required this.venueId,
  });

  static Future<void> push(BuildContext context, String venueId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManageVenueAnnouncementsPageWrapper(venueId: venueId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) => ManageAnnouncementsBloc(venueId: venueId)
        ..add(const LoadAnnouncements()),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Text(
            LocaleKeys.manage_venue_announcements_page_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            Builder(
              builder: (inner) => IconButton(
                tooltip: LocaleKeys.manage_venue_announcements_tooltip_new.tr(),
                onPressed: () => showAnnouncementFormSheet(inner),
                icon: Icon(TablerIcons.plus, color: c.onSurface),
              ),
            ),
          ],
        ),
        body: BlocConsumer<ManageAnnouncementsBloc, ManageAnnouncementsState>(
          listener: (context, state) {
            if (state is ManageAnnouncementsActionSucceeded) {
              appToast.success(state.message);
            } else if (state is ManageAnnouncementsActionFailed) {
              appToast.error(state.message);
            }
          },
          builder: (context, state) {
            return switch (state) {
              ManageAnnouncementsInitial() ||
              ManageAnnouncementsLoading() => Center(
                  child: CircularProgressIndicator(
                    color: c.onSurface,
                    strokeWidth: 1.5,
                  ),
                ),
              ManageAnnouncementsError(:final message) =>
                _ErrorView(message: message),
              ManageAnnouncementsLoaded(:final items, :final hasMore) =>
                items.isEmpty
                    ? const _EmptyView()
                    : _AnnouncementsList(
                        items: items,
                        hasMore: hasMore,
                        busy: false,
                      ),
              ManageAnnouncementsMutating(:final items) =>
                _AnnouncementsList(
                  items: items,
                  hasMore: false,
                  busy: true,
                ),
              ManageAnnouncementsActionSucceeded(:final items) =>
                _AnnouncementsList(items: items, hasMore: false, busy: false),
              ManageAnnouncementsActionFailed(:final items) =>
                _AnnouncementsList(items: items, hasMore: false, busy: false),
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
              onPressed: () => context
                  .read<ManageAnnouncementsBloc>()
                  .add(const LoadAnnouncements()),
              child: Text(LocaleKeys.manage_venue_announcements_button_retry.tr()),
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
            Icon(TablerIcons.speakerphone, color: c.onSurfaceDisabled, size: 32),
            const SizedBox(height: 10),
            Text(
              LocaleKeys.manage_venue_announcements_empty.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (inner) => FilledButton.icon(
                onPressed: () => showAnnouncementFormSheet(inner),
                icon: Icon(TablerIcons.plus, color: c.surface, size: 16),
                label: Text(LocaleKeys.manage_venue_announcements_fab_new.tr()),
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

class _AnnouncementsList extends StatefulWidget {
  final List<AnnouncementResponse> items;
  final bool hasMore;
  final bool busy;
  const _AnnouncementsList({
    required this.items,
    required this.hasMore,
    required this.busy,
  });

  @override
  State<_AnnouncementsList> createState() => _AnnouncementsListState();
}

class _AnnouncementsListState extends State<_AnnouncementsList> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      context
          .read<ManageAnnouncementsBloc>()
          .add(const LoadMoreAnnouncements());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AnnouncementResponse a,
  ) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          LocaleKeys.manage_venue_announcements_dialog_delete_title.tr(),
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          LocaleKeys.manage_venue_announcements_dialog_delete_body
              .tr(namedArgs: {'title': a.titleAr}),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocaleKeys.manage_venue_announcements_button_cancel.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              LocaleKeys.manage_venue_announcements_button_delete.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context
          .read<ManageAnnouncementsBloc>()
          .add(DeleteAnnouncementRequested(a.id));
    }
  }

  void _togglePinned(BuildContext context, AnnouncementResponse a) {
    context.read<ManageAnnouncementsBloc>().add(
          UpdateAnnouncementSubmitted(
            announcementId: a.id,
            body: UpdateAnnouncementRequest(pinned: !a.pinned),
            successMessage: !a.pinned
                ? LocaleKeys.manage_venue_announcements_success_pinned.tr()
                : LocaleKeys.manage_venue_announcements_success_unpinned.tr(),
          ),
        );
  }

  void _toggleActive(BuildContext context, AnnouncementResponse a) {
    context.read<ManageAnnouncementsBloc>().add(
          UpdateAnnouncementSubmitted(
            announcementId: a.id,
            body: UpdateAnnouncementRequest(active: !a.active),
            successMessage: !a.active
                ? LocaleKeys.manage_venue_announcements_success_republished.tr()
                : LocaleKeys.manage_venue_announcements_success_hidden.tr(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= widget.items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: CircularProgressIndicator(
                    color: c.onSurface,
                    strokeWidth: 1.5,
                  ),
                ),
              );
            }
            final a = widget.items[index];
            return _AnnouncementCard(
              announcement: a,
              onEdit: () => showAnnouncementFormSheet(context, existing: a),
              onTogglePinned: () => _togglePinned(context, a),
              onToggleActive: () => _toggleActive(context, a),
              onDelete: () => _confirmDelete(context, a),
            );
          },
        ),
        if (widget.busy)
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

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementResponse announcement;
  final VoidCallback onEdit;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onTogglePinned,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = announcement;
    final expiresAt =
        a.expiresAt != null ? DateTime.tryParse(a.expiresAt!) : null;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (a.pinned) ...[
                  Icon(TablerIcons.pin_filled, color: c.primary, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    a.titleAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!a.active)
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
                      LocaleKeys.manage_venue_announcements_badge_hidden.tr(),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              a.bodyAr,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(TablerIcons.clock, color: c.onSurfaceMuted, size: 12),
                const SizedBox(width: 4),
                Text(
                  formatRelativeTime(a.createdAt),
                  style: TextStyle(color: c.onSurfaceMuted, fontSize: 10),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    TablerIcons.calendar_due,
                    color: c.onSurfaceMuted,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LocaleKeys.manage_venue_announcements_expires_label
                        .tr(namedArgs: {'date': _shortDate(expiresAt)}),
                    style: TextStyle(color: c.onSurfaceMuted, fontSize: 10),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: (a.pinned
                          ? LocaleKeys.manage_venue_announcements_tooltip_unpin
                          : LocaleKeys.manage_venue_announcements_tooltip_pin)
                      .tr(),
                  onPressed: onTogglePinned,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    a.pinned ? TablerIcons.pin_filled : TablerIcons.pin,
                    color: a.pinned ? c.primary : c.onSurfaceSecondary,
                    size: 18,
                  ),
                ),
                IconButton(
                  tooltip: (a.active
                          ? LocaleKeys.manage_venue_announcements_tooltip_hide
                          : LocaleKeys.manage_venue_announcements_tooltip_republish)
                      .tr(),
                  onPressed: onToggleActive,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    a.active ? TablerIcons.eye_off : TablerIcons.eye,
                    color: c.onSurfaceSecondary,
                    size: 18,
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.manage_venue_announcements_tooltip_delete.tr(),
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(TablerIcons.trash, color: c.danger, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }
}
