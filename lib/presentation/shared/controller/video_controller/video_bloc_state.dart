part of 'video_bloc_bloc.dart';

@immutable
sealed class VideoBlocState {
  final bool isMuted;
  const VideoBlocState({this.isMuted = false});
}

final class VideoBlocInitial extends VideoBlocState {}
final class VideoToggledSound extends VideoBlocState {
  const VideoToggledSound({required super.isMuted});
}
