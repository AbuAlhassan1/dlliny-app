import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoView extends StatefulWidget {
  final VideoPlayerController _controller;
  const VideoView({super.key, required VideoPlayerController controller})
    : _controller = controller;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget._controller.value.isInitialized
      ? SizedBox(
        height: widget._controller.value.size.height, width: widget._controller.value.size.width,
        child: VideoPlayer(widget._controller)
      )
      : SizedBox();
  }
}
