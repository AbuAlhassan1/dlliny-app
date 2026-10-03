import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class AudioPickResult {
  final File file;
  final int durationSeconds;

  const AudioPickResult({required this.file, required this.durationSeconds});
}

Future<AudioPickResult?> pickAudioOverlay() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
    allowMultiple: false,
  );
  final path = result?.files.single.path;
  if (path == null) return null;

  final file = File(path);
  final player = AudioPlayer();
  Duration? duration;
  try {
    duration = await player.setFilePath(path);
  } catch (_) {
    duration = const Duration(seconds: 30);
  } finally {
    await player.dispose();
  }
  final seconds = (duration ?? const Duration(seconds: 30))
      .inSeconds
      .clamp(1, 60);

  return AudioPickResult(file: file, durationSeconds: seconds);
}
