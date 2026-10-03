import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/voice_playback_service.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';

class VoiceMessageContent extends StatefulWidget {
  final MessageDisplayItem item;
  final bool isMine;

  const VoiceMessageContent({
    super.key,
    required this.item,
    required this.isMine,
  });

  @override
  State<VoiceMessageContent> createState() => _VoiceMessageContentState();
}

class _VoiceMessageContentState extends State<VoiceMessageContent> {
  late final VoicePlaybackService _service =
      serviceLocator.get<VoicePlaybackService>();

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;

  bool _isPlaying = false;
  Duration _position = Duration.zero;

  late final List<double> _bars = _decodeWaveform(widget.item.message.audioWaveform);

  String get _messageId => widget.item.message.id;

  String? get _source =>
      widget.item.message.audioUrl ?? widget.item.localFilePath;

  Duration get _totalDuration => Duration(
        seconds: widget.item.message.audioDurationSeconds ?? 0,
      );

  @override
  void initState() {
    super.initState();
    _playingSub = _service.playingStream.listen((playing) {
      if (!mounted) return;
      final mine = _service.currentlyPlayingId == _messageId;
      setState(() => _isPlaying = mine && playing);
    });
    _positionSub = _service.positionStream.listen((pos) {
      if (!mounted) return;
      if (_service.currentlyPlayingId != _messageId) return;
      setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final src = _source;
    if (src == null) return;
    if (_isPlaying) {
      await _service.pauseIfPlaying(_messageId);
    } else {
      await _service.play(messageId: _messageId, source: src);
    }
  }

  Future<void> _seekTap(double fraction) async {
    if (_totalDuration == Duration.zero) return;
    if (_service.currentlyPlayingId != _messageId) return;
    final target = Duration(
      milliseconds: (_totalDuration.inMilliseconds * fraction).round(),
    );
    await _service.seekTo(_messageId, target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = widget.isMine ? c.onPrimary : c.onSurface;
    final progress = _totalDuration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _totalDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    final hasSource = _source != null;

    return SizedBox(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlayButton(
            isPlaying: _isPlaying,
            enabled: hasSource,
            color: fg,
            onTap: _togglePlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Waveform(
                  bars: _bars,
                  progress: progress,
                  color: fg,
                  onSeek: _seekTap,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_isPlaying ? _position : _totalDuration),
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<double> _decodeWaveform(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .map((v) => (v is num) ? v.toDouble().clamp(0.0, 1.0) : 0.0)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  const _PlayButton({
    required this.isPlaying,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isPlaying
                ? TablerIcons.player_pause_filled
                : TablerIcons.player_play_filled,
            size: 18,
            color: enabled ? color : color.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  final List<double> bars;
  final double progress;
  final Color color;
  final ValueChanged<double> onSeek;
  const _Waveform({
    required this.bars,
    required this.progress,
    required this.color,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final fraction =
                  (d.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
              onSeek(fraction);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, 28),
              painter: _WaveformPainter(
                bars: bars,
                progress: progress,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color color;
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }
    final barCount = bars.length;
    final gap = 2.0;
    final totalGap = gap * (barCount - 1);
    final barWidth = ((size.width - totalGap) / barCount).clamp(1.0, 4.0);
    final progressX = size.width * progress;
    final played = Paint()..color = color;
    final unplayed = Paint()..color = color.withValues(alpha: 0.35);

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final h = (bars[i].clamp(0.05, 1.0)) * size.height;
      final top = (size.height - h) / 2;
      final isPlayed = x + barWidth / 2 <= progressX;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barWidth, h),
          const Radius.circular(1.5),
        ),
        isPlayed ? played : unplayed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.bars.length != bars.length;
}
