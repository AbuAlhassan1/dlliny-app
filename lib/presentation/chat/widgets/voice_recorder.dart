import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:hangout/presentation/chat/bloc/conversation/conversation_bloc.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';

class VoiceRecorderButton extends StatefulWidget {
  final MessageDisplayItem? replyTo;

  final Duration maxDuration;

  const VoiceRecorderButton({
    super.key,
    this.replyTo,
    this.maxDuration = const Duration(minutes: 2),
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  static const double _cancelThreshold = -90;

  final AudioRecorder _recorder = AudioRecorder();
  final List<double> _amplitudes = [];

  OverlayEntry? _overlay;
  Timer? _ticker;
  Timer? _maxDurationTimer;
  StreamSubscription<Amplitude>? _ampSub;
  Stopwatch? _stopwatch;
  String? _filePath;

  final ValueNotifier<_RecorderOverlayState> _overlayState = ValueNotifier(
    const _RecorderOverlayState(
      elapsed: Duration.zero,
      dragDx: 0,
      wouldCancel: false,
    ),
  );

  bool _isRecording = false;
  bool _wouldCancel = false;

  @override
  void dispose() {
    _abortRecording();
    _recorder.dispose();
    _overlayState.dispose();
    super.dispose();
  }

  String _platformMime() => Platform.isIOS ? 'audio/m4a' : 'audio/aac';

  Future<bool> _ensureMicPermission() async {
    var status = await Permission.microphone.status;
    log('mic perm (before request) = $status');
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      log('mic perm (after request)  = $status');
    }
    if (status.isGranted) return true;

    final recorderOk = await _recorder.hasPermission();
    log('record plugin hasPermission = $recorderOk');
    if (recorderOk) return true;

    if (!mounted) return false;
    appToast.error(
      LocaleKeys.chat_voice_permission_required_title.tr(),
      body: status.isPermanentlyDenied
          ? LocaleKeys.chat_voice_permission_open_settings_hint.tr()
          : null,
    );
    return false;
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    if (!await _ensureMicPermission()) {
      log('voice: aborted — permission check returned false');
      return;
    }
    if (!await _recorder.hasPermission()) {
      log('voice: aborted — recorder.hasPermission() returned false');
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final path =
        '${tmpDir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        numChannels: 1,
      ),
      path: path,
    );

    _filePath = path;
    _isRecording = true;
    _wouldCancel = false;
    _amplitudes.clear();
    _stopwatch = Stopwatch()..start();
    HapticFeedback.mediumImpact();

    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((a) {
      final db = a.current;
      final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
      _amplitudes.add(normalized);
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _overlayState.value = _overlayState.value.copyWith(
        elapsed: _stopwatch?.elapsed ?? Duration.zero,
      );
    });

    _maxDurationTimer = Timer(widget.maxDuration, () {
      if (_isRecording) _finishRecording(canceled: false);
    });

    _showOverlay();
  }

  void _onDragUpdate(double dx) {
    if (!_isRecording) return;
    final wouldCancel = dx < _cancelThreshold;
    if (wouldCancel != _wouldCancel) {
      _wouldCancel = wouldCancel;
      HapticFeedback.selectionClick();
    }
    _overlayState.value = _overlayState.value.copyWith(
      dragDx: dx,
      wouldCancel: wouldCancel,
    );
  }

  Future<void> _finishRecording({required bool canceled}) async {
    if (!_isRecording) return;
    _isRecording = false;
    _ticker?.cancel();
    _maxDurationTimer?.cancel();
    await _ampSub?.cancel();
    final elapsed = _stopwatch?.elapsed ?? Duration.zero;
    _stopwatch?.stop();

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    _removeOverlay();

    if (canceled || path == null) {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      } else if (_filePath != null) {
        try {
          await File(_filePath!).delete();
        } catch (_) {}
      }
      _filePath = null;
      return;
    }

    final seconds = elapsed.inSeconds.clamp(1, 60 * 60);
    final waveform = _downsampleAndEncode(_amplitudes, target: 50);
    final replyToId = widget.replyTo?.message.id;
    if (!mounted) return;
    context.read<ConversationBloc>().add(
          VoiceMessageSent(
            localFilePath: path,
            mimeType: _platformMime(),
            durationSeconds: seconds,
            waveformJson: waveform,
            replyToId: replyToId,
          ),
        );
  }

  Future<void> _abortRecording() async {
    if (!_isRecording) {
      _removeOverlay();
      return;
    }
    _isRecording = false;
    _ticker?.cancel();
    _maxDurationTimer?.cancel();
    await _ampSub?.cancel();
    _stopwatch?.stop();
    try {
      final path = await _recorder.stop();
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    } catch (_) {}
    _removeOverlay();
  }

  String _downsampleAndEncode(List<double> source, {required int target}) {
    if (source.isEmpty) return '[]';
    if (source.length <= target) return jsonEncode(source);
    final bucketSize = source.length / target;
    final out = <double>[];
    for (var i = 0; i < target; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor().clamp(start + 1, source.length);
      double maxV = 0;
      for (var j = start; j < end; j++) {
        if (source[j] > maxV) maxV = source[j];
      }
      out.add(double.parse(maxV.toStringAsFixed(3)));
    }
    return jsonEncode(out);
  }

  void _showOverlay() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _overlay = OverlayEntry(
      builder: (_) => _RecordingOverlay(state: _overlayState),
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
    _overlayState.value = const _RecorderOverlayState(
      elapsed: Duration.zero,
      dragDx: 0,
      wouldCancel: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _startRecording(),
      onLongPressMoveUpdate: (e) => _onDragUpdate(e.offsetFromOrigin.dx),
      onLongPressEnd: (_) => _finishRecording(canceled: _wouldCancel),
      onLongPressCancel: () => _abortRecording(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          TablerIcons.microphone,
          color: c.onSurface,
          size: 22,
        ),
      ),
    );
  }
}

class _RecorderOverlayState {
  final Duration elapsed;
  final double dragDx;
  final bool wouldCancel;
  const _RecorderOverlayState({
    required this.elapsed,
    required this.dragDx,
    required this.wouldCancel,
  });

  _RecorderOverlayState copyWith({
    Duration? elapsed,
    double? dragDx,
    bool? wouldCancel,
  }) {
    return _RecorderOverlayState(
      elapsed: elapsed ?? this.elapsed,
      dragDx: dragDx ?? this.dragDx,
      wouldCancel: wouldCancel ?? this.wouldCancel,
    );
  }
}

class _RecordingOverlay extends StatelessWidget {
  final ValueNotifier<_RecorderOverlayState> state;
  const _RecordingOverlay({required this.state});

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    final hundredths = (d.inMilliseconds.remainder(1000) ~/ 10);
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<_RecorderOverlayState>(
          valueListenable: state,
          builder: (context, value, _) {
            final cancel = value.wouldCancel;
            final slide = value.dragDx.clamp(-110.0, 0.0);
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: c.mediaSurface,
                  border: Border(
                    top: BorderSide(
                      color: c.onMediaSurface.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: cancel
                            ? c.onMediaSurface.withValues(alpha: 0.24)
                            : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _format(value.elapsed),
                      style: TextStyle(
                        color: c.onMediaSurface,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(slide, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              cancel ? TablerIcons.trash : TablerIcons.chevron_left,
                              color: cancel
                                  ? Colors.redAccent
                                  : c.onMediaSurface.withValues(alpha: 0.54),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (cancel
                                      ? LocaleKeys.chat_voice_deleted_indicator
                                      : LocaleKeys.chat_voice_drag_to_cancel)
                                  .tr(),
                              style: TextStyle(
                                color: cancel
                                    ? Colors.redAccent
                                    : c.onMediaSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
