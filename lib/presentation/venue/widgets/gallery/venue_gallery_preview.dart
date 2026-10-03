import 'dart:math' as math;

import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_manager_page.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_page.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/utils/gallery_filters.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_chips.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';
import 'package:hangout/presentation/venue/widgets/venue_about_constants.dart';

const double _kGap = 4;
const BorderRadius _kTileRadius = BorderRadius.all(Radius.circular(10));

class VenueGalleryPreview extends StatelessWidget {
  final VenueResponse venue;

  const VenueGalleryPreview({super.key, required this.venue});

  Future<void> _openManager(BuildContext context) async {
    final venueBloc = context.read<VenueBloc>();
    final changed = await VenueGalleryManagerPage.push(
      context,
      venue.id,
      branches: venue.locations,
    );
    if (changed == true && !venueBloc.isClosed) {
      venueBloc.add(GetVenueDetails(venue.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gallery = venue.gallery;
    if (gallery == null) return const SizedBox.shrink();
    final photos = gallery.photos;
    final canUpload = userHasOnVenue(context, VenuePerm.mediaUpload, venue.id);
    if (photos.isEmpty) {
      if (!canUpload) return const SizedBox.shrink();
      return Padding(
        padding: kVenueAboutPartPadding,
        child: _EmptyCta(onTap: () => _openManager(context)),
      );
    }

    final total = math.max(gallery.totalCount, photos.length);
    final tagCounts = knownTagCounts(gallery.tagCounts);
    void openViewer(int index) => VenuePhotoViewerPage.open(
      context,
      photos: photos,
      index: index,
      branches: venue.locations,
    );
    void openGrid({String? tag}) =>
        VenueGalleryPage.push(context, venue, tag: tag);

    final side = EdgeInsetsDirectional.only(
      start: kVenueAboutPartPadding.start,
      end: kVenueAboutPartPadding.end,
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: kVenueAboutPartPadding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: side,
            child: _Header(total: total, onSeeAll: openGrid),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: side,
            child: photos.length >= 3
                ? _Mosaic(
                    photos: photos,
                    total: total,
                    onPhoto: openViewer,
                    onMore: openGrid,
                  )
                : _Row(photos: photos, total: total, onPhoto: openViewer),
          ),
          if (tagCounts.isNotEmpty) ...[
            const SizedBox(height: 10),
            GalleryChipRow(
              padding: side,
              chips: [
                for (final e in tagCounts.entries)
                  GalleryChip(
                    label: galleryTagLabel(e.key),
                    count: e.value,
                    onTap: () => openGrid(tag: e.key),
                  ),
              ],
            ),
          ],
          if (canUpload) ...[
            const SizedBox(height: 10),
            Padding(
              padding: side,
              child: _ManagePhotosEntry(onTap: () => _openManager(context)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onSeeAll;
  const _Header({required this.total, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(TablerIcons.library_photo, color: c.onSurface, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            LocaleKeys.venue_gallery_title.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinInteractiveDimension,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    LocaleKeys.venue_gallery_see_all.tr(
                      namedArgs: {'count': '$total'},
                    ),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? TablerIcons.chevron_left
                        : TablerIcons.chevron_right,
                    color: c.onSurfaceSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Mosaic extends StatelessWidget {
  final List<GalleryPhotoDto> photos;

  final int total;
  final ValueChanged<int> onPhoto;
  final VoidCallback onMore;

  const _Mosaic({
    required this.photos,
    required this.total,
    required this.onPhoto,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final hiddenCount = total - 3;
    String label(int i) =>
        galleryPhotoSemanticLabel(photos[i], index: i, total: total);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bigWidth = (width - _kGap) * 2 / 3;
        final height = bigWidth * 4 / 3;
        final smallHeight = (height - _kGap) / 2;
        return SizedBox(
          height: height,
          child: Row(
            children: [
              SizedBox(
                width: bigWidth,
                child: GalleryPhotoTile(
                  photo: photos[0],
                  hero: true,
                  borderRadius: _kTileRadius,
                  semanticLabel: label(0),
                  onTap: () => onPhoto(0),
                ),
              ),
              const SizedBox(width: _kGap),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: smallHeight,
                      child: GalleryPhotoTile(
                        photo: photos[1],
                        hero: true,
                        borderRadius: _kTileRadius,
                        semanticLabel: label(1),
                        onTap: () => onPhoto(1),
                      ),
                    ),
                    const SizedBox(height: _kGap),
                    SizedBox(
                      height: smallHeight,
                      child: GalleryPhotoTile(
                        photo: photos[2],
                        hero: hiddenCount <= 0,
                        borderRadius: _kTileRadius,
                        overlay: hiddenCount > 0
                            ? _MoreOverlay(count: hiddenCount)
                            : null,
                        semanticLabel: hiddenCount > 0
                            ? LocaleKeys.venue_gallery_see_all.tr(
                                namedArgs: {'count': '$total'},
                              )
                            : label(2),
                        onTap: hiddenCount > 0 ? onMore : () => onPhoto(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoreOverlay extends StatelessWidget {
  final int count;
  const _MoreOverlay({required this.count});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Text(
          '+$count',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<GalleryPhotoDto> photos;
  final int total;
  final ValueChanged<int> onPhoto;
  const _Row({
    required this.photos,
    required this.total,
    required this.onPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final List<double> ratios;
        final double height;
        if (photos.length == 1) {
          ratios = [layoutRatio(photos[0]).clamp(1.0, 16 / 9)];
          height = width / ratios[0];
        } else {
          ratios = [for (final p in photos) layoutRatio(p).clamp(0.75, 1.5)];
          height = (width - _kGap) / (ratios[0] + ratios[1]);
        }
        return SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < photos.length; i++) ...[
                if (i > 0) const SizedBox(width: _kGap),
                SizedBox(
                  width: photos.length == 1 ? width : ratios[i] * height,
                  child: GalleryPhotoTile(
                    photo: photos[i],
                    hero: true,
                    borderRadius: _kTileRadius,
                    semanticLabel: galleryPhotoSemanticLabel(
                      photos[i],
                      index: i,
                      total: total,
                    ),
                    onTap: () => onPhoto(i),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCta extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: c.borderStrong,
        radius: const Radius.circular(14),
        strokeWidth: 1,
        dashPattern: const [6, 4],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(TablerIcons.photo, color: c.onSurface, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.venue_gallery_title.tr(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleKeys.venue_gallery_empty_owner.tr(),
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(TablerIcons.plus, color: c.onSurfaceSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagePhotosEntry extends StatelessWidget {
  final VoidCallback onTap;
  const _ManagePhotosEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.photo, color: c.onSurface, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LocaleKeys.venue_gallery_manage.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? TablerIcons.chevron_left
                    : TablerIcons.chevron_right,
                color: c.onSurfaceSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
