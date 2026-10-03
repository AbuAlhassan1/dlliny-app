import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_gallery/venue_gallery_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_chips.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';

class VenueGalleryPage extends StatelessWidget {
  final VenueResponse venue;

  final String? initialTag;

  const VenueGalleryPage({super.key, required this.venue, this.initialTag});

  static Future<void> push(
    BuildContext context,
    VenueResponse venue, {
    String? tag,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueGalleryPage(venue: venue, initialTag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tag = initialTag;
    return BlocProvider(
      create: (_) => VenueGalleryBloc(
        venueId: venue.id,
        seed: venue.gallery?.photos ?? const [],
        tag: tag != null && kGalleryTags.contains(tag) ? tag : null,
      )..add(const VenueGalleryRequested()),
      child: _VenueGalleryView(venue: venue),
    );
  }
}

class _VenueGalleryView extends StatelessWidget {
  final VenueResponse venue;
  const _VenueGalleryView({required this.venue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.venue_gallery_title.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            Text(
              venue.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      body: BlocBuilder<VenueGalleryBloc, VenueGalleryState>(
        builder: (context, state) {
          if (state.photos.isEmpty) {
            return switch (state.status) {
              VenueGalleryStatus.loading => Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
              VenueGalleryStatus.error => _Message(
                icon: TablerIcons.alert_triangle,
                text: LocaleKeys.common_error_generic.tr(),
                action: OutlinedButton(
                  onPressed: () => context.read<VenueGalleryBloc>().add(
                    const VenueGalleryRequested(),
                  ),
                  child: Text(LocaleKeys.common_retry.tr()),
                ),
              ),
              VenueGalleryStatus.ready => _Message(
                icon: TablerIcons.photo_off,
                text: LocaleKeys.common_no_results.tr(),
              ),
            };
          }
          return _GalleryBody(venue: venue, state: state);
        },
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  final VenueResponse venue;
  final VenueGalleryState state;
  const _GalleryBody({required this.venue, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VenueGalleryBloc>();
    final branches = venue.onlineOnly
        ? const []
        : sortedGalleryBranches(venue.locations);
    final counts = state.tagCounts;
    final selectedTag = state.tag;
    final visible = state.visible;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (branches.length >= 2) ...[
          const SizedBox(height: 4),
          GalleryChipRow(
            chips: [
              GalleryChip(
                label: LocaleKeys.venue_gallery_branch_all.tr(),
                selected: state.locationId == null,
                onTap: () => bloc.add(const VenueGalleryBranchSelected(null)),
              ),
              for (final b in branches)
                GalleryChip(
                  label: galleryBranchLabel(b),
                  selected: state.locationId == b.id,
                  onTap: () => bloc.add(VenueGalleryBranchSelected(b.id)),
                ),
            ],
          ),
        ],
        if (counts.isNotEmpty || selectedTag != null) ...[
          const SizedBox(height: 8),
          GalleryChipRow(
            chips: [
              GalleryChip(
                label: LocaleKeys.venue_gallery_filter_all.tr(),
                count: state.branchPhotos.length,
                selected: selectedTag == null,
                onTap: () => bloc.add(const VenueGalleryTagSelected(null)),
              ),
              for (final tag in kGalleryTags)
                if (counts.containsKey(tag) || tag == selectedTag)
                  GalleryChip(
                    label: galleryTagLabel(tag),
                    count: counts[tag] ?? 0,
                    selected: tag == selectedTag,
                    onTap: () => bloc.add(VenueGalleryTagSelected(tag)),
                  ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Expanded(
          child: visible.isEmpty
              ? _Message(
                  icon: TablerIcons.photo_off,
                  text: LocaleKeys.common_no_results.tr(),
                )
              : GridView.builder(
                  padding: EdgeInsets.only(bottom: bottomInset + 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3 / 4,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => GalleryPhotoTile(
                    key: ValueKey(visible[i].id),
                    photo: visible[i],
                    hero: true,
                    semanticLabel: galleryPhotoSemanticLabel(
                      visible[i],
                      index: i,
                      total: visible.length,
                    ),
                    onTap: () => VenuePhotoViewerPage.open(
                      context,
                      photos: visible,
                      index: i,
                      branches: venue.locations,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceDisabled, size: 32),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
