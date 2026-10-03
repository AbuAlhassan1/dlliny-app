part of 'user_points_bloc.dart';

sealed class UserPointsEvent {}

final class LoadUserPoints extends UserPointsEvent {}

final class RefreshUserPoints extends UserPointsEvent {}

final class ClearUserPoints extends UserPointsEvent {}
