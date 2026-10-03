import 'dart:math' as math;

import 'package:dismissible_page/dismissible_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/gallery_filters.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_chips.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';

class VenuePhotoViewerPage extends StatefulWidget {
  final List<GalleryPhotoDto> photos;
  final int initialIndex;

  final List<VenueLocationResponse> branches;

  const VenuePhotoViewerPage({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    this.branches = const [],
  });

  static Future<void> open(
    BuildContext context, {
    required List<GalleryPhotoDto> photos,
    int index = 0,
    List<VenueLocationResponse> branches = const [],
  }) {
    if (photos.isEmpty) return Future.value();
    return context.pushTransparentRoute(
      VenuePhotoViewerPage(
        photos: photos,
        initialIndex: index.clamp(0, photos.length - 1),
        branches: branches,
      ),
    );
  }

  @override
  State<VenuePhotoViewerPage> createState() => _VenuePhotoViewerPageState();
}

class _VenuePhotoViewerPageState extends State<VenuePhotoViewerPage> {
  late final PageController _pager;
  late int _index;
  bool _zoomed = false;
  bool _precached = false;

  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pager = PageController(initialPage: _index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      _precacheAround(_index);
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _precacheAround(int index) {
    final images = GalleryImageScope.of(context);
    final width = _decodeWidth(context);
    for (final i in [index - 1, index + 1]) {
      if (i < 0 || i >= widget.photos.length) continue;
      final photo = widget.photos[i];
      precacheImage(
        images(photo.url, cacheWidth: _cacheWidth(photo, width)),
        context,
        onError: (_, _) {},
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    _precacheAround(index);
  }

  void _onZoomChanged(bool zoomed) {
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  VenueLocationResponse? _branchOf(GalleryPhotoDto photo) {
    final id = photo.locationId;
    if (id == null) return null;
    for (final b in widget.branches) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    final tags = knownTags(photo.tags);
    final branch = _branchOf(photo);
    return DismissiblePage(
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.down,
      disabled: _zoomed,
      isFullScreen: true,
      minRadius: 0,
      backgroundColor: Colors.black,
      child: KeyedSubtree(
        key: _contentKey,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pager,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.photos.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => _ZoomablePhoto(
                  key: ValueKey(widget.photos[i].id),
                  photo: widget.photos[i],
                  onZoomChanged: _onZoomChanged,
                ),
              ),
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: _Bar(
                  top: true,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(TablerIcons.x, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        LocaleKeys.venue_gallery_viewer_counter.tr(
                          namedArgs: {
                            'index': '${_index + 1}',
                            'total': '${widget.photos.length}',
                          },
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
              if (tags.isNotEmpty || branch != null)
                PositionedDirectional(
                  bottom: 0,
                  start: 0,
                  end: 0,
                  child: _Bar(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (branch != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  TablerIcons.map_pin,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  galleryBranchLabel(branch),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          for (final t in tags)
                            GalleryChip(
                              label: galleryTagLabel(t),
                              onMedia: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final bool top;
  final Widget child;
  const _Bar({required this.top, required this.child});

  @override
  Widget build(BuildContext context) {
    final scrim = Colors.black.withValues(alpha: 0.5);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [scrim, Colors.transparent],
        ),
      ),
      child: SafeArea(top: top, bottom: !top, child: child),
    );
  }
}

int _decodeWidth(BuildContext context) {
  final mq = MediaQuery.of(context);
  return (mq.size.width * mq.devicePixelRatio * 1.5).round();
}

int? _cacheWidth(GalleryPhotoDto photo, int screenWidth) =>
    photo.width > 0 ? math.min(photo.width, screenWidth) : null;

class _ZoomablePhoto extends StatefulWidget {
  final GalleryPhotoDto photo;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({
    super.key,
    required this.photo,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2;

  final TransformationController _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _tween;
  Offset? _doubleTapAt;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() => _transform.value = _tween!.value);
    _transform.addListener(_onTransform);
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged(zoomed);
  }

  void _onDoubleTap() {
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      final size = context.size ?? Size.zero;
      final p = _doubleTapAt ?? size.center(Offset.zero);
      const s = _doubleTapScale;
      target = Matrix4.identity()
        ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
    _tween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOut));
    _animation.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 4,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Center(
                child: AspectRatio(
                  aspectRatio: layoutRatio(photo),
                  child: Hero(
                    tag: galleryHeroTag(photo),
                    child: GalleryPhotoImage(
                      photo: photo,
                      cacheWidth: _cacheWidth(photo, _decodeWidth(context)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
