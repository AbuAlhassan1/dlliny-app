import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/deep_links/deep_link_handler.dart';

class DeepLinkListener extends StatefulWidget {
  final Widget child;
  const DeepLinkListener({super.key, required this.child});

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _handledInitial = false;

  @override
  void initState() {
    super.initState();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (!mounted) return;
        handleDeepLink(uri);
      },
      onError: (_) {},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainInitial());
  }

  Future<void> _drainInitial() async {
    if (_handledInitial) return;
    _handledInitial = true;
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) await handleDeepLink(uri);
    } catch (_) {
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
