import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_details_actions_row.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_details_comment_composer.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_details_comments_sliver.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_details_header.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_details_likes_count.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/widgets/post_video_player_wrapper.dart';
import 'package:hangout/presentation/post/controllers/comments/comments_bloc.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/post/widgets/comments_bottom_sheet.dart';
import 'package:hangout/presentation/post/widgets/media_double_tap_like.dart';
import 'package:hangout/presentation/post/widgets/mentioned_caption.dart';
import 'package:hangout/presentation/post/widgets/venue_tags_chip.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostDetailsPageWrapper extends StatelessWidget {
  final PostResponse post;
  const PostDetailsPageWrapper({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentsBloc()..add(GetComments(post.id)),
      child: _PostDetailsView(post: post),
    );
  }
}

class _PostDetailsView extends StatefulWidget {
  final PostResponse post;
  const _PostDetailsView({required this.post});

  @override
  State<_PostDetailsView> createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<_PostDetailsView> {
  final ScrollController _scroll = ScrollController();
  final PageController _mediaController = PageController();
  final TextEditingController _commentInput = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  double? _mediaAspect;

  @override
  void initState() {
    super.initState();
    _resolveFirstMediaAspect();
    _scroll.addListener(_maybeFetchMore);
  }

  void _resolveFirstMediaAspect() {
    if (widget.post.media.isEmpty) return;
    final ar = widget.post.media.first.aspectRatio;
    if (ar != null && ar.isFinite && ar > 0) {
      _mediaAspect = ar;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _mediaController.dispose();
    _commentInput.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _maybeFetchMore() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<CommentsBloc>().add(GetMoreComments(widget.post.id));
    }
  }

  void _sendComment() {
    final text = _commentInput.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<CommentsBloc>();
    bloc.add(AddComment(
      postId: widget.post.id,
      body: text,
      parentCommentId: bloc.replyTarget?.parentCommentId,
    ));
    _commentInput.clear();
    FocusScope.of(context).unfocus();
  }

  void _startReply(String parentCommentId, String authorUsername) {
    context.read<CommentsBloc>().add(SetReplyTarget(
          parentCommentId: parentCommentId,
          authorUsername: authorUsername,
        ));
    _commentFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(
                    child: PostDetailsHeader(post: widget.post),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: _buildMedia(context)),
                  SliverToBoxAdapter(
                    child: PostDetailsActionsRow(post: widget.post),
                  ),
                  SliverToBoxAdapter(
                    child: PostDetailsLikesCount(post: widget.post),
                  ),
                  if (widget.post.venueMentions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        child: VenueTagsChip(
                          venueMentions: widget.post.venueMentions,
                          backgroundColor: c.surfaceMuted,
                          foregroundColor: c.onSurface,
                          onVenueTap: (v) {},
                        ),
                      ),
                    ),
                  if (widget.post.caption != null &&
                      widget.post.caption!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        child: MentionedCaption(
                          caption: widget.post.caption,
                          userMentions: widget.post.userMentions,
                          baseStyle: TextStyle(color: c.onSurface),
                          mentionStyle: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                          onMentionTap: (handle, resolved) {
                            final username = resolved?.username ?? handle;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfilePageWrapper(username: username),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Divider(color: c.divider, height: 24),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: Text(
                        LocaleKeys.post_comments_sheet_title.tr(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  PostDetailsCommentsSliver(
                    postId: widget.post.id,
                    onStartReply: _startReply,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.divider),
            const CommentsReplyBanner(),
            Padding(
              padding: EdgeInsets.only(bottom: viewInsets),
              child: PostDetailsCommentComposer(
                controller: _commentInput,
                focusNode: _commentFocus,
                onSend: _sendComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    final c = context.c;
    return MediaDoubleTapLike(
      onDoubleTapLike: () {
        final bloc = context.read<PostInteractionsBloc>();
        final liked = bloc.likedByMe(widget.post.id, widget.post.likedByMe);
        if (liked) return;
        bloc.add(ToggleLike(
          postId: widget.post.id,
          currentLikedByMe: liked,
          currentLikesCount: bloc.likesCount(
            widget.post.id,
            widget.post.likesCount,
          ),
        ));
      },
      child: Container(
        color: c.mediaSurface,
        child: AspectRatio(
          aspectRatio: _mediaAspect ?? 1,
          child: Stack(
            children: [
              PageView.builder(
                controller: _mediaController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.post.media.length,
                itemBuilder: (context, index) {
                  final media = widget.post.media[index];
                  if (media.mediaType == 'video') {
                    return PostVideoPlayerWrapper(
                      url: media.url,
                      streamUrl: media.streamUrl,
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: media.url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) =>
                        Container(color: c.mediaSurface),
                  );
                },
              ),
              if (widget.post.media.length > 1)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SmoothPageIndicator(
                      controller: _mediaController,
                      count: widget.post.media.length,
                      effect: WormEffect(
                        dotColor:
                            c.onMediaSurface.withValues(alpha: 0.5),
                        activeDotColor: c.onMediaSurface,
                        dotHeight: 8,
                        dotWidth: 8,
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
