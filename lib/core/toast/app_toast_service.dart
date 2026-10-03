import 'dart:async';

enum AppToastSeverity { success, error, info }

class AppToastMessage {
  final String text;
  final String? body;
  final AppToastSeverity severity;
  final Duration autoDismiss;

  const AppToastMessage({
    required this.text,
    required this.severity,
    this.body,
    this.autoDismiss = const Duration(seconds: 4),
  });
}

class AppToastService {
  AppToastService._();
  static final AppToastService instance = AppToastService._();

  final StreamController<AppToastMessage> _controller =
      StreamController<AppToastMessage>.broadcast();

  Stream<AppToastMessage> get stream => _controller.stream;

  void show(AppToastMessage msg) => _controller.add(msg);

  void success(String text, {String? body, Duration? autoDismiss}) =>
      show(AppToastMessage(
        text: text,
        body: body,
        severity: AppToastSeverity.success,
        autoDismiss: autoDismiss ?? const Duration(seconds: 4),
      ));

  void error(String text, {String? body, Duration? autoDismiss}) =>
      show(AppToastMessage(
        text: text,
        body: body,
        severity: AppToastSeverity.error,
        autoDismiss: autoDismiss ?? const Duration(seconds: 5),
      ));

  void info(String text, {String? body, Duration? autoDismiss}) =>
      show(AppToastMessage(
        text: text,
        body: body,
        severity: AppToastSeverity.info,
        autoDismiss: autoDismiss ?? const Duration(seconds: 4),
      ));
}

final AppToastService appToast = AppToastService.instance;
