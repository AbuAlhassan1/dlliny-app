import 'package:json_annotation/json_annotation.dart';

enum ChallengeKind {
  @JsonValue('PLATFORM')
  platform,
  @JsonValue('VENUE')
  venue,
}

enum ChallengeAudience {
  @JsonValue('ANY')
  any,
  @JsonValue('NORMAL_USERS')
  normalUsers,
  @JsonValue('INFLUENCERS')
  influencers,
}

enum ChallengeCadence {
  @JsonValue('DAILY')
  daily,
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('SEASONAL')
  seasonal,
  @JsonValue('SPECIAL')
  special,
}

enum ChallengeObjectiveType {
  @JsonValue('VISIT_BRANCH')
  visitBranch,
  @JsonValue('CREATE_HANGOUT')
  createHangout,
  @JsonValue('INVITE_FRIENDS')
  inviteFriends,
  @JsonValue('POST_COUNT')
  postCount,
  @JsonValue('MEMORY_COUNT')
  memoryCount,
  @JsonValue('FOLLOW_VENUE')
  followVenue,
  @JsonValue('REVIEW_VENUE')
  reviewVenue,
}

enum ChallengeProgressStatus {
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('EXPIRED')
  expired,
}
