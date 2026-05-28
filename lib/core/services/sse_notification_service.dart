import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'sse_web.dart' if (dart.library.io) 'sse_stub.dart';
import '../constants/api_endpoints.dart';

/// Web 端轻量 SSE 推送（Mobile 由 FCM 负责）
class SseNotificationService {
  static GoRouter? _router;

  static void setRouter(GoRouter router) {
    _router = router;
  }

  /// 登录后调用，连接 SSE 推送流
  static void connect(String jwtToken) {
    if (!kIsWeb) return;
    final url =
        '${ApiEndpoints.baseUrl}/api/v1/sse/subscribe?token=$jwtToken';
    connectSse(url, _handleEvent);
  }

  /// 登出后调用
  static void disconnect() {
    if (!kIsWeb) return;
    disconnectSse();
  }

  static void _handleEvent(String event, String data) {
    if (event != 'order_status') return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final orderId = json['orderId']?.toString();
      if (orderId != null && _router != null) {
        _router!.push('/orders/$orderId');
      }
    } catch (_) {}
  }
}
