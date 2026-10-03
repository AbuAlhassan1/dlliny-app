part of 'video_bloc_bloc.dart';

@immutable
sealed class VideoBlocEvent {
  final VideoPlayerController controller;
  const VideoBlocEvent({required this.controller});
}

class VideoToggleSoundEvent extends VideoBlocEvent {
  const VideoToggleSoundEvent({required super.controller});
}
