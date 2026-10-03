part of 'challenges_list_bloc.dart';

sealed class ChallengesListEvent {
  const ChallengesListEvent();
}

final class LoadChallenges extends ChallengesListEvent {
  final ChallengeCadence? cadence;
  const LoadChallenges({this.cadence});
}
