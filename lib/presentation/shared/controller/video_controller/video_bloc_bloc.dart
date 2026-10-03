import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

part 'video_bloc_event.dart';
part 'video_bloc_state.dart';

class VideoBloc extends Bloc<VideoBlocEvent, VideoBlocState> {
  VideoBloc() : super(VideoBlocInitial()) {
    on<VideoBlocEvent>((event, emit) {});

    on<VideoToggleSoundEvent>((event, emit) async {
      await event.controller.setVolume(event.controller.value.volume > 0 ? 0 : 1);
      if ( event.controller.value.volume > 0) {
        emit(VideoToggledSound(isMuted: false));
      } else if (event.controller.value.volume == 0) {
        emit(VideoToggledSound(isMuted: true));
      }

    },);
  }
}
