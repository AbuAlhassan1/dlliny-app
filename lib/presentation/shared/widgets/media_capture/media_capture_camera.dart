import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

class CapturedMedia {
  final File file;
  final CaptureAspectRatio aspect;
  final bool isVideo;
  const CapturedMedia({
    required this.file,
    required this.aspect,
    required this.isVideo,
  });
}

class MediaCaptureCamera extends StatefulWidget {
  final Duration maxVideoLength;

  final ValueChanged<CapturedMedia> onCaptured;

  final CaptureAspectRatio aspect;
  final ValueChanged<CaptureAspectRatio> onAspectChanged;

  final bool aspectLocked;

  final bool fullscreen;

  final List<CaptureAspectRatio>? ratios;

  const MediaCaptureCamera({
    super.key,
    required this.onCaptured,
    required this.aspect,
    required this.onAspectChanged,
    this.aspectLocked = false,
    this.fullscreen = false,
    this.maxVideoLength = const Duration(seconds: 120),
    this.ratios,
  });

  @override
  State<MediaCaptureCamera> createState() => MediaCaptureCameraState();
}

class MediaCaptureCameraState extends State<MediaCaptureCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initialized = false;
  CameraLensDirection _lens = CameraLensDirection.front;
  bool _recording = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordingTicker;
  Timer? _autoStopTimer;
  bool _initInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTicker?.cancel();
    _autoStopTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_recording) _stopVideoRecording();
      final c = _controller;
      if (c != null) {
        c.dispose();
        _controller = null;
        _initialized = false;
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null) _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_initInFlight) return;
    _initInFlight = true;
    try {
      final cameras = await availableCameras();
      final desired = cameras.firstWhere(
        (c) => c.lensDirection == _lens,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        desired,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (e) {
      if (mounted) appToast.error('تعذر فتح الكاميرا');
    } finally {
      _initInFlight = false;
    }
  }

  Future<void> _flipCamera() async {
    if (_recording) return;
    final next = _lens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final cameras = await availableCameras();
    final target = cameras.firstWhere(
      (c) => c.lensDirection == next,
      orElse: () => cameras.first,
    );
    try {
      await _controller?.setDescription(target);
      if (mounted) setState(() => _lens = next);
    } catch (_) {
      _lens = next;
      await _controller?.dispose();
      _controller = null;
      _initialized = false;
      if (mounted) setState(() {});
      await _initCamera();
    }
  }

  bool get isInitialized => _initialized;
  bool get isRecording => _recording;
  Duration get recordedDuration => _recordedDuration;
  Future<void> takePicture() => _takePicture();
  Future<void> startVideoRecording() => _startVideoRecording();
  Future<void> stopVideoRecording() => _stopVideoRecording();

  Future<void> _takePicture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) {
      return;
    }
    try {
      HapticFeedback.lightImpact();
      final picture = await c.takePicture();
      if (!mounted) return;
      widget.onCaptured(CapturedMedia(
        file: File(picture.path),
        aspect: widget.aspect,
        isVideo: false,
      ));
    } catch (_) {
      if (mounted) appToast.error('تعذر التقاط الصورة');
    }
  }

  Future<void> _startVideoRecording() async {
    final c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        c.value.isRecordingVideo ||
        _recording) {
      return;
    }
    try {
      HapticFeedback.mediumImpact();
      await c.startVideoRecording();
      _recordedDuration = Duration.zero;
      _recordingTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _recordedDuration += const Duration(milliseconds: 100);
        });
      });
      _autoStopTimer = Timer(widget.maxVideoLength, _stopVideoRecording);
      if (mounted) setState(() => _recording = true);
    } catch (_) {
      if (mounted) appToast.error('تعذر بدء التسجيل');
    }
  }

  Future<void> _stopVideoRecording() async {
    final c = _controller;
    if (c == null || !c.value.isRecordingVideo) {
      _recording = false;
      return;
    }
    _recordingTicker?.cancel();
    _autoStopTimer?.cancel();
    try {
      final video = await c.stopVideoRecording();
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recordedDuration = Duration.zero;
      });
      widget.onCaptured(CapturedMedia(
        file: File(video.path),
        aspect: widget.aspect,
        isVideo: true,
      ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _recordedDuration = Duration.zero;
        });
        appToast.error('تعذر إيقاف التسجيل');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullscreen) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _Preview(
            controller: _controller,
            initialized: _initialized,
            aspect: widget.aspect,
            onFlip: _flipCamera,
            recording: _recording,
            recordedDuration: _recordedDuration,
            fillParent: true,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                child: Center(
                  child: MediaCaptureButton(
                    enabled: _initialized,
                    recording: _recording,
                    recordedDuration: _recordedDuration,
                    maxLength: widget.maxVideoLength,
                    onTap: _takePicture,
                    onHoldStart: _startVideoRecording,
                    onHoldEnd: _stopVideoRecording,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AspectRatioPicker(
            current: widget.aspect,
            locked: widget.aspectLocked,
            ratios: widget.ratios,
            onChanged: (next) {
              if (_recording) return;
              widget.onAspectChanged(next);
            },
          ),
        ),
        _Preview(
          controller: _controller,
          initialized: _initialized,
          aspect: widget.aspect,
          onFlip: _flipCamera,
          recording: _recording,
          recordedDuration: _recordedDuration,
        ),
        const SizedBox(height: 14),
        MediaCaptureButton(
          enabled: _initialized,
          recording: _recording,
          recordedDuration: _recordedDuration,
          maxLength: widget.maxVideoLength,
          onTap: _takePicture,
          onHoldStart: _startVideoRecording,
          onHoldEnd: _stopVideoRecording,
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final CameraController? controller;
  final bool initialized;
  final CaptureAspectRatio aspect;
  final VoidCallback onFlip;
  final bool recording;
  final Duration recordedDuration;

  final bool fillParent;

  const _Preview({
    required this.controller,
    required this.initialized,
    required this.aspect,
    required this.onFlip,
    required this.recording,
    required this.recordedDuration,
    this.fillParent = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = fillParent ? constraints.maxHeight : width / aspect.ratio;
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius:
                fillParent ? BorderRadius.zero : BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              if (initialized && controller != null)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller!.value.previewSize?.height ?? 1,
                      height: controller!.value.previewSize?.width ?? 1,
                      child: CameraPreview(controller!),
                    ),
                  ),
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 1,
                  ),
                ),

              PositionedDirectional(
                bottom: 8,
                end: 8,
                child: Opacity(
                  opacity: recording ? 0.4 : 1.0,
                  child: IconButton(
                    onPressed: recording ? null : onFlip,
                    icon: const Icon(
                      TablerIcons.refresh,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              if (recording)
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(recordedDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class MediaCaptureButton extends StatelessWidget {
  final bool enabled;
  final bool recording;
  final Duration recordedDuration;
  final Duration maxLength;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const MediaCaptureButton({
    super.key,
    required this.enabled,
    required this.recording,
    required this.recordedDuration,
    required this.maxLength,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final progress = maxLength.inMilliseconds == 0
        ? 0.0
        : (recordedDuration.inMilliseconds / maxLength.inMilliseconds)
            .clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      onLongPressStart: enabled ? (_) => onHoldStart() : null,
      onLongPressEnd: enabled ? (_) => onHoldEnd() : null,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: recording
                  ? CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: c.onSurface.withValues(alpha: 0.24),
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.red),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                    ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: recording ? 28 : 56,
              height: recording ? 28 : 56,
              decoration: BoxDecoration(
                color: recording ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(recording ? 6 : 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$mm:$ss';
}
