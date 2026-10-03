import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/request/gallery_requests.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_gallery/manage_gallery_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/utils/gallery_upload.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_chips.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';
import 'package:image_picker/image_picker.dart';

class VenueGalleryManagerPage extends StatelessWidget {
  final String venueId;

  final List<VenueLocationResponse> branches;

  final ImagePicker? picker;
  final GalleryFilePreparer? prepare;
  final GalleryS3Uploader? upload;

  const VenueGalleryManagerPage({
    super.key,
    required this.venueId,
    this.branches = const [],
    @visibleForTesting this.picker,
    @visibleForTesting this.prepare,
    @visibleForTesting this.upload,
  });

  static Future<bool?> push(
    BuildContext context,
    String venueId, {
    List<VenueLocationResponse> branches = const [],
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            VenueGalleryManagerPage(venueId: venueId, branches: branches),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = userHasOnVenue(context, VenuePerm.mediaDelete, venueId);
    return BlocProvider(
      create: (_) => ManageGalleryBloc(
        venueId: venueId,
        canManage: canManage,
        prepare: prepare ?? prepareGalleryFile,
        upload: upload ?? putGalleryBytes,
      )..add(const GalleryLoadRequested()),
      child: _ManagerView(
        branches: branches,
        canManage: canManage,
        picker: picker ?? ImagePicker(),
      ),
    );
  }
}

class _ManagerView extends StatefulWidget {
  final List<VenueLocationResponse> branches;
  final bool canManage;
  final ImagePicker picker;

  const _ManagerView({
    required this.branches,
    required this.canManage,
    required this.picker,
  });

  @override
  State<_ManagerView> createState() => _ManagerViewState();
}

class _ManagerViewState extends State<_ManagerView> {
  List<GalleryPhotoDto>? _reorder;

  bool _leaving = false;

  int? _shownNotice;

  bool get _showBranch => widget.branches.length >= 2;

  Future<void> _onBack() async {
    if (_reorder != null) {
      setState(() => _reorder = null);
      return;
    }
    final bloc = context.read<ManageGalleryBloc>();
    if (_leaving) {
      _leaving = false;
      Navigator.of(context).pop(true);
      return;
    }
    if (!bloc.state.uploading) {
      Navigator.of(context).pop(bloc.state.changed);
      return;
    }
    final leave = await _confirmLeave();
    if (leave != true || !mounted || bloc.isClosed) return;
    if (!bloc.state.uploading) {
      Navigator.of(context).pop(bloc.state.changed);
      return;
    }
    setState(() => _leaving = true);
    bloc.add(const GalleryUploadsCancelled());
  }

  Future<bool?> _confirmLeave() {
    final c = context.c;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(LocaleKeys.manage_venue_gallery_manager_leave_title.tr()),
        content: Text(LocaleKeys.manage_venue_gallery_manager_leave_body.tr()),
        actions: [
          TextButton(
            key: const ValueKey('gallery-leave-stay'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              LocaleKeys.manage_venue_gallery_manager_leave_stay.tr(),
            ),
          ),
          TextButton(
            key: const ValueKey('gallery-leave-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(
              LocaleKeys.manage_venue_gallery_manager_leave_confirm.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final bloc = context.read<ManageGalleryBloc>();
    final remaining = bloc.state.remaining;
    if (remaining <= 0) {
      appToast.info(
        galleryManagerErrorText(
          VenueErrorCodes.galleryLimitReached,
          maxPhotos: bloc.state.maxPhotos,
        ),
      );
      return;
    }
    final List<XFile> files;
    try {
      files = await pickGalleryFiles(widget.picker, remaining);
    } catch (_) {
      appToast.error(LocaleKeys.common_error_generic.tr());
      return;
    }
    if (files.isEmpty || !mounted) return;
    final batch = await _showBatchSheet(context, widget.branches);
    if (batch == null || bloc.isClosed) return;
    bloc.add(
      GalleryPhotosPicked(
        files,
        tags: batch.tags,
        locationId: batch.locationId,
      ),
    );
  }

  Future<void> _onPhotoTap(
    GalleryPhotoDto photo,
    List<GalleryPhotoDto> all,
  ) async {
    if (_leaving) return;
    if (!widget.canManage) {
      if (photo.hidden) {
        appToast.info(
          LocaleKeys.manage_venue_gallery_manager_hidden_by_admin.tr(),
          body: _hiddenReason(photo),
        );
        return;
      }
      final visible = [
        for (final p in all)
          if (!p.hidden) p,
      ];
      await VenuePhotoViewerPage.open(
        context,
        photos: visible,
        index: visible.indexOf(photo),
        branches: widget.branches,
      );
      return;
    }
    final bloc = context.read<ManageGalleryBloc>();
    final edit = await _showEditSheet(context, photo, widget.branches);
    if (edit == null || bloc.isClosed) return;
    if (edit.delete) {
      bloc.add(GalleryPhotoDeleted(photo.id));
    } else {
      bloc.add(
        GalleryPhotoEdited(
          photo.id,
          tags: edit.tags,
          venueLocationId: edit.venueLocationId,
        ),
      );
    }
  }

  void _toggleReorder(ManageGalleryState state) {
    final order = _reorder;
    if (order == null) {
      setState(() => _reorder = [...state.photos]);
      return;
    }
    context.read<ManageGalleryBloc>().add(
      GalleryReorderCommitted([for (final p in order) p.id]),
    );
    setState(() => _reorder = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<ManageGalleryBloc, ManageGalleryState>(
      listenWhen: (prev, curr) =>
          (curr.notice != null && prev.notice?.serial != curr.notice?.serial) ||
          (_leaving && !curr.uploading),
      listener: (context, state) {
        final notice = state.notice;
        if (notice != null && notice.serial != _shownNotice) {
          _shownNotice = notice.serial;
          final code = notice.code;
          final text = galleryManagerErrorText(
            code,
            maxPhotos: state.maxPhotos,
          );
          if (code == VenueErrorCodes.galleryLimitReached) {
            appToast.info(text);
          } else {
            appToast.error(
              text,
              body: notice.branchCleared
                  ? LocaleKeys
                        .manage_venue_gallery_manager_branch_not_found_retry
                        .tr()
                  : null,
            );
          }
        }
        if (_leaving && !state.uploading) {
          _leaving = false;
          Navigator.of(context).pop(state.changed);
        }
      },
      builder: (context, state) {
        final reordering = _reorder != null;
        final canReorder =
            widget.canManage &&
            state.status == ManageGalleryStatus.ready &&
            state.photos.length >= 2;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBack();
          },
          child: Scaffold(
            backgroundColor: c.background,
            appBar: AppBar(
              backgroundColor: c.background,
              foregroundColor: c.onSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                LocaleKeys.manage_venue_gallery_manager_title.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              actions: [
                if (canReorder)
                  TextButton.icon(
                    key: const ValueKey('gallery-manager-reorder'),
                    onPressed: state.uploading || state.busy
                        ? null
                        : () => _toggleReorder(state),
                    icon: Icon(
                      reordering ? TablerIcons.check : TablerIcons.arrows_sort,
                      size: 18,
                    ),
                    label: Text(
                      (reordering
                              ? LocaleKeys
                                    .manage_venue_gallery_manager_reorder_done
                              : LocaleKeys.manage_venue_gallery_manager_reorder)
                          .tr(),
                    ),
                    style: TextButton.styleFrom(foregroundColor: c.onSurface),
                  ),
                const SizedBox(width: 8),
              ],
            ),
            body: switch (state.status) {
              ManageGalleryStatus.loading => Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
              ManageGalleryStatus.error => _LoadError(
                onRetry: () => context.read<ManageGalleryBloc>().add(
                  const GalleryLoadRequested(),
                ),
              ),
              ManageGalleryStatus.ready =>
                reordering
                    ? _ReorderList(
                        photos: _reorder!,
                        onReorder: (from, to) => setState(() {
                          final list = _reorder!;
                          list.insert(to, list.removeAt(from));
                        }),
                      )
                    : IgnorePointer(
                        ignoring: _leaving,
                        child: _Grid(
                          state: state,
                          canManage: widget.canManage,
                          branches: widget.branches,
                          leaving: _leaving,
                          onPhotoTap: (p) => _onPhotoTap(p, state.photos),
                        ),
                      ),
            },
            bottomNavigationBar:
                state.status == ManageGalleryStatus.ready &&
                    !reordering &&
                    !_leaving
                ? _AddBar(state: state, onAdd: _add)
                : null,
          ),
        );
      },
    );
  }

  Future<_Batch?> _showBatchSheet(
    BuildContext context,
    List<VenueLocationResponse> branches,
  ) {
    return showModalBottomSheet<_Batch>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchSheet(branches: _showBranch ? branches : const []),
    );
  }

  Future<_Edit?> _showEditSheet(
    BuildContext context,
    GalleryPhotoDto photo,
    List<VenueLocationResponse> branches,
  ) {
    return showModalBottomSheet<_Edit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EditSheet(photo: photo, branches: _showBranch ? branches : const []),
    );
  }
}

String? _hiddenReason(GalleryPhotoDto photo) {
  final reason = photo.hiddenReason;
  if (reason == null || reason.trim().isEmpty) return null;
  return LocaleKeys.manage_venue_gallery_manager_hidden_reason.tr(
    namedArgs: {'reason': reason.trim()},
  );
}

class _Grid extends StatelessWidget {
  final ManageGalleryState state;
  final bool canManage;
  final List<VenueLocationResponse> branches;

  final bool leaving;
  final ValueChanged<GalleryPhotoDto> onPhotoTap;

  const _Grid({
    required this.state,
    required this.canManage,
    required this.branches,
    required this.leaving,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final uploads = state.pendingUploads;
    final count = state.photos.length;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Counter(count: count, max: state.maxPhotos),
                if (!canManage) ...[
                  const SizedBox(height: 12),
                  GalleryNotice(
                    key: const ValueKey('gallery-manager-staff-hint'),
                    icon: TablerIcons.info_circle,
                    text: LocaleKeys.manage_venue_gallery_manager_staff_hint
                        .tr(),
                    color: c.onSurfaceSecondary,
                  ),
                ],
                if (state.uploading) ...[
                  const SizedBox(height: 12),
                  _UploadProgress(
                    text: leaving
                        ? LocaleKeys.manage_venue_gallery_manager_finishing.tr()
                        : LocaleKeys.manage_venue_gallery_manager_uploading.tr(
                            namedArgs: {
                              'done': '${state.uploadsDone}',
                              'total': '${state.uploadsTotal}',
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (count == 0 && uploads.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TablerIcons.photo,
                      color: c.onSurfaceDisabled,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocaleKeys.venue_gallery_empty_owner.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.onSurfaceSecondary),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 3 / 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: count + uploads.length,
              itemBuilder: (context, i) {
                if (i < count) {
                  final photo = state.photos[i];
                  final label = galleryPhotoSemanticLabel(
                    photo,
                    index: i,
                    total: count,
                  );
                  final hidden = LocaleKeys
                      .manage_venue_gallery_manager_hidden_by_admin
                      .tr();
                  return GalleryPhotoTile(
                    key: ValueKey('gallery-manager-photo-${photo.id}'),
                    photo: photo,
                    overlay: _PhotoOverlay(
                      photo: photo,
                      hasBranch:
                          photo.locationId != null && branches.length >= 2,
                    ),
                    semanticLabel: photo.hidden ? '$hidden · $label' : label,
                    onTap: () => onPhotoTap(photo),
                  );
                }
                final item = uploads[i - count];
                return _UploadTile(
                  key: ValueKey('gallery-manager-upload-${item.localId}'),
                  item: item,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final int count;
  final int max;
  const _Counter({required this.count, required this.max});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Text(
          LocaleKeys.manage_venue_gallery_manager_counter.tr(
            namedArgs: {'count': '$count', 'max': '$max'},
          ),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max <= 0 ? 0 : (count / max).clamp(0.0, 1.0),
              minHeight: 6,
              color: count >= max ? c.warning : c.onSurface,
              backgroundColor: c.surfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final String text;
  const _UploadProgress({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: c.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          key: const ValueKey('gallery-manager-progress'),
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _PhotoOverlay extends StatelessWidget {
  final GalleryPhotoDto photo;
  final bool hasBranch;
  const _PhotoOverlay({required this.photo, required this.hasBranch});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tagCount = knownTags(photo.tags).length;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (photo.hidden)
          ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        if (photo.hidden)
          PositionedDirectional(
            top: 6,
            start: 6,
            end: 6,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: c.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      TablerIcons.eye_off,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        LocaleKeys.manage_venue_gallery_manager_hidden_by_admin
                            .tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (tagCount > 0 || hasBranch)
          PositionedDirectional(
            bottom: 6,
            start: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tagCount > 0) ...[
                    const Icon(TablerIcons.tag, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      '$tagCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                  if (tagCount > 0 && hasBranch) const SizedBox(width: 6),
                  if (hasBranch)
                    const Icon(
                      TablerIcons.map_pin,
                      color: Colors.white,
                      size: 12,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  final GalleryUploadItem item;
  const _UploadTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final failed = item.status == GalleryUploadStatus.failed;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: c.surfaceMuted),
        if (item.file.path.isNotEmpty)
          Image.file(
            File(item.file.path),
            fit: BoxFit.cover,
            cacheWidth: (140 * dpr).round(),
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ColoredBox(
          color: failed
              ? c.danger.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.35),
        ),
        if (!failed)
          const Center(
            child: SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TablerIcons.alert_triangle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocaleKeys.manage_venue_gallery_manager_upload_failed.tr(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextButton.icon(
                    key: ValueKey('gallery-manager-retry-${item.localId}'),
                    onPressed: () => context.read<ManageGalleryBloc>().add(
                      GalleryUploadRetried(item.localId),
                    ),
                    icon: const Icon(TablerIcons.refresh, size: 12),
                    label: Text(
                      LocaleKeys.common_retry.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: c.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 26),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: LocaleKeys.common_cancel.tr(),
              onPressed: () => context.read<ManageGalleryBloc>().add(
                GalleryUploadDismissed(item.localId),
              ),
              icon: const Icon(TablerIcons.x, color: Colors.white, size: 16),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddBar extends StatelessWidget {
  final ManageGalleryState state;
  final VoidCallback onAdd;
  const _AddBar({required this.state, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final full = state.remaining <= 0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (full) ...[
              Text(
                galleryManagerErrorText(
                  VenueErrorCodes.galleryLimitReached,
                  maxPhotos: state.maxPhotos,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              key: const ValueKey('gallery-manager-add'),
              onPressed: full ? null : onAdd,
              icon: const Icon(TablerIcons.photo_plus, size: 18),
              label: Text(LocaleKeys.manage_venue_gallery_manager_add.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: c.onSurface,
                foregroundColor: c.surface,
                disabledBackgroundColor: c.surfaceMuted,
                disabledForegroundColor: c.onSurfaceDisabled,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

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
              LocaleKeys.common_error_generic.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(LocaleKeys.common_retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderList extends StatelessWidget {
  final List<GalleryPhotoDto> photos;

  final void Function(int from, int to) onReorder;
  const _ReorderList({required this.photos, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemCount: photos.length,
      onReorderItem: onReorder,
      itemBuilder: (context, i) {
        final photo = photos[i];
        final tags = knownTags(photo.tags).map(galleryTagLabel).join('، ');
        return Material(
          key: ValueKey(photo.id),
          color: c.background,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 64,
                  child: GalleryPhotoTile(
                    photo: photo,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tags.isEmpty ? '—' : tags,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.onSurface, fontSize: 13),
                      ),
                      if (photo.hidden) ...[
                        const SizedBox(height: 4),
                        Text(
                          LocaleKeys
                              .manage_venue_gallery_manager_hidden_by_admin
                              .tr(),
                          style: TextStyle(
                            color: c.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      TablerIcons.grip_vertical,
                      color: c.onSurfaceSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Batch {
  final List<String> tags;
  final String? locationId;
  const _Batch(this.tags, this.locationId);
}

class _Edit {
  final bool delete;
  final List<String>? tags;
  final String? venueLocationId;
  const _Edit({this.delete = false, this.tags, this.venueLocationId});
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;

  final bool handle;
  const _SheetFrame({
    required this.title,
    required this.children,
    this.handle = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (handle) ...[
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
                ] else
                  const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ButtonStyle _primaryButtonStyle(AppColors c) => FilledButton.styleFrom(
  backgroundColor: c.onSurface,
  foregroundColor: c.surface,
  minimumSize: const Size.fromHeight(48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

class _BatchSheet extends StatefulWidget {
  final List<VenueLocationResponse> branches;
  const _BatchSheet({required this.branches});

  @override
  State<_BatchSheet> createState() => _BatchSheetState();
}

class _BatchSheetState extends State<_BatchSheet> {
  List<String> _tags = const [];
  String? _locationId;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _SheetFrame(
      title: LocaleKeys.manage_venue_gallery_manager_batch_tags_title.tr(),
      handle: false,
      children: [
        GalleryTagSelector(
          selected: _tags,
          onChanged: (t) => setState(() => _tags = t),
        ),
        if (widget.branches.isNotEmpty) ...[
          const SizedBox(height: 16),
          GalleryBranchDropdown(
            branches: widget.branches,
            value: _locationId,
            onChanged: (v) => setState(() => _locationId = v),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('gallery-batch-confirm'),
          onPressed: () =>
              Navigator.of(context).pop(_Batch(_tags, _locationId)),
          icon: const Icon(TablerIcons.cloud_upload, size: 18),
          label: Text(LocaleKeys.manage_venue_gallery_manager_add.tr()),
          style: _primaryButtonStyle(c),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const ValueKey('gallery-batch-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: c.onSurfaceSecondary,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(LocaleKeys.common_cancel.tr()),
        ),
      ],
    );
  }
}

class _EditSheet extends StatefulWidget {
  final GalleryPhotoDto photo;

  final List<VenueLocationResponse> branches;
  const _EditSheet({required this.photo, required this.branches});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final List<String> _initialTags;
  late List<String> _tags;

  late final String? _initialBranch;
  late String? _branch;

  @override
  void initState() {
    super.initState();
    _initialTags = knownTags(widget.photo.tags);
    _tags = _initialTags;
    final id = widget.photo.locationId;
    _initialBranch = widget.branches.any((b) => b.id == id) ? id : null;
    _branch = _initialBranch;
  }

  bool get _tagsChanged =>
      _tags.length != _initialTags.length ||
      !_tags.every(_initialTags.contains);

  bool get _branchChanged =>
      widget.branches.isNotEmpty && _branch != _initialBranch;

  Future<void> _confirmDelete() async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          LocaleKeys.manage_venue_gallery_manager_delete_confirm_title.tr(),
        ),
        content: Text(
          LocaleKeys.manage_venue_gallery_manager_delete_confirm_body.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocaleKeys.common_cancel.tr()),
          ),
          TextButton(
            key: const ValueKey('gallery-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(LocaleKeys.manage_venue_gallery_manager_delete.tr()),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(const _Edit(delete: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final photo = widget.photo;
    final reason = _hiddenReason(photo);
    return _SheetFrame(
      title: LocaleKeys.manage_venue_gallery_manager_title.tr(),
      children: [
        Center(
          child: SizedBox(
            width: 96,
            height: 128,
            child: GalleryPhotoTile(
              photo: photo,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (photo.hidden) ...[
          const SizedBox(height: 12),
          GalleryNotice(
            icon: TablerIcons.eye_off,
            text: [
              LocaleKeys.manage_venue_gallery_manager_hidden_by_admin.tr(),
              ?reason,
            ].join(' · '),
            color: c.danger,
          ),
        ],
        const SizedBox(height: 16),
        GalleryTagSelector(
          selected: _tags,
          onChanged: (t) => setState(() => _tags = t),
        ),
        if (widget.branches.isNotEmpty) ...[
          const SizedBox(height: 16),
          GalleryBranchDropdown(
            branches: widget.branches,
            value: _branch,
            onChanged: (v) => setState(() => _branch = v),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey('gallery-edit-save'),
          onPressed: _tagsChanged || _branchChanged
              ? () => Navigator.of(context).pop(
                  _Edit(
                    tags: _tagsChanged ? _tags : null,
                    venueLocationId: _branchChanged
                        ? (_branch ?? kClearVenueLocationId)
                        : null,
                  ),
                )
              : null,
          style: _primaryButtonStyle(c),
          child: Text(LocaleKeys.common_save.tr()),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('gallery-edit-delete'),
          onPressed: _confirmDelete,
          icon: const Icon(TablerIcons.trash, size: 18),
          label: Text(LocaleKeys.manage_venue_gallery_manager_delete.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.danger,
            side: BorderSide(color: c.danger.withValues(alpha: 0.5)),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
