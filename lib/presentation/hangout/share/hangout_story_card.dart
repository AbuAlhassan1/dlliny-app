import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HangoutStoryCard extends StatelessWidget {
  final ui.Image? coverImage;
  final Uint8List? authorAvatarBytes;
  final List<Uint8List?> attendeeAvatars;
  final String authorName;
  final String? authorHandle;
  final int likesCount;
  final int commentsCount;
  final int attendeesCount;
  final String caption;
  final String? dateLabel;
  final String inviteUrl;
  final bool isArabic;

  static const double kWidth = 1080;
  static const double kHeight = 1920;

  static const double _cardBaseWidth = 360;
  static const double _cardAspect = 0.8;

  const HangoutStoryCard({
    super.key,
    required this.coverImage,
    required this.authorAvatarBytes,
    required this.attendeeAvatars,
    required this.authorName,
    required this.authorHandle,
    required this.likesCount,
    required this.commentsCount,
    required this.attendeesCount,
    required this.caption,
    required this.dateLabel,
    required this.inviteUrl,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SizedBox(
        width: kWidth,
        height: kHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverImage != null)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: RawImage(
                  image: coverImage,
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
                  colors: [Color(0xB3000000), Color(0x99000000), Color(0xD9000000)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(70, 96, 70, 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: kWidth - 140,
                      height: (kWidth - 140) / _cardAspect,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: _cardBaseWidth,
                          height: _cardBaseWidth / _cardAspect,
                          child: HangoutStoryCardVisual(
                            coverImage: coverImage,
                            authorAvatarBytes: authorAvatarBytes,
                            attendeeAvatars: attendeeAvatars,
                            authorName: authorName,
                            authorHandle: authorHandle,
                            likesCount: likesCount,
                            commentsCount: commentsCount,
                            attendeesCount: attendeesCount,
                            caption: caption,
                            dateLabel: dateLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  _QrLinkRow(inviteUrl: inviteUrl, isArabic: isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HangoutStoryCardVisual extends StatelessWidget {
  final ui.Image? coverImage;
  final Uint8List? authorAvatarBytes;
  final List<Uint8List?> attendeeAvatars;
  final String authorName;
  final String? authorHandle;
  final int likesCount;
  final int commentsCount;
  final int attendeesCount;
  final String caption;
  final String? dateLabel;

  const HangoutStoryCardVisual({
    super.key,
    required this.coverImage,
    required this.authorAvatarBytes,
    required this.attendeeAvatars,
    required this.authorName,
    required this.authorHandle,
    required this.likesCount,
    required this.commentsCount,
    required this.attendeesCount,
    required this.caption,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverImage != null)
            RawImage(
              image: coverImage,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A2E5C), Color(0xFF241C38)],
                ),
              ),
            ),

          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8C000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xC2000000),
                  ],
                  stops: [0.0, 0.28, 0.55, 1.0],
                ),
              ),
            ),
          ),

          PositionedDirectional(
            top: 12,
            start: 12,
            end: 12,
            child: _authorRow(context),
          ),

          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 12,
            child: _bottomBlock(),
          ),
        ],
      ),
    );
  }

  Widget _authorRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circleAvatar(authorAvatarBytes, 36, fallbackIcon: TablerIcons.user),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'IBMPlexSansArabic',
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                      if (authorHandle != null && authorHandle!.isNotEmpty)
                        Text(
                          authorHandle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'IBMPlexSansArabic',
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: const Icon(TablerIcons.dots, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _bottomBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statsChip(),
            const Spacer(),
            if (attendeeAvatars.isNotEmpty)
              _bubbles(),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
        ],
        if (dateLabel != null && dateLabel!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(TablerIcons.calendar_event, size: 12, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stat(TablerIcons.heart, likesCount),
          const SizedBox(width: 16),
          _stat(TablerIcons.message_circle, commentsCount),
          const SizedBox(width: 16),
          _stat(TablerIcons.users, attendeesCount),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ],
    );
  }

  Widget _bubbles() {
    const size = 32.0;
    const overlap = 11.0;
    final shown = attendeeAvatars.take(3).toList();
    final extra = attendeeAvatars.length - shown.length;

    final children = <Widget>[];
    for (var i = shown.length - 1; i >= 0; i--) {
      children.add(PositionedDirectional(
        end: i * (size - overlap),
        child: _circleAvatar(shown[i], size,
            fallbackIcon: TablerIcons.user, borderWidth: 1.5),
      ));
    }
    if (extra > 0) {
      children.insert(
        0,
        PositionedDirectional(
          end: shown.length * (size - overlap),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.55),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              '+$extra',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ),
      );
    }

    final faces = shown.length + (extra > 0 ? 1 : 0);
    final width = size + (faces - 1) * (size - overlap);
    return SizedBox(
      height: size,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.centerEnd,
        children: children,
      ),
    );
  }

  Widget _circleAvatar(
    Uint8List? bytes,
    double size, {
    required IconData fallbackIcon,
    double borderWidth = 1.5,
  }) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white, width: borderWidth),
      ),
      child: bytes != null
          ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: Image.memory(bytes, fit: BoxFit.cover)
          )
          : Icon(fallbackIcon, color: Colors.white, size: size * 0.5),
    );
  }
}

class _QrLinkRow extends StatelessWidget {
  final String inviteUrl;
  final bool isArabic;
  const _QrLinkRow({required this.inviteUrl, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final shortUrl = inviteUrl.replaceFirst(RegExp(r'^https?://'), '');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: QrImageView(
            data: inviteUrl,
            size: 210,
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
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic ? 'امسح للانضمام' : 'Scan to join',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'IBMPlexSansArabic',
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(TablerIcons.link, color: Colors.white, size: 34),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        shortUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
