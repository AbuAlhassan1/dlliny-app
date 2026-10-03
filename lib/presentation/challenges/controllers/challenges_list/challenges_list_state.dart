part of 'challenges_list_bloc.dart';

sealed class ChallengesListState {
  final Map<ChallengeCadence?, List<ChallengeListItemResponse>> byCadence;
  const ChallengesListState({this.byCadence = const {}});
}

final class ChallengesListInitial extends ChallengesListState {
  const ChallengesListInitial();
}

final class ChallengesListLoading extends ChallengesListState {
  final ChallengeCadence? cadence;
  const ChallengesListLoading({required this.cadence, super.byCadence});
}

final class ChallengesListLoaded extends ChallengesListState {
  final ChallengeCadence? cadence;
  const ChallengesListLoaded({required this.cadence, super.byCadence});
}

final class ChallengesListError extends ChallengesListState {
  final ChallengeCadence? cadence;
  final String message;
  const ChallengesListError({
    required this.cadence,
    required this.message,
    super.byCadence,
  });
}
