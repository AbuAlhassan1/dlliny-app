part of 'hangout_details_bloc.dart';

sealed class HangoutDetailsState {}

final class HangoutDetailsInitial extends HangoutDetailsState {}

final class HangoutDetailsLoading extends HangoutDetailsState {}

final class HangoutDetailsLoaded extends HangoutDetailsState {
  final HangoutResponse hangout;
  final List<HangoutMediaResponse> media;

  final VenueResponse? venue;

  HangoutDetailsLoaded({
    required this.hangout,
    required this.media,
    this.venue,
  });
}

final class HangoutDetailsError extends HangoutDetailsState {
  final String message;
  HangoutDetailsError(this.message);
}
