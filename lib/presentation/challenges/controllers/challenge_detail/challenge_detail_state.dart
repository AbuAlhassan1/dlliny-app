part of 'challenge_detail_bloc.dart';

sealed class ChallengeDetailState {
  final ChallengeDetailResponse? detail;
  const ChallengeDetailState({this.detail});
}

final class ChallengeDetailInitial extends ChallengeDetailState {
  const ChallengeDetailInitial();
}

final class ChallengeDetailLoading extends ChallengeDetailState {
  const ChallengeDetailLoading({super.detail});
}

final class ChallengeDetailLoaded extends ChallengeDetailState {
  const ChallengeDetailLoaded({super.detail});
}

final class ChallengeDetailError extends ChallengeDetailState {
  final String message;
  const ChallengeDetailError(this.message, {super.detail});
}

final class ChallengeJoining extends ChallengeDetailState {
  const ChallengeJoining({super.detail});
}

final class ChallengeJoined extends ChallengeDetailState {
  const ChallengeJoined({super.detail});
}

final class ChallengeJoinError extends ChallengeDetailState {
  final String message;
  const ChallengeJoinError(this.message, {super.detail});
}
