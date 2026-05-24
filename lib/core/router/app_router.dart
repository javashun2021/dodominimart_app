import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/catalog/screens/product_detail_screen.dart';
import '../../features/catalog/screens/product_list_screen.dart';
import '../../features/catalog/screens/search_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/gcash_payment_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/flash_sale/screens/flash_sale_screen.dart';
import '../../features/group_buy/screens/group_activity_orders_screen.dart';
import '../../features/group_buy/screens/group_buy_detail_screen.dart';
import '../../features/group_buy/screens/group_buy_list_screen.dart';
import '../../features/group_buy/models/group_activity_model.dart';
import '../../features/orders/models/gcash_payment_info.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/home_tab_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/terms_screen.dart';
import '../../features/runner/models/runner_application_model.dart';
import '../../features/runner/screens/runner_apply_screen.dart';
import '../../features/runner/screens/runner_dashboard_screen.dart';
import '../../features/runner/screens/runner_history_screen.dart';

// Bridges Riverpod AuthState into GoRouter's refreshListenable
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final path = state.matchedLocation;

      final publicPaths = {'/splash', '/login', '/onboarding', '/privacy', '/terms'};
      final isPublic = publicPaths.contains(path) ||
          path.startsWith('/group-buy/') ||
          path.startsWith('/group-activity/') ||
          path == '/group-buys';

      switch (authState.status) {
        case AuthStatus.initial:
        case AuthStatus.loading:
          return path == '/splash' ? null : '/splash';

        case AuthStatus.unauthenticated:
          return isPublic ? null : '/login';

        case AuthStatus.authenticated:
          final user = authState.user!;
          if (path == '/splash' || path == '/login') {
            return user.needsOnboarding ? '/onboarding' : '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Shell (bottom nav) ──────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => HomeScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, __) => const ProductListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, __) => const OrderListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Full-screen routes (outside shell) ─────────────────────────────────
      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success/:orderId',
        builder: (_, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/payment/gcash/:orderId',
        builder: (_, state) => GCashPaymentScreen(
          orderId: state.pathParameters['orderId']!,
          gcashInfo: state.extra as GCashPaymentInfo?,
        ),
      ),
      GoRoute(
        path: '/flash-sale',
        builder: (_, __) => const FlashSaleScreen(),
      ),
      GoRoute(
        path: '/group-buys',
        builder: (_, __) => const GroupBuyListScreen(),
      ),
      GoRoute(
        path: '/group-activity/:activityId',
        builder: (_, state) => GroupActivityOrdersScreen(
          activity: state.extra as GroupActivityModel,
        ),
      ),
      GoRoute(
        path: '/group-buy/:inviteCode',
        builder: (_, state) => GroupBuyDetailScreen(
          inviteCode: state.pathParameters['inviteCode']!,
        ),
      ),
      GoRoute(
        path: '/runner',
        builder: (_, __) => const RunnerDashboardScreen(),
      ),
      GoRoute(
        path: '/runner/apply',
        builder: (_, state) => RunnerApplyScreen(
          existing: state.extra as RunnerApplicationModel?,
        ),
      ),
      GoRoute(
        path: '/runner/history',
        builder: (_, __) => const RunnerHistoryScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsScreen(),
      ),
    ],
  );
});
