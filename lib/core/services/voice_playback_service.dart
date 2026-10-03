import 'package:just_audio/just_audio.dart';

class VoicePlaybackService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentMessageId;

  String? get currentlyPlayingId => _currentMessageId;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Future<void> play({
    required String messageId,
    required String source,
  }) async {
    if (_currentMessageId == messageId && _player.playing) return;
    if (_currentMessageId == messageId &&
        _player.processingState != ProcessingState.idle) {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      return;
    }
    _currentMessageId = messageId;
    await _player.stop();
    if (source.startsWith('http')) {
      await _player.setUrl(source);
    } else {
      await _player.setFilePath(source);
    }
    await _player.play();
  }

  Future<void> pauseIfPlaying(String messageId) async {
    if (_currentMessageId == messageId && _player.playing) {
      await _player.pause();
    }
  }

  Future<void> seekTo(String messageId, Duration position) async {
    if (_currentMessageId == messageId) {
      await _player.seek(position);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
