part of 'influencer_bloc.dart';

sealed class InfluencerState {
  final bool enabled;
  const InfluencerState({required this.enabled});
}

final class InfluencerReady extends InfluencerState {
  const InfluencerReady({required super.enabled});
}

final class InfluencerUpdating extends InfluencerState {
  final bool target;
  const InfluencerUpdating({required super.enabled, required this.target});
}

final class InfluencerError extends InfluencerState {
  final String message;
  const InfluencerError(this.message, {required super.enabled});
}
