import 'package:flutter/foundation.dart';

abstract final class ApiEndpoints {
  // Android emulator → host machine localhost
  // Chrome / desktop → localhost:8080 directly
  static String get baseUrl {
    if (kIsWeb) return Uri.base.origin; // 自动使用当前页面域名，本地=localhost，线上=dodominimart.com
    if (_isAndroid) return 'http://10.0.2.2:8080'; // 内网真机
    return 'http://localhost:8080'; // macOS/Windows 桌面直连
  }

  static bool get _isAndroid {
    try {
      // dart:io not available on web, but we guard with !kIsWeb above
      // ignore: do_not_use_environment
      return const bool.fromEnvironment('dart.library.io') &&
          !kIsWeb;
    } catch (_) {
      return false;
    }
  }

  // ── Auth (no JWT required) ─────────────────────────────────────────────────
  static const sendCode   = '/api/v1/auth/send-code'; // POST {email}
  static const register   = '/api/v1/auth/register';  // POST {email,code,password,nickName}
  static const emailLogin = '/api/v1/auth/login';     // POST {email,password}
  static const appleAuth  = '/api/v1/auth/apple';     // POST {identityToken, fullName?}
  static const googleAuth = '/api/v1/auth/google';    // POST {idToken}
  static const logout     = '/api/v1/auth/logout';    // POST

  // ── App config (no JWT required) ──────────────────────────────────────────
  static const config = '/api/v1/config'; // GET

  // ── Member (JWT required) ─────────────────────────────────────────────────
  static const memberProfile = '/api/v1/member/profile'; // GET / PUT
  static const memberAddresses = '/api/v1/member/addresses'; // GET / POST
  static String memberAddress(String id) =>
      '/api/v1/member/addresses/$id'; // PUT / DELETE

  // ── Catalog (no JWT required) ─────────────────────────────────────────────
  static const categories = '/api/v1/categories'; // GET
  static const products = '/api/v1/products'; // GET ?categoryId=&keyword=
  static String productDetail(String id) => '/api/v1/products/$id'; // GET

  // ── Orders (JWT required) ─────────────────────────────────────────────────
  static const orders = '/api/v1/orders'; // GET / POST
  static String orderDetail(String id) => '/api/v1/orders/$id'; // GET
  static String cancelOrder(String id) =>
      '/api/v1/orders/$id/cancel'; // POST {reason}
  static String orderPay(String id) =>
      '/api/v1/orders/$id/pay'; // POST → GCash payUrl

  // ── Flash Sale (no JWT required) ─────────────────────────────────────────
  static const flashSales = '/api/v1/flash-sales'; // GET

  // ── Group Activity (no JWT required) ─────────────────────────────────────
  static const groupActivities = '/api/v1/group-activities'; // GET
  // ── Group Order (JWT required for POST) ───────────────────────────────────
  static const groupOrders = '/api/v1/group-orders'; // POST (create)
  static const groupOrdersList = '/api/v1/group-orders/list'; // POST (query list)
  static String groupOrderDetail(String inviteCode) =>
      '/api/v1/group-orders/$inviteCode'; // GET
  static String joinGroupOrder(String inviteCode) =>
      '/api/v1/group-orders/$inviteCode/join'; // POST
  static String closeGroupOrder(String inviteCode) =>
      '/api/v1/group-orders/$inviteCode/close'; // POST
  static const myGroupOrders = '/api/v1/group-orders/my'; // GET

  // ── Upload (JWT required) ─────────────────────────────────────────────────
  static const uploadImage = '/api/v1/upload/image'; // POST multipart/form-data

  // ── Runner (JWT required) ─────────────────────────────────────────────────
  static const runnerApplication     = '/api/v1/runner/application';        // GET / POST
  static const runnerAvailableOrders = '/api/v1/runner/available-orders';   // GET
  static const runnerMyDeliveries    = '/api/v1/runner/my-deliveries';      // GET
  static String runnerAccept(String id)   => '/api/v1/runner/orders/$id/accept';   // POST
  static String runnerComplete(String id) => '/api/v1/runner/orders/$id/complete'; // POST
  static String rateRunner(String id)     => '/api/v1/orders/$id/rate-runner';     // POST
  static String runnerStats(String id)    => '/api/v1/runner/stats/$id';           // GET (public)

  // Fallback delivery fee — overridden by /api/v1/config at runtime
  static const double deliveryFee = 20.0;

  // 把后端返回的相对路径补全为可访问的完整 URL
  static String? resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return '$baseUrl$url';
  }
}
