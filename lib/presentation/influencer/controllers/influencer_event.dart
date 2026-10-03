part of 'influencer_bloc.dart';

sealed class InfluencerEvent {
  const InfluencerEvent();
}

final class ToggleInfluencer extends InfluencerEvent {
  final bool enable;
  const ToggleInfluencer({required this.enable});
}
