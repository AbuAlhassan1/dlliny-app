import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/weekly_recommendations_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class WeeklyCoverAudioScope extends InheritedNotifier<ValueNotifier<String?>> {
  const WeeklyCoverAudioScope({
    super.key,
    required ValueNotifier<String?> super.notifier,
    required super.child,
  });

  static ValueNotifier<String?>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WeeklyCoverAudioScope>()
        ?.notifier;
  }
}

class WeeklyVenueCard extends StatelessWidget {
  static const double width = 280;
  static const double height = 400;

  final WeeklyRecommendationItem item;
  const WeeklyVenueCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VenuePageWrapper(venueId: item.venueId),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Cover(item: item),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 110,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (item.fallback)
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: _FallbackChip(),
                ),
              PositionedDirectional(
                start: 12,
                end: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LogoAvatar(url: item.logoUrl),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.2,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
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

class _Cover extends StatelessWidget {
  final WeeklyRecommendationItem item;
  const _Cover({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (isVideoCover(
      coverUrl: item.coverUrl,
      coverStreamUrl: item.coverStreamUrl,
    )) {
      final source = VideoSource.of(
        item.coverUrl ?? '',
        streamUrl: item.coverStreamUrl,
      );
      return _CoverVideo(
        key: ValueKey((item.venueId, source)),
        source: source,
        venueId: item.venueId,
      );
    }
    final url = item.coverUrl ?? item.logoUrl;
    if (url == null || url.isEmpty) return _placeholder(c);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: 720,
      placeholder: (_, _) => Container(color: c.surfaceMuted),
      errorWidget: (_, _, _) => _placeholder(c),
    );
  }

  Widget _placeholder(AppColors c) => Container(
        color: c.surfaceMuted,
        alignment: Alignment.center,
        child: Icon(
          TablerIcons.building_store,
          color: c.onSurfaceSecondary,
          size: 36,
        ),
      );
}

class _CoverVideo extends StatefulWidget {
  final VideoSource source;
  final String venueId;
  const _CoverVideo({
    super.key,
    required this.source,
    required this.venueId,
  });

  @override
  State<_CoverVideo> createState() => _CoverVideoState();
}

class _CoverVideoState extends State<_CoverVideo> {
  late final VideoPlayback _video;
  VideoPlayerController? get _controller => _video.controller;
  bool _muted = true;
  bool _visible = false;
  ValueNotifier<String?>? _audioScope;

  @override
  void initState() {
    super.initState();
    _video = widget.source.load(
      onReady: (ctrl) async {
        if (!mounted) return;
        await ctrl.setLooping(true);
        await ctrl.setVolume(_muted ? 0 : 1);
        if (!mounted) return;
        setState(() {});
        if (_visible) await ctrl.play();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = WeeklyCoverAudioScope.maybeOf(context);
    if (identical(next, _audioScope)) return;
    _audioScope?.removeListener(_syncFromAudioScope);
    _audioScope = next;
    _audioScope?.addListener(_syncFromAudioScope);
    _syncFromAudioScope();
  }

  @override
  void dispose() {
    _audioScope?.removeListener(_syncFromAudioScope);
    _controller?.pause();
    _video.dispose();
    super.dispose();
  }

  void _syncFromAudioScope() {
    final activeId = _audioScope?.value;
    final shouldBeMuted = activeId != widget.venueId;
    if (shouldBeMuted == _muted) return;
    setState(() => _muted = shouldBeMuted);
    final ctrl = _controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      ctrl.setVolume(shouldBeMuted ? 0 : 1);
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _visible = info.visibleFraction >= 0.1;
      return;
    }
    final shouldPlay = info.visibleFraction >= 0.1;
    if (shouldPlay == _visible) return;
    _visible = shouldPlay;
    if (shouldPlay) {
      ctrl.play();
    } else {
      ctrl.pause();
    }
  }

  void _toggleMute() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final scope = _audioScope;
    if (scope != null) {
      scope.value = scope.value == widget.venueId ? null : widget.venueId;
      return;
    }
    final next = !_muted;
    setState(() => _muted = next);
    ctrl.setVolume(next ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ctrl = _controller;
    return VisibilityDetector(
      key: ValueKey('weekly-cover-${widget.venueId}-${widget.source.uri}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ctrl != null && ctrl.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ctrl.value.size.width,
                height: ctrl.value.size.height,
                child: VideoPlayer(ctrl),
              ),
            )
          else
            Container(color: c.surfaceMuted),
          PositionedDirectional(
            bottom: 12,
            end: 12,
            child: _MuteToggleButton(muted: _muted, onTap: _toggleMute),
          ),
        ],
      ),
    );
  }
}

class _MuteToggleButton extends StatelessWidget {
  final bool muted;
  final VoidCallback onTap;
  const _MuteToggleButton({required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            muted ? TablerIcons.volume_off : TablerIcons.volume,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  final String? url;
  const _LogoAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const size = 32.0;
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: c.surfaceMuted,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      ),
      child: hasUrl
          ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                errorWidget: (_, _, _) => Icon(
                  TablerIcons.building_store,
                  size: 16,
                  color: c.onSurfaceSecondary,
                ),
              ),
          )
          : Icon(
              TablerIcons.building_store,
              size: 16,
              color: c.onSurfaceSecondary,
            ),
    );
  }
}

class _FallbackChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.flame, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            LocaleKeys.hub_weekly_venues_trending_badge.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}
