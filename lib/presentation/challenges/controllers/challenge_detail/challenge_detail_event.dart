part of 'challenge_detail_bloc.dart';

sealed class ChallengeDetailEvent {
  const ChallengeDetailEvent();
}

final class LoadChallengeDetail extends ChallengeDetailEvent {
  final String challengeId;
  const LoadChallengeDetail(this.challengeId);
}

final class JoinCurrentChallenge extends ChallengeDetailEvent {
  const JoinCurrentChallenge();
}

final class RefreshChallengeDetail extends ChallengeDetailEvent {
  const RefreshChallengeDetail();
}
