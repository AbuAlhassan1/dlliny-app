part of 'my_joined_challenges_bloc.dart';

sealed class MyJoinedChallengesEvent {
  const MyJoinedChallengesEvent();
}

final class LoadMyJoinedChallenges extends MyJoinedChallengesEvent {
  const LoadMyJoinedChallenges();
}
