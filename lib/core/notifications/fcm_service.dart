import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/register_fcm_token_request.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('FCM background message: ${message.messageId} data=${message.data}');
}

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const String _globalTopic = 'hangout-global';
  static const String _channelId = 'hangout_default';
  static const String _channelName = 'General';
  static const String _channelDescription = 'App notifications';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _api = serviceLocator.get<ApiService>();

  bool _started = false;
  String? _registeredToken;

  final StreamController<IncomingNotification> _onIncoming =
      StreamController<IncomingNotification>.broadcast();
  Stream<IncomingNotification> get onIncomingNotification => _onIncoming.stream;

  final StreamController<IncomingNotification> _onTapped =
      StreamController<IncomingNotification>.broadcast();
  Stream<IncomingNotification> get onTappedNotification => _onTapped.stream;

  IncomingNotification? _pendingTap;

  IncomingNotification? consumePendingTap() {
    final t = _pendingTap;
    _pendingTap = null;
    return t;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    log('FCM: start() invoked');

    await _initLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      log('FCM: notifications permission denied by user');
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      final apns = await _messaging.getAPNSToken();
      if (apns == null) {
        log('FCM: APNS token not available yet — push will register on next launch');
        return;
      }
      log('FCM: APNS token = $apns');
    }

    final token = await _messaging.getToken();
    if (token == null) {
      log('FCM: getToken returned null');
      return;
    }
    log('FCM: device token = $token');
    await _registerToken(token);

    _messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromBackground);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _onOpenedFromBackground(initial);
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _registeredToken = null;
    try {
      await _messaging.unsubscribeFromTopic(_globalTopic);
      await _messaging.deleteToken();
    } catch (e) {
      log('FCM stop error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _registeredToken) return;
    try {
      final res = await _api.registerFcmToken(
        RegisterFcmTokenRequest(fcmToken: token),
      );
      if (!res.success) {
        log('FCM: registerFcmToken failed: ${res.error}');
        return;
      }
      _registeredToken = token;
      log('FCM: registerFcmToken succeeded');
      try {
        await _messaging.subscribeToTopic(_globalTopic);
      } catch (e) {
        log('FCM: subscribeToTopic($_globalTopic) failed: $e');
      }
    } catch (e) {
      log('FCM: registerFcmToken exception: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        log('Local notification tapped: payload=${response.payload}');
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    log('FCM foreground: ${message.messageId} data=${message.data}');
    _onIncoming.add(_toIncoming(message));
  }

  void _onOpenedFromBackground(RemoteMessage message) {
    log('FCM tapped: ${message.messageId} data=${message.data}');
    final notif = _toIncoming(message);
    _pendingTap = notif;
    _onTapped.add(notif);
  }

  IncomingNotification _toIncoming(RemoteMessage m) {
    return IncomingNotification(
      title: m.notification?.title,
      body: m.notification?.body,
      data: Map<String, String>.from(m.data),
    );
  }
}
