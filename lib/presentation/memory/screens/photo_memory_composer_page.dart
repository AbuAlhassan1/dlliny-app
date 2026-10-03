import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/data/repositories/memory_upload_repository.dart';
import 'package:hangout/domain/dto/request/create_memory_request.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/presentation/memory/bloc/memory_composer/memory_composer_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/memory/widgets/composer/audio_picker.dart';
import 'package:hangout/presentation/memory/widgets/composer/composer_overlay.dart';
import 'package:hangout/presentation/memory/widgets/composer/draggable_overlay_layer.dart';
import 'package:hangout/presentation/memory/widgets/composer/engagement_editor_sheet.dart';
import 'package:hangout/presentation/memory/widgets/composer/mention_picker_sheet.dart';
import 'package:hangout/presentation/memory/widgets/composer/post_as_picker.dart';
import 'package:hangout/presentation/memory/widgets/composer/text_editor_sheet.dart';
import 'package:path_provider/path_provider.dart';

class PhotoMemoryComposerPage extends StatelessWidget {
  final File photo;
  const PhotoMemoryComposerPage({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryComposerBloc>(
      create: (_) => MemoryComposerBloc(
        repository: serviceLocator.get<MemoryRepository>(),
        uploader: serviceLocator.get<MemoryUploadRepository>(),
        mode: MemoryComposerMode.photo,
        initialPhoto: photo,
      ),
      child: _ComposerSurface(photo: photo),
    );
  }
}

class _ComposerSurface extends StatefulWidget {
  final File photo;
  const _ComposerSurface({required this.photo});

  @override
  State<_ComposerSurface> createState() => _ComposerSurfaceState();
}

class _ComposerSurfaceState extends State<_ComposerSurface> {
  final GlobalKey _canvasKey = GlobalKey();

  int _nextOverlayId = 0;

  double? _photoAspect;

  String _newOverlayId() => 'ovl-${_nextOverlayId++}';

  @override
  void initState() {
    super.initState();
    _resolvePhotoAspect();
  }

  void _resolvePhotoAspect() {
    final stream = FileImage(widget.photo).resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        stream.removeListener(listener);
        if (!mounted || w <= 0 || h <= 0) return;
        setState(() => _photoAspect = w / h);
      },
      onError: (_, _) {
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  Future<({File file, Size size})?> _captureCanvas() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final size = Size(image.width.toDouble(), image.height.toDouble());
      final bytes =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return null;

      final tmp = await getTemporaryDirectory();
      final out = File(
        '${tmp.path}/memory_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(bytes.buffer.asUint8List());
      return (file: out, size: size);
    } catch (_) {
      return null;
    }
  }

  Size? _logicalCanvasSize() {
    final ctx = _canvasKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    return box?.size;
  }

  Future<void> _onPost() async {
    final canvas = _logicalCanvasSize();
    final captured = await _captureCanvas();
    if (!mounted) return;
    context.read<MemoryComposerBloc>().add(
          PostRequested(
            compositedPhoto: captured?.file,
            canvasSize: canvas,
          ),
        );
  }

  Future<void> _addTextOverlay() async {
    final result = await showTextOverlayEditor(context);
    if (result == null || !mounted) return;
    final canvas = _logicalCanvasSize() ?? const Size(360, 640);
    context.read<MemoryComposerBloc>().add(
          OverlayAdded(
            TextOverlay(
              id: _newOverlayId(),
              position: Offset(
                canvas.width / 2 - 80,
                canvas.height / 2 - 20,
              ),
              scale: 1.0,
              rotation: 0,
              text: result.text,
              color: result.color,
            ),
          ),
        );
  }

  Future<void> _addMention() async {
    final pick = await showMentionPicker(context);
    if (pick == null || !mounted) return;
    final canvas = _logicalCanvasSize() ?? const Size(360, 640);
    context.read<MemoryComposerBloc>().add(
          OverlayAdded(
            MentionOverlay(
              id: _newOverlayId(),
              position: Offset(
                canvas.width / 2 - 60,
                canvas.height / 2 - 14,
              ),
              scale: 1.0,
              rotation: 0,
              type: pick.type,
              mentionId: pick.id,
              label: pick.label,
            ),
          ),
        );
  }

  Future<void> _addOrReplaceAudio() async {
    final result = await pickAudioOverlay();
    if (result == null || !mounted) return;
    context.read<MemoryComposerBloc>().add(
          AudioOverlayPicked(
            file: result.file,
            durationSeconds: result.durationSeconds,
          ),
        );
  }

  Future<void> _addOrEditEngagement() async {
    final existing =
        context.read<MemoryComposerBloc>().state.engagement;
    final next = await showEngagementEditor(context, initial: existing);
    if (next == null || !mounted) return;
    context.read<MemoryComposerBloc>().add(EngagementConfigured(next));
  }

  void _onSuccess(File? compositedFile) {
    serviceLocator.get<MemoryTrayBloc>().add(TrayRefreshed());
    appToast.success('تم نشر القصة');
    final tmp = compositedFile;
    if (tmp != null) {
      tmp.delete().catchError((_) => tmp);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemoryComposerBloc, MemoryComposerState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case MemoryComposerStatus.success:
            _onSuccess(state.photoFile);
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
              _TopBar(
                onAddText: _addTextOverlay,
                onAddMention: _addMention,
                onAddAudio: _addOrReplaceAudio,
                onAddEngagement: _addOrEditEngagement,
              ),
              const PostAsPicker(),
              Expanded(
                child: ColoredBox(
                  color: context.c.mediaSurface,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _photoAspect ?? (9 / 16),
                      child: RepaintBoundary(
                        key: _canvasKey,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                widget.photo,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const Positioned.fill(
                              child: DraggableOverlayLayer(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const _AttachmentChips(),
              const _Hint(),
              _PostBar(onPost: _onPost),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddMention;
  final VoidCallback onAddAudio;
  final VoidCallback onAddEngagement;

  const _TopBar({
    required this.onAddText,
    required this.onAddMention,
    required this.onAddAudio,
    required this.onAddEngagement,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) =>
          prev.audioFile != curr.audioFile ||
          prev.engagement != curr.engagement,
      builder: (context, state) {
        final hasAudio = state.audioFile != null;
        final hasEngagement = state.engagement != null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(TablerIcons.x, color: c.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(TablerIcons.typography, color: c.onSurface),
                tooltip: 'إضافة نص',
                onPressed: onAddText,
              ),
              IconButton(
                icon: Icon(TablerIcons.at, color: c.onSurface),
                tooltip: 'إشارة',
                onPressed: onAddMention,
              ),
              IconButton(
                icon: Icon(
                  TablerIcons.music,
                  color: hasAudio ? c.onSurface : c.onSurfaceSecondary,
                ),
                tooltip: 'موسيقى',
                onPressed: onAddAudio,
              ),
              IconButton(
                icon: Icon(
                  TablerIcons.chart_bar,
                  color: hasEngagement ? c.onSurface : c.onSurfaceSecondary,
                ),
                tooltip: 'عنصر تفاعلي',
                onPressed: onAddEngagement,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentChips extends StatelessWidget {
  const _AttachmentChips();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) =>
          prev.audioFile != curr.audioFile ||
          prev.engagement != curr.engagement,
      builder: (context, state) {
        final hasAudio = state.audioFile != null;
        final hasEngagement = state.engagement != null;
        if (!hasAudio && !hasEngagement) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Wrap(
            spacing: 8,
            children: [
              if (hasAudio)
                _AttachmentChip(
                  icon: TablerIcons.music,
                  label: 'موسيقى (${state.audioDurationSeconds ?? 0} ث)',
                  onRemove: () => context
                      .read<MemoryComposerBloc>()
                      .add(AudioOverlayRemoved()),
                ),
              if (hasEngagement)
                _AttachmentChip(
                  icon: TablerIcons.chart_bar,
                  label: _engagementLabel(state.engagement!),
                  onRemove: () => context
                      .read<MemoryComposerBloc>()
                      .add(EngagementRemoved()),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _engagementLabel(EngagementConfig cfg) {
    switch (cfg.type) {
      case MemoryEngagementType.poll:
        return 'استطلاع';
      case MemoryEngagementType.question:
        return 'سؤال';
      case MemoryEngagementType.slider:
        return 'منزلق';
      case MemoryEngagementType.quiz:
        return 'اختبار';
    }
  }
}

class _AttachmentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onRemove;
  const _AttachmentChip({
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: c.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.onSurfaceDisabled),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.onSurface, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: c.onSurface, fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(TablerIcons.x, color: c.onSurfaceSecondary, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        'اسحب للتحريك • قرص للتكبير • مطوّل للحذف',
        style: TextStyle(
          color: context.c.onSurfaceMuted,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PostBar extends StatelessWidget {
  final Future<void> Function() onPost;
  const _PostBar({required this.onPost});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final busy = state.isBusy;
        final enabled = state.canPost;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
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
        return 'جارٍ رفع الصورة…';
      case MemoryComposerStatus.posting:
        return 'جارٍ النشر…';
      default:
        return 'جارٍ النشر…';
    }
  }
}

