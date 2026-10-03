import 'package:hangout/domain/dto/response/feed_response.dart';

const double _reelMinAspect = 0.55;
const double _reelMaxAspect = 0.58;

bool _isReelAspect(double? ratio) {
  if (ratio == null) return false;
  return ratio >= _reelMinAspect && ratio <= _reelMaxAspect;
}

FeedMediaItem? pickReelCover(List<FeedMediaItem> media) {
  FeedMediaItem? strictVerticalVideo;
  FeedMediaItem? strictVerticalImage;
  FeedMediaItem? fallbackVideo;
  FeedMediaItem? fallbackImage;
  for (final m in media) {
    final inBand = _isReelAspect(m.aspectRatio);
    if (m.type == 'video') {
      fallbackVideo ??= m;
      if (inBand) strictVerticalVideo ??= m;
    } else if (m.type == 'image') {
      fallbackImage ??= m;
      if (inBand) strictVerticalImage ??= m;
    }
  }
  return strictVerticalVideo ??
      strictVerticalImage ??
      fallbackVideo ??
      fallbackImage;
}
