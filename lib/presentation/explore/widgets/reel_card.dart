import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/explore/utils/pick_reel_cover.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_actions_chip.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_bottom_info.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_heart_burst.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_helpers.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_media.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_media_dots.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_scrim_layer.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/post/widgets/comments_bottom_sheet.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:video_player/video_player.dart';

class ReelCard extends StatefulWidget {
  final PostFeedItem post;

  final bool isActive;

  const ReelCard({
    super.key,
    required this.post,
    this.isActive = true,
  });

  @override
  State<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard>
    with SingleTickerProviderStateMixin {
  late bool _liked = widget.post.likedByMe;
  late int _likesCount = widget.post.likesCount;
  bool _likeInFlight = false;
  late final AnimationController _heartBurst;
  late final PageController _mediaController;
  final ValueNotifier<VideoPlayerController?> _activeVideo =
      ValueNotifier(null);
  final ReelApiService _api = ReelApiService();
  final ReelFormatter _format = ReelFormatter();

  String get _authorName {
    return widget.post.authorVenueName ??
        widget.post.authorDisplayName ??
        widget.post.authorUsername ??
        LocaleKeys.explore_author_fallback.tr();
  }

  String? get _authorAvatarUrl {
    return widget.post.authorVenueLogoUrl ?? widget.post.authorAvatarUrl;
  }

  bool get _isVenuePost => widget.post.authorVenueId != null;

  int get _initialIndex {
    final media = widget.post.mediaUrls;
    final cover = pickReelCover(media);
    if (cover == null) return 0;
    final idx = media.indexOf(cover);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    _heartBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _mediaController = PageController(initialPage: _initialIndex);
  }

  @override
  void dispose() {
    _heartBurst.dispose();
    _mediaController.dispose();
    _activeVideo.dispose();
    super.dispose();
  }

  void _onDoubleTapLike() {
    _heartBurst
      ..reset()
      ..forward();
    if (!_liked) _toggleLike();
  }

  void _openAuthor() {
    if (_isVenuePost) {
      final venueId = widget.post.authorVenueId;
      if (venueId == null || venueId.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenuePageWrapper(venueId: venueId),
        ),
      );
      return;
    }
    final username = widget.post.authorUsername;
    if (username == null || username.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePageWrapper(username: username),
      ),
    );
  }

  Future<void> _openComments() async {
    await showCommentsBottomSheet(
      context: context,
      postId: widget.post.id,
      initialCommentsCount: widget.post.commentsCount,
    );
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likesCount += wasLiked ? -1 : 1;
      _likeInFlight = true;
    });
    try {
      if (wasLiked) {
        await _api.unlike(widget.post.id);
      } else {
        await _api.like(widget.post.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
    } finally {
      if (mounted) setState(() => _likeInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelMedia(
          media: widget.post.mediaUrls,
          isActive: widget.isActive,
          controller: _mediaController,
          activeVideo: _activeVideo,
          sourceId: 'post-${widget.post.id}',
          onDoubleTapLike: _onDoubleTapLike,
        ),
        const ReelScrimLayer(),
        ReelHeartBurst(animation: _heartBurst),
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.post.mediaUrls.length > 1) ...[
                ReelMediaDots(
                  controller: _mediaController,
                  count: widget.post.mediaUrls.length,
                ),
                const SizedBox(height: 12),
              ],
              Center(
                child: ValueListenableBuilder<VideoPlayerController?>(
                  valueListenable: _activeVideo,
                  builder: (context, activeVideo, _) {
                    return BlocBuilder<PostInteractionsBloc,
                        PostInteractionsState>(
                      buildWhen: (_, curr) =>
                          curr is PostInteractionUpdated &&
                          curr.postId == widget.post.id,
                      builder: (context, _) {
                        final bloc = context.read<PostInteractionsBloc>();
                        return ReelActionsChip(
                          liked: _liked,
                          likesCount: _likesCount,
                          commentsCount: bloc.commentsCount(
                            widget.post.id,
                            widget.post.commentsCount,
                          ),
                          onLike: _toggleLike,
                          onComment: _openComments,
                          format: _format,
                          controller: activeVideo,
                        );
                      },
                    );
                  },
                ),
              ),
              ReelBottomInfo(
                authorName: _authorName,
                username: _isVenuePost ? null : widget.post.authorUsername,
                avatarUrl: _authorAvatarUrl,
                caption: widget.post.caption,
                isVenue: _isVenuePost,
                venueId: widget.post.authorVenueId,
                venueName: widget.post.authorVenueName,
                onAuthorTap: _openAuthor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
