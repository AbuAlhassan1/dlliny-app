import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:video_player/video_player.dart';

class PostVideoPlayerWrapper extends StatefulWidget {
  final String url;

  final String? streamUrl;

  const PostVideoPlayerWrapper({super.key, required this.url, this.streamUrl});

  @override
  State<PostVideoPlayerWrapper> createState() =>
      _PostVideoPlayerWrapperState();
}

class _PostVideoPlayerWrapperState extends State<PostVideoPlayerWrapper> {
  late final VideoPlayback _video;
  bool _manuallyPaused = false;

  @override
  void initState() {
    super.initState();
    _video = VideoSource.of(widget.url, streamUrl: widget.streamUrl).load(
      onReady: (c) async {
        if (!mounted) return;
        await c.setLooping(true);
        if (!mounted) return;
        if (!_manuallyPaused) await c.play();
        if (mounted) setState(() {});
      },
    );
    _video.controller.play();
  }

  @override
  void dispose() {
    _video.controller.pause();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = _video.controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (vc.value.isPlaying) {
          vc.pause();
          setState(() => _manuallyPaused = true);
        } else {
          vc.play();
          setState(() => _manuallyPaused = false);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(vc),
          if (_manuallyPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.player_play_filled,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
