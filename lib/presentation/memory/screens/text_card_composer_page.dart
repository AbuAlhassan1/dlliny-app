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

class TextCardComposerPage extends StatelessWidget {
  const TextCardComposerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryComposerBloc>(
      create: (_) => MemoryComposerBloc(
        repository: serviceLocator.get<MemoryRepository>(),
        uploader: serviceLocator.get<MemoryUploadRepository>(),
        mode: MemoryComposerMode.text,
      ),
      child: const _ComposerSurface(),
    );
  }
}

const List<String> _backgroundSwatches = [
  '#1F1F1F',
  '#FFFFFF',
  '#FF3B30',
  '#FF9500',
  '#FFCC00',
  '#34C759',
  '#007AFF',
  '#AF52DE',
  '#FF2D55',
];

const List<String> _textSwatches = [
  '#FFFFFF',
  '#000000',
  '#FFCC00',
];

class _ComposerSurface extends StatefulWidget {
  const _ComposerSurface();

  @override
  State<_ComposerSurface> createState() => _ComposerSurfaceState();
}

class _ComposerSurfaceState extends State<_ComposerSurface> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<MemoryComposerBloc>().state.textContent,
    );
    _controller.addListener(_pushTextToBloc);
  }

  @override
  void dispose() {
    _controller.removeListener(_pushTextToBloc);
    _controller.dispose();
    super.dispose();
  }

  void _pushTextToBloc() {
    context.read<MemoryComposerBloc>().add(TextChanged(_controller.text));
  }

  void _onSuccess(BuildContext context) {
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
            _onSuccess(context);
          case MemoryComposerStatus.failure:
            appToast.error(state.errorMessage ?? 'تعذر نشر القصة');
          case _:
            break;
        }
      },
      child: BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
        buildWhen: (prev, curr) =>
            prev.backgroundColor != curr.backgroundColor ||
            prev.textColor != curr.textColor,
        builder: (context, state) {
          final c = context.c;
          final bg = _parseHex(state.backgroundColor, c.mediaSurface);
          final fg = _parseHex(state.textColor, c.onMediaSurface);
          return Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(textColor: fg),
                  const PostAsPicker(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          minLines: 1,
                          textAlign: TextAlign.center,
                          cursorColor: fg,
                          style: TextStyle(
                            color: fg,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب رسالتك…',
                            hintStyle: TextStyle(
                              color: fg.withValues(alpha: 0.45),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _PalettePicker(activeBackground: state.backgroundColor),
                  const SizedBox(height: 6),
                  _TextColorPicker(activeText: state.textColor),
                  const _PostBar(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Color textColor;
  const _TopBar({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(TablerIcons.x, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  final String activeBackground;
  const _PalettePicker({required this.activeBackground});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _backgroundSwatches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final hex = _backgroundSwatches[i];
          return _Swatch(
            hex: hex,
            selected: hex == activeBackground,
            onTap: () => context
                .read<MemoryComposerBloc>()
                .add(BackgroundColorChanged(hex)),
          );
        },
      ),
    );
  }
}

class _TextColorPicker extends StatelessWidget {
  final String activeText;
  const _TextColorPicker({required this.activeText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final hex in _textSwatches) ...[
            _Swatch(
              hex: hex,
              size: 24,
              selected: hex == activeText,
              onTap: () => context
                  .read<MemoryComposerBloc>()
                  .add(TextColorChanged(hex)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _Swatch({
    required this.hex,
    required this.selected,
    required this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = _parseHex(hex, c.mediaSurface);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? c.onMediaSurface
                : c.onMediaSurface.withValues(alpha: 0.24),
            width: selected ? 2.5 : 1.0,
          ),
        ),
      ),
    );
  }
}

class _PostBar extends StatelessWidget {
  const _PostBar();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MemoryComposerBloc, MemoryComposerState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.textContent.trim().isNotEmpty !=
              curr.textContent.trim().isNotEmpty,
      builder: (context, state) {
        final busy = state.isBusy;
        final enabled = state.canPost;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: enabled
                  ? () =>
                      context.read<MemoryComposerBloc>().add(PostRequested())
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: c.onMediaSurface,
                foregroundColor: c.mediaSurface,
                disabledBackgroundColor:
                    c.onMediaSurface.withValues(alpha: 0.24),
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
                        color: c.mediaSurface.withValues(alpha: 0.6),
                      ),
                    )
                  : const Icon(TablerIcons.send),
              label: Text(
                busy ? 'جارٍ النشر…' : 'نشر القصة',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _parseHex(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
}
