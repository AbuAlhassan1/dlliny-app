import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/toast/app_toast_service.dart';

class AppToastBanner extends StatefulWidget {
  final AppToastMessage message;
  final VoidCallback onDismissed;

  const AppToastBanner({
    super.key,
    required this.message,
    required this.onDismissed,
  });

  @override
  State<AppToastBanner> createState() => _AppToastBannerState();
}

class _AppToastBannerState extends State<AppToastBanner>
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

    Future.delayed(widget.message.autoDismiss, () {
      if (mounted && !_dismissing) _dismiss();
    });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _slide.reverse().whenComplete(widget.onDismissed);
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
    final m = widget.message;
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
              onTap: _dismiss,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
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
                      _SeverityIcon(severity: m.severity),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (m.body != null && m.body!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                m.body!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _SeverityIcon extends StatelessWidget {
  final AppToastSeverity severity;
  const _SeverityIcon({required this.severity});

  ({Color background, Color foreground, IconData icon}) get _palette {
    switch (severity) {
      case AppToastSeverity.success:
        return (
          background: const Color(0xFF1E5237),
          foreground: const Color(0xFF6EEB9F),
          icon: TablerIcons.check,
        );
      case AppToastSeverity.error:
        return (
          background: const Color(0xFF5A1F25),
          foreground: const Color(0xFFFF8585),
          icon: TablerIcons.alert_circle,
        );
      case AppToastSeverity.info:
        return (
          background: const Color(0xFF1F3F5A),
          foreground: const Color(0xFF7FB8FF),
          icon: TablerIcons.info_circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.background,
        border: Border.all(
          color: p.foreground.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Icon(p.icon, color: p.foreground, size: 20),
    );
  }
}
