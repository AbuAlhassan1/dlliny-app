import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/presentation/hangout/share/hangout_share_service.dart';
import 'package:hangout/presentation/hangout/share/hangout_story_card.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

const double _kBoardWidth = 1080;
const double _kBoardHeight = 1920;
const int _kMaxPhotoStickers = 5;

enum StoryKind { card, qr, photo }

class StoryItem {
  final StoryKind kind;
  final int photoIndex;
  Offset center;
  double rotation;
  double scale;
  final double widthFraction;
  final double aspect;

  StoryItem({
    required this.kind,
    this.photoIndex = -1,
    required this.center,
    this.rotation = 0,
    this.scale = 1.0,
    required this.widthFraction,
    required this.aspect,
  });

  double get effectiveWidthFraction => widthFraction * scale;
}

class StoryImages {
  final ui.Image? cover;
  final List<ui.Image?> photos;
  final Uint8List? authorAvatar;
  final List<Uint8List?> attendeeAvatars;

  const StoryImages({
    required this.cover,
    required this.photos,
    required this.authorAvatar,
    required this.attendeeAvatars,
  });
}

class StoryCardData {
  final String authorName;
  final String? authorHandle;
  final int likesCount;
  final int commentsCount;
  final int attendeesCount;
  final String caption;
  final String? dateLabel;
  final bool isArabic;

  const StoryCardData({
    required this.authorName,
    required this.authorHandle,
    required this.likesCount,
    required this.commentsCount,
    required this.attendeesCount,
    required this.caption,
    required this.dateLabel,
    required this.isArabic,
  });
}

List<StoryItem> buildInitialStoryItems({
  required int photoCount,
  required int seed,
}) {
  final r = math.Random(seed);
  double jitter(double span) => (r.nextDouble() - 0.5) * span;

  final items = <StoryItem>[
    StoryItem(
      kind: StoryKind.card,
      center: Offset(0.5 + jitter(0.08), 0.36 + jitter(0.06)),
      rotation: jitter(0.06),
      widthFraction: 0.60,
      aspect: 0.8,
    ),
    StoryItem(
      kind: StoryKind.qr,
      center: Offset(0.70 + jitter(0.08), 0.82 + jitter(0.06)),
      rotation: jitter(0.05),
      widthFraction: 0.26,
      aspect: 0.82,
    ),
  ];

  final n = math.min(photoCount, _kMaxPhotoStickers);
  for (var i = 0; i < n; i++) {
    items.add(StoryItem(
      kind: StoryKind.photo,
      photoIndex: i,
      center: Offset(0.22 + r.nextDouble() * 0.56, 0.16 + r.nextDouble() * 0.7),
      rotation: (r.nextDouble() - 0.5) * 0.4,
      widthFraction: 0.28,
      aspect: 1.0,
    ));
  }
  return items;
}

class HangoutStoryEditorPage extends StatefulWidget {
  final StoryImages images;
  final StoryCardData card;
  final String inviteUrl;
  final int seed;

  const HangoutStoryEditorPage({
    super.key,
    required this.images,
    required this.card,
    required this.inviteUrl,
    required this.seed,
  });

  @override
  State<HangoutStoryEditorPage> createState() => _HangoutStoryEditorPageState();
}

class _HangoutStoryEditorPageState extends State<HangoutStoryEditorPage> {
  late final List<StoryItem> _items = buildInitialStoryItems(
    photoCount: widget.images.photos.length,
    seed: widget.seed,
  );
  bool _sharing = false;
  StoryItem? _selected;

  bool get _isArabic => widget.card.isArabic;

  Future<void> _editItem(StoryItem item) async {
    setState(() {
      _items
        ..remove(item)
        ..add(item);
      _selected = item;
    });
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1B1B1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ItemControls(
        item: item,
        isArabic: _isArabic,
        onChanged: () => setState(() {}),
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final png = await ScreenshotController().captureFromWidget(
        _CaptureBoard(
          items: _items,
          images: widget.images,
          card: widget.card,
          inviteUrl: widget.inviteUrl,
        ),
        pixelRatio: 1,
        targetSize: const Size(_kBoardWidth, _kBoardHeight),
        delay: const Duration(milliseconds: 400),
      );
      await shareStoryImageBytes(png, widget.inviteUrl);
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isArabic ? 'رتّب الستوري' : 'Arrange your story',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(TablerIcons.brand_instagram, size: 18),
              label: Text(
                _isArabic ? 'مشاركة' : 'Share',
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _isArabic
                    ? 'اسحب العناصر لترتيبها كما تحب'
                    : 'Drag the elements to arrange them',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      var boardW = constraints.maxWidth;
                      var boardH = boardW * _kBoardHeight / _kBoardWidth;
                      if (boardH > constraints.maxHeight) {
                        boardH = constraints.maxHeight;
                        boardW = boardH * _kBoardWidth / _kBoardHeight;
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: boardW,
                          height: boardH,
                          child: _EditableBoard(
                            items: _items,
                            images: widget.images,
                            card: widget.card,
                            inviteUrl: widget.inviteUrl,
                            boardW: boardW,
                            boardH: boardH,
                            selected: _selected,
                            onChanged: () => setState(() {}),
                            onSelect: _editItem,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableBoard extends StatelessWidget {
  final List<StoryItem> items;
  final StoryImages images;
  final StoryCardData card;
  final String inviteUrl;
  final double boardW;
  final double boardH;
  final StoryItem? selected;
  final VoidCallback onChanged;
  final ValueChanged<StoryItem> onSelect;

  const _EditableBoard({
    required this.items,
    required this.images,
    required this.card,
    required this.inviteUrl,
    required this.boardW,
    required this.boardH,
    required this.selected,
    required this.onChanged,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: card.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StoryBackground(cover: images.cover),
          for (final item in items)
            _positioned(item),
        ],
      ),
    );
  }

  Widget _positioned(StoryItem item) {
    final w = item.effectiveWidthFraction * boardW;
    final h = w / item.aspect;
    final isSelected = identical(item, selected);
    return Positioned(
      key: ValueKey(item),
      left: item.center.dx * boardW - w / 2,
      top: item.center.dy * boardH - h / 2,
      width: w,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(item),
        onPanStart: (_) {
          items
            ..remove(item)
            ..add(item);
          onChanged();
        },
        onPanUpdate: (d) {
          item.center = Offset(
            (item.center.dx + d.delta.dx / boardW).clamp(0.06, 0.94),
            (item.center.dy + d.delta.dy / boardH).clamp(0.04, 0.96),
          );
          onChanged();
        },
        child: Transform.rotate(
          angle: item.rotation,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: const Color(0xFFEC4899), width: 2.5)
                  : null,
            ),
            child: storyItemVisual(item, images, card, inviteUrl, w),
          ),
        ),
      ),
    );
  }
}

class _CaptureBoard extends StatelessWidget {
  final List<StoryItem> items;
  final StoryImages images;
  final StoryCardData card;
  final String inviteUrl;

  const _CaptureBoard({
    required this.items,
    required this.images,
    required this.card,
    required this.inviteUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: card.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        width: _kBoardWidth,
        height: _kBoardHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            StoryBackground(cover: images.cover),
            for (final item in items)
              () {
                final w = item.effectiveWidthFraction * _kBoardWidth;
                final h = w / item.aspect;
                return Positioned(
                  left: item.center.dx * _kBoardWidth - w / 2,
                  top: item.center.dy * _kBoardHeight - h / 2,
                  width: w,
                  height: h,
                  child: Transform.rotate(
                    angle: item.rotation,
                    child: storyItemVisual(item, images, card, inviteUrl, w),
                  ),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

class StoryBackground extends StatelessWidget {
  final ui.Image? cover;
  const StoryBackground({super.key, required this.cover});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cover != null)
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: RawImage(
              image: cover,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Color(0x55000000), Color(0xB3000000)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

Widget storyItemVisual(
  StoryItem item,
  StoryImages images,
  StoryCardData card,
  String inviteUrl,
  double pxWidth,
) {
  switch (item.kind) {
    case StoryKind.card:
      const base = 360.0;
      return FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: base,
          height: base / item.aspect,
          child: HangoutStoryCardVisual(
            coverImage: images.cover,
            authorAvatarBytes: images.authorAvatar,
            attendeeAvatars: images.attendeeAvatars,
            authorName: card.authorName,
            authorHandle: card.authorHandle,
            likesCount: card.likesCount,
            commentsCount: card.commentsCount,
            attendeesCount: card.attendeesCount,
            caption: card.caption,
            dateLabel: card.dateLabel,
          ),
        ),
      );
    case StoryKind.qr:
      return _QrSticker(inviteUrl: inviteUrl, isArabic: card.isArabic);
    case StoryKind.photo:
      final img = (item.photoIndex >= 0 && item.photoIndex < images.photos.length)
          ? images.photos[item.photoIndex]
          : null;
      return _PhotoSticker(image: img);
  }
}

class _PhotoSticker extends StatelessWidget {
  final ui.Image? image;
  const _PhotoSticker({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: image != null
            ? RawImage(
                image: image,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              )
            : const ColoredBox(color: Color(0xFF241C38)),
      ),
    );
  }
}

class _ItemControls extends StatefulWidget {
  final StoryItem item;
  final bool isArabic;
  final VoidCallback onChanged;

  const _ItemControls({
    required this.item,
    required this.isArabic,
    required this.onChanged,
  });

  @override
  State<_ItemControls> createState() => _ItemControlsState();
}

class _ItemControlsState extends State<_ItemControls> {
  static const double _minScale = 0.4;
  static const double _maxScale = 2.6;
  static const double _rotRange = math.pi;

  void _set(VoidCallback mutate) {
    setState(mutate);
    widget.onChanged();
  }

  String get _kindLabel {
    final ar = widget.isArabic;
    switch (widget.item.kind) {
      case StoryKind.card:
        return ar ? 'بطاقة الطلعة' : 'Hangout card';
      case StoryKind.qr:
        return ar ? 'رمز QR' : 'QR code';
      case StoryKind.photo:
        return ar ? 'صورة' : 'Photo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ar = widget.isArabic;
    const accent = Color(0xFFEC4899);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(TablerIcons.adjustments, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _kindLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _set(() {
                    item.rotation = 0;
                    item.scale = 1.0;
                  }),
                  child: Text(
                    ar ? 'إعادة تعيين' : 'Reset',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _sliderRow(
              icon: TablerIcons.rotate_2,
              label: ar ? 'التدوير' : 'Rotation',
              value: item.rotation.clamp(-_rotRange, _rotRange),
              min: -_rotRange,
              max: _rotRange,
              accent: accent,
              trailing: '${(item.rotation * 180 / math.pi).round()}°',
              onChanged: (v) => _set(() => item.rotation = v),
            ),
            _sliderRow(
              icon: TablerIcons.resize,
              label: ar ? 'الحجم' : 'Size',
              value: item.scale.clamp(_minScale, _maxScale),
              min: _minScale,
              max: _maxScale,
              accent: accent,
              trailing: '${(item.scale * 100).round()}%',
              onChanged: (v) => _set(() => item.scale = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required Color accent,
    required String trailing,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              thumbColor: accent,
              inactiveTrackColor: Colors.white24,
              overlayColor: accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            trailing,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}

class _QrSticker extends StatelessWidget {
  final String inviteUrl;
  final bool isArabic;
  const _QrSticker({required this.inviteUrl, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          padding: EdgeInsets.all(w * 0.06),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(w * 0.12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: inviteUrl,
                size: w * 0.78,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF11151D),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF11151D),
                ),
              ),
              SizedBox(height: w * 0.04),
              Text(
                isArabic ? 'امسح للانضمام' : 'Scan to join',
                style: TextStyle(
                  color: const Color(0xFF11151D),
                  fontSize: w * 0.1,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
