import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

// Top-level handler required by FCM for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

const _kChannelId   = 'dodo_orders';
const _kChannelName = 'Order Updates';

class FcmService {
  static GoRouter? _router;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp.
  static Future<void> initialize() async {
    if (kIsWeb) return; // Web uses WebSocket; skip Firebase entirely

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('FCM: Firebase init failed — $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotifications();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      if (defaultTargetPlatform == TargetPlatform.android) {
        _showLocalNotification(
          title:     notification.title ?? 'DODO MiniMart',
          body:      notification.body  ?? '',
          routePath: _routeFrom(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
  }

  /// Call after the GoRouter instance is created (inside build).
  static void setRouter(GoRouter router) {
    _router = router;
    if (kIsWeb) return;
    FirebaseMessaging.instance.getInitialMessage().then(_handleMessage);
  }

  // ─── Private ─────────────────────────────────────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        final route = details.payload;
        if (route != null && route.isNotEmpty && _router != null) {
          _router!.push(route);
        }
      },
    );

    // Create a high-importance Android notification channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description: 'Order status change notifications',
        importance: Importance.high,
        playSound: true,
        enableLights: true,
      ),
    );
  }

  static void _showLocalNotification({
    required String title,
    required String body,
    String? routePath,
  }) {
    _localNotif.show(
      routePath?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          channelDescription: 'Order and group buy notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: routePath,
    );
  }

  /// Derives a push route from FCM data payload.
  /// Backend should send one of:
  ///   { "orderId": "123" }           → /orders/123
  ///   { "inviteCode": "ABC123" }     → /group-buy/ABC123
  static String? _routeFrom(Map<String, dynamic> data) {
    final orderId    = data['orderId']    as String?;
    final inviteCode = data['inviteCode'] as String?;
    if (orderId != null && orderId.isNotEmpty) return '/orders/$orderId';
    if (inviteCode != null && inviteCode.isNotEmpty) return '/group-buy/$inviteCode';
    return null;
  }

  static void _handleMessage(RemoteMessage? message) {
    if (message == null || _router == null) return;
    final route = _routeFrom(message.data);
    if (route != null) _router!.push(route);
  }

  /// Returns the current device FCM token, or null on web/unavailable.
  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM: getToken failed — $e');
      return null;
    }
  }
}
