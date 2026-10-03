import 'package:hangout/domain/dto/response/feed_response.dart';

sealed class ReelItem {
  const ReelItem();

  String get id;

  List<FeedMediaItem> get media;

  static ReelItem? from(Object parsed) {
    if (parsed is PostFeedItem) return PostReel(parsed);
    if (parsed is HangoutFeedItem) return HangoutReel(parsed);
    return null;
  }
}

final class PostReel extends ReelItem {
  final PostFeedItem post;
  const PostReel(this.post);

  @override
  String get id => 'post-${post.id}';

  @override
  List<FeedMediaItem> get media => post.mediaUrls;
}

final class HangoutReel extends ReelItem {
  final HangoutFeedItem hangout;
  const HangoutReel(this.hangout);

  @override
  String get id => 'hangout-${hangout.id}';

  @override
  List<FeedMediaItem> get media => hangout.media;
}
