import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/data/repositories/memory_upload_repository.dart';
import 'package:hangout/presentation/memory/bloc/memory_composer/memory_composer_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/memory/widgets/composer/post_as_picker.dart';
import 'package:video_player/video_player.dart';

class VideoMemoryComposerPage extends StatelessWidget {
  final File video;
  const VideoMemoryComposerPage({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryComposerBloc>(
      create: (_) => MemoryComposerBloc(
        repository: serviceLocator.get<MemoryRepository>(),
        uploader: serviceLocator.get<MemoryUploadRepository>(),
        mode: MemoryComposerMode.video,
        initialVideo: video,
      ),
      child: _ComposerSurface(video: video),
    );
  }
}

class _ComposerSurface extends StatefulWidget {
  final File video;
  const _ComposerSurface({required this.video});

  @override
  State<_ComposerSurface> createState() => _ComposerSurfaceState();
}

class _ComposerSurfaceState extends State<_ComposerSurface> {
  VideoPlayerController? _controller;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.file(widget.video);
    try {
      await c.initialize();
    } catch (_) {
      await c.dispose();
      if (!mounted) return;
      setState(() => _initFailed = true);
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    await c.setLooping(true);
    await c.play();
    setState(() => _controller = c);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      c.value.isPlaying ? c.pause() : c.play();
    });
  }

  Future<void> _onPost() async {
    final c = _controller;
    final seconds = c == null || !c.value.isInitialized
        ? 1
        : c.value.duration.inSeconds.clamp(1, 60);
    context.read<MemoryComposerBloc>().add(
          PostRequested(videoDurationSeconds: seconds),
        );
  }

  void _onSuccess() {
    serviceLocator.get<MemoryTrayBloc>().add(TrayRefreshed());
    appToast.success('تم نشر القصة');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemoryComposerBloc, MemoryComposerState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case MemoryComposerStatus.success:
            _onSuccess();
          case MemoryComposerStatus.failure:
            appToast.error(state.errorMessage ?? 'تعذر نشر القصة');
          case _:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: context.c.background,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(onClose: () => Navigator.of(context).pop()),
              const PostAsPicker(),
              Expanded(
                child: GestureDetector(
                  onTap: _togglePlay,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: _PreviewBody(
                      controller: _controller,
                      initFailed: _initFailed,
                    ),
                  ),
                ),
              ),
              _PostBar(onPost: _onPost, hasController: _controller != null),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(TablerIcons.x, color: c.onSurface),
            onPressed: onClose,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(TablerIcons.typography, color: c.onSurfaceDisabled),
            tooltip: 'متاحة للصور فقط',
            onPressed: null,
          ),
          IconButton(
            icon: Icon(TablerIcons.at, color: c.onSurfaceDisabled),
            tooltip: 'متاحة للصور فقط',
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool initFailed;
  const _PreviewBody({required this.controller, required this.initFailed});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    if (initFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.alert_triangle,
              color: t.onSurfaceDisabled,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تشغيل الفيديو',
              style: TextStyle(color: t.onSurfaceSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    final c = controller;
    if (c == null) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2, color: t.onSurface),
      );
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio == 0 ? 9 / 16 : c.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(c),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (_, value, _) {
              if (value.isPlaying) return const SizedBox.shrink();
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: t.scrimSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  TablerIcons.player_play,
                  color: t.onMediaSurface,
                  size: 28,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PostBar extends StatelessWidget {
  final VoidCallback onPost;
  final bool hasController;
  const _PostBar({required this.onPost, required this.hasController});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final busy = state.isBusy;
        final enabled = state.canPost && hasController && !busy;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: enabled ? onPost : null,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                disabledBackgroundColor: c.onSurfaceDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.onPrimary.withValues(alpha: 0.6),
                      ),
                    )
                  : const Icon(TablerIcons.send),
              label: Text(
                busy ? _busyLabel(state.status) : 'نشر القصة',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }

  String _busyLabel(MemoryComposerStatus status) {
    switch (status) {
      case MemoryComposerStatus.uploading:
        return 'جارٍ رفع الفيديو…';
      case MemoryComposerStatus.posting:
        return 'جارٍ النشر…';
      default:
        return 'جارٍ النشر…';
    }
  }
}
