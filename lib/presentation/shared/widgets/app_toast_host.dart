import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/presentation/shared/widgets/app_toast_banner.dart';

class AppToastHost extends StatefulWidget {
  final Widget child;
  const AppToastHost({super.key, required this.child});

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  StreamSubscription<AppToastMessage>? _sub;
  AppToastMessage? _current;
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _sub = AppToastService.instance.stream.listen(_onIncoming);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onIncoming(AppToastMessage message) {
    if (!mounted) return;
    setState(() {
      _current = message;
      _bannerKey = UniqueKey();
    });
  }

  void _clear() {
    if (!mounted) return;
    setState(() => _current = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_current != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppToastBanner(
              key: _bannerKey,
              message: _current!,
              onDismissed: _clear,
            ),
          ),
      ],
    );
  }
}
