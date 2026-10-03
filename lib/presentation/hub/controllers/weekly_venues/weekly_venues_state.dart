part of 'weekly_venues_bloc.dart';

sealed class WeeklyVenuesState {
  const WeeklyVenuesState();
}

final class WeeklyVenuesInitial extends WeeklyVenuesState {
  const WeeklyVenuesInitial();
}

final class WeeklyVenuesLoading extends WeeklyVenuesState {
  const WeeklyVenuesLoading();
}

final class WeeklyVenuesLoaded extends WeeklyVenuesState {
  final List<WeeklyRecommendationItem> items;
  final String weekStartsAt;
  final bool isFallback;

  final bool isRefreshing;
  const WeeklyVenuesLoaded({
    required this.items,
    required this.weekStartsAt,
    required this.isFallback,
    this.isRefreshing = false,
  });
}

final class WeeklyVenuesEmpty extends WeeklyVenuesState {
  const WeeklyVenuesEmpty();
}

final class WeeklyVenuesError extends WeeklyVenuesState {
  const WeeklyVenuesError();
}
