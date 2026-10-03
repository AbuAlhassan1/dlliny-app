import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';
import 'package:hangout/presentation/orders/widgets/product_order_cta.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/post/widgets/comments_bottom_sheet.dart';
import 'package:hangout/presentation/post/widgets/hangout_here_button.dart';
import 'package:hangout/presentation/post/widgets/shop_products_button.dart';
import 'package:hangout/presentation/post/widgets/media_double_tap_like.dart';
import 'package:hangout/presentation/post/widgets/mentioned_caption.dart';
import 'package:hangout/presentation/post/widgets/post_actions_sheet.dart';
import 'package:hangout/presentation/post/widgets/post_like_button.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/presentation/shared/widgets/author_preview_popup.dart';
import 'package:hangout/presentation/shared/widgets/scroll_snapy_physics.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wave_divider/wave_divider.dart';

const String _venuePostsDeletePerm = 'venue:posts:delete';

bool _isMyPost(BuildContext context, PostFeedItem item) {
  final myId = context.read<MyProfileBloc>().user?.id;
  if (myId != null && item.authorUserId == myId) return true;
  final venueId = item.authorVenueId;
  if (venueId == null) return false;
  final access = context.read<AccessBloc>().myAccess?.data;
  if (access == null) return false;
  bool canDelete(v) =>
      v.venueId == venueId &&
      v.effectivePermissions.contains(_venuePostsDeletePerm);
  for (final biz in access.businesses) {
    for (final v in biz.venues) {
      if (canDelete(v)) return true;
    }
  }
  for (final v in access.orphanVenues) {
    if (canDelete(v)) return true;
  }
  return false;
}

class PostWidget extends StatefulWidget {
  final PostFeedItem item;

  const PostWidget({super.key, required this.item});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  static const double _playThreshold = 0.6;

  late List<VideoPlayback?> videos;
  final PageController controller = PageController();
  bool _initialized = false;
  double? _mediaAspect;
  int _currentMediaIndex = 0;
  double _visibleFraction = 0;
  final Set<int> _manuallyPaused = {};
  bool _deletedLocally = false;

  @override
  void initState() {
    super.initState();
    videos = List<VideoPlayback?>.filled(
      widget.item.mediaUrls.length,
      null,
      growable: false,
    );
    _resolveFirstMediaAspect();
    controller.addListener(_onMediaPageChanged);
  }

  void _onMediaPageChanged() {
    final page = controller.page?.round() ?? 0;
    if (page == _currentMediaIndex) return;
    _currentMediaIndex = page;
    _syncPlayback();
  }

  void _resolveFirstMediaAspect() {
    final urls = widget.item.mediaUrls;
    if (urls.isEmpty) return;
    final first = urls.first.aspectRatio;
    if (first != null && first.isFinite && first > 0) {
      _mediaAspect = first;
    }
  }

  void _initVideos() {
    if (_initialized) return;
    _initialized = true;
    for (int i = 0; i < widget.item.mediaUrls.length; i++) {
      final mediaItem = widget.item.mediaUrls[i];
      if (mediaItem.type == 'video') {
        videos[i] = VideoSource.of(
          mediaItem.url,
          streamUrl: mediaItem.streamUrl,
        ).load(
          onReady: (c) async {
            if (!mounted) return;
            await c.setLooping(true);
            if (!mounted) return;
            setState(() {});
            _syncPlayback();
          },
        );
      }
    }
  }

  void _syncPlayback() {
    if (!mounted) return;
    final shouldPlay = _visibleFraction >= _playThreshold;
    final muted = context.read<VideoBloc>().state.isMuted;
    for (int i = 0; i < videos.length; i++) {
      final c = videos[i]?.controller;
      if (c == null || !c.value.isInitialized) continue;
      final isActive =
          shouldPlay && i == _currentMediaIndex && !_manuallyPaused.contains(i);
      if (isActive) {
        c.setVolume(muted ? 0 : 1);
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onMediaPageChanged);
    for (final video in videos) {
      video?.dispose();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deletedLocally) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imgWidth = (screenWidth * dpr).toInt();
    final c = context.c;
    return BlocListener<VideoBloc, VideoBlocState>(
      listenWhen: (_, curr) => curr is VideoToggledSound,
      listener: (_, _) => _syncPlayback(),
      child: VisibilityDetector(
        key: Key('post-${widget.item.id}'),
        onVisibilityChanged: (info) {
          _visibleFraction = info.visibleFraction;
          if (info.visibleFraction > 0.1 && !_initialized) _initVideos();
          _syncPlayback();
        },
        child: Container(
          padding: const EdgeInsets.only(top: 5),
          margin: const EdgeInsets.only(left: 0, right: 0, bottom: 15),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 15, end: 0),
                child: SizedBox(
                  width: double.infinity,
                  child: _AuthorHeader(
                    item: widget.item,
                    onDeleted: () {
                      if (!mounted) return;
                      setState(() => _deletedLocally = true);
                    },
                  ),
                ),
              ),

              SizedBox(height: 10),

              MediaDoubleTapLike(
                onDoubleTapLike: () {
                  final bloc = context.read<PostInteractionsBloc>();
                  final liked = bloc.likedByMe(
                    widget.item.id,
                    widget.item.likedByMe,
                  );
                  if (liked) return;
                  bloc.add(
                    ToggleLike(
                      postId: widget.item.id,
                      currentLikedByMe: liked,
                      currentLikesCount: bloc.likesCount(
                        widget.item.id,
                        widget.item.likesCount,
                      ),
                    ),
                  );
                },
                child: Container(
                  color: c.mediaSurface,
                  child: AspectRatio(
                    aspectRatio: _mediaAspect ?? 1,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: controller,
                          physics: const SnappyPageScrollPhysics(),
                          itemCount: (widget.item).mediaUrls.length,
                          itemBuilder: (context, index) {
                            final FeedMediaItem mediaItem =
                                (widget.item).mediaUrls[index];
                            return Builder(
                              builder: (context) {
                                if (widget.item.mediaUrls[index].type ==
                                    'video') {
                                  final vc = videos[index]?.controller;
                                  if (vc == null || !vc.value.isInitialized) {
                                    final poster = mediaItem.thumbnailUrl;
                                    if (poster != null && poster.isNotEmpty) {
                                      return CachedNetworkImage(
                                        imageUrl: poster,
                                        fit: BoxFit.cover,
                                        memCacheWidth: imgWidth,
                                        errorWidget: (context, url, error) =>
                                            Container(color: c.mediaSurface),
                                      );
                                    }
                                    return Container(
                                      color: c.mediaSurface,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            TablerIcons.player_play_filled,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      if (vc.value.isPlaying) {
                                        _manuallyPaused.add(index);
                                        vc.pause();
                                      } else {
                                        _manuallyPaused.remove(index);
                                        vc.play();
                                      }
                                      setState(() {});
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        VideoPlayer(vc),
                                        if (_manuallyPaused.contains(index))
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                TablerIcons.player_play_filled,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }
                                if (mediaItem.type == 'image') {
                                  return PinchZoom(
                                    child: CachedNetworkImage(
                                      imageUrl: mediaItem.url.toString(),
                                      fit: BoxFit.cover,
                                      memCacheWidth: imgWidth,
                                      placeholder: (context, url) => Shimmer(
                                        duration: const Duration(
                                          milliseconds: 900,
                                        ),
                                        color: c.surfaceMuted,
                                        child: Container(color: c.surface),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: c.mediaSurface,
                                            child: Icon(
                                              Icons.error_outline,
                                              color: c.danger,
                                            ),
                                          ),
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            );
                          },
                        ),

                        (widget.item).mediaUrls.length > 1
                            ? Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: SmoothPageIndicator(
                                    controller: controller,
                                    count: (widget.item).mediaUrls.length,
                                    effect: WormEffect(
                                      dotColor: c.onMediaSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                      activeDotColor: c.onMediaSurface,
                                      dotHeight: 8,
                                      dotWidth: 8,
                                    ),
                                    onDotClicked: (index) {},
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),

              widget.item.caption != null && widget.item.caption!.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      margin: EdgeInsets.only(top: 10, bottom: 5),
                      child: MentionedCaption(
                        caption: widget.item.caption,
                        baseStyle: TextStyle(
                          color: c.onSurface,
                        ),
                        onMentionTap: (handle, _) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProfilePageWrapper(username: handle),
                            ),
                          );
                        },
                      ),
                    )
                  : SizedBox(height: 5),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: .end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          TablerIcons.heart_filled,
                          color: Colors.red,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        PostLikesCountText(
                          postId: widget.item.id,
                          initialLikesCount: widget.item.likesCount,
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    PostCommentsCountText(
                      postId: widget.item.id,
                      initialCommentsCount: widget.item.commentsCount,
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      builder: (n) => LocaleKeys.post_comments_count.tr(
                        namedArgs: {'n': '$n'},
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 5),

              WaveDivider(color: c.divider, padding: EdgeInsets.zero, thickness: 1, waveHeight: 1),

              Row(
                mainAxisAlignment: .start,
                crossAxisAlignment: .center,
                children: [
                  PostLikeButton(
                    postId: widget.item.id,
                    initialLikedByMe: widget.item.likedByMe,
                    initialLikesCount: widget.item.likesCount,
                  ),
                  IconButton(
                    onPressed: () => showCommentsBottomSheet(
                      context: context,
                      postId: widget.item.id,
                      initialCommentsCount: widget.item.commentsCount,
                    ),
                    icon: Icon(TablerIcons.message, color: c.onSurface),
                  ),
                  IconButton(
                    onPressed: () => openShareSheet(
                      context,
                      resourceType: SharedResourceType.post,
                      resourceId: widget.item.id,
                      headlineLabel: LocaleKeys.post_share_headline.tr(),
                    ),
                    icon: Icon(TablerIcons.send, color: c.onSurface),
                  ),
                  Spacer(),
                  if (widget.item.isProduct && widget.item.price != null)
                    ProductOrderCta(
                      postId: widget.item.id,
                      price: widget.item.price!,
                      currency: widget.item.priceCurrency ?? 'IQD',
                      venueName: widget.item.authorVenueName,
                      productCaption: widget.item.caption,
                    ),
                  SizedBox(width: 10),
                ],
              ),
              if (widget.item.authorVenueId != null) ...[
                if (widget.item.isProduct) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ShopProductsButton(
                      venueId: widget.item.authorVenueId!,
                      venueName: widget.item.authorVenueName,
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else if (!widget.item.authorVenueOnlineOnly) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: HangoutHereButton(
                      venueId: widget.item.authorVenueId!,
                      venueName: widget.item.authorVenueName,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              SizedBox(height: 15),
              WaveDivider(color: c.onSurface, padding: EdgeInsets.zero, thickness: 1, waveHeight: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  final PostFeedItem item;
  final VoidCallback onDeleted;

  const _AuthorHeader({required this.item, required this.onDeleted});

  bool get _isVenue => item.authorVenueId != null;

  String _displayNameFor(BuildContext context) {
    if (_isVenue) {
      return context.pickBilingual(
        ar: item.authorVenueNameAr,
        en: item.authorVenueNameEn,
        fallback: item.authorVenueName ?? '',
      );
    }
    return (item.authorDisplayName?.isNotEmpty == true
            ? item.authorDisplayName
            : item.authorUsername) ??
        '';
  }

  String? get _handle => _isVenue ? null : item.authorUsername;

  String? get _imageUrl =>
      _isVenue ? item.authorVenueLogoUrl : item.authorAvatarUrl;

  void _onTap(BuildContext context) {
    if (_isVenue) {
      final id = item.authorVenueId;
      if (id == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VenuePageWrapper(venueId: id)),
      );
    } else {
      final handle = item.authorUsername;
      if (handle == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePageWrapper(username: handle)),
      );
    }
  }

  void _onLongPress(BuildContext context) {
    showAuthorPreviewPopup(
      context,
      imageUrl: _imageUrl,
      name: _displayNameFor(context),
      subtitle: _isVenue ? null : _handle == null ? null : '@$_handle',
      rolePill: _isVenue ? LocaleKeys.hangout_role_pill_venue.tr() : null,
      isVenue: _isVenue,
      onOpenProfile: () => _onTap(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        InkWell(
          onTap: () => _onTap(context),
          onLongPress: () => _onLongPress(context),
          customBorder: _isVenue
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              : const CircleBorder(),
          child: _AuthorAvatar(url: _imageUrl, isVenue: _isVenue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => _onTap(context),
            onLongPress: () => _onLongPress(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayNameFor(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.onSurface,
                  ),
                ),
                if (_handle != null)
                  Text(_handle!, style: TextStyle(color: c.onSurface)),
                Text(
                  formatRelativeTime(item.createdAt),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            final result = await showPostActionsSheet(
              context,
              postId: item.id,
              isMine: _isMyPost(context, item),
              venueId: item.authorVenueId,
            );
            if (result == PostActionResult.deleted) onDeleted();
          },
          icon: Icon(TablerIcons.dots_vertical, color: c.onSurface),
        ),
      ],
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String? url;
  final bool isVenue;
  const _AuthorAvatar({required this.url, required this.isVenue});

  @override
  Widget build(BuildContext context) {
    const size = 45.0;
    if (!isVenue) {
      return SizedBox(
        width: size,
        height: size,
        child: UserAvatar(avatarUrl: url ?? ''),
      );
    }
    final c = context.c;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: c.surfaceMuted,
      ),
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(
                TablerIcons.building_store,
                color: c.onSurfaceSecondary,
                size: 22,
              ),
            )
          : Icon(
              TablerIcons.building_store,
              color: c.onSurfaceSecondary,
              size: 22,
            ),
    );
  }
}
