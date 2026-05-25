import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/dodo_logo.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate once auth state is resolved (not initial/loading)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    ref.listenManual<AuthState>(authProvider, (prev, next) async {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        final user = next.user;
        if (user != null && user.needsOnboarding) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      } else if (next.status == AuthStatus.unauthenticated) {
        final storage = ref.read(storageServiceProvider);
        final agreed = await storage.hasAgreedToTerms();
        if (!mounted) return;
        context.go(agreed ? '/login' : '/agreement');
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF97316),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DodoLogo(size: 116, showShadow: false),
            const SizedBox(height: 24),
            Text(
              'Your neighborhood store',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
