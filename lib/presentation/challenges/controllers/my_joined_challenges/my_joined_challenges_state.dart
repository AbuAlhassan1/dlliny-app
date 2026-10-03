part of 'my_joined_challenges_bloc.dart';

sealed class MyJoinedChallengesState {
  final List<ChallengeListItemResponse> items;
  const MyJoinedChallengesState({this.items = const []});
}

final class MyJoinedChallengesInitial extends MyJoinedChallengesState {
  const MyJoinedChallengesInitial();
}

final class MyJoinedChallengesLoading extends MyJoinedChallengesState {
  const MyJoinedChallengesLoading({super.items});
}

final class MyJoinedChallengesLoaded extends MyJoinedChallengesState {
  const MyJoinedChallengesLoaded({super.items});
}

final class MyJoinedChallengesError extends MyJoinedChallengesState {
  final String message;
  const MyJoinedChallengesError(this.message, {super.items});
}
