import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/core/theme/colors.dart';

class NotificationBanner extends StatefulWidget {
  final IncomingNotification notification;
  final Duration autoDismiss;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismissed,
    this.autoDismiss = const Duration(seconds: 8),
  });

  @override
  State<NotificationBanner> createState() => NotificationBannerState();
}

class NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final Animation<Offset> _offset;
  bool _dismissing = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    _slide.forward();

    Future.delayed(widget.autoDismiss, () {
      if (mounted && !_dismissing) _dismiss();
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void forceDismiss() {
    if (_dismissing) return;
    _dismiss();
  }

  void _dismiss({bool runOnDismissed = true}) {
    if (_dismissing) return;
    _dismissing = true;
    _slide.reverse().whenComplete(() {
      if (runOnDismissed) widget.onDismissed();
    });
  }

  void _handleTap() {
    if (_dismissing) return;
    widget.onTap();
    _dismiss();
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    if (_dismissing) return;
    setState(() => _dragOffset = (_dragOffset + d.delta.dy).clamp(-80.0, 0.0));
  }

  void _handleDragEnd(DragEndDetails d) {
    if (_dismissing) return;
    if (_dragOffset < -30 || d.velocity.pixelsPerSecond.dy < -500) {
      _dismiss();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isAr = context.locale.languageCode == 'ar';
    final n = widget.notification;
    final title = n.localizedTitle(isAr: isAr);
    final body = n.localizedBody(isAr: isAr);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SlideTransition(
          position: _offset,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleTap,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: c.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _Avatar(url: n.actorAvatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null && title.isNotEmpty)
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            if (body != null && body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.onSurfaceSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        TablerIcons.chevron_left,
                        color: c.onSurfaceDisabled,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surfaceMuted,
        border: Border.all(
          color: c.onSurface.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(
                TablerIcons.bell,
                color: c.onSurface,
                size: 18,
              ),
            )
          : Icon(TablerIcons.bell, color: c.onSurface, size: 18),
    );
  }
}
