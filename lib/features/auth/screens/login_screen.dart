import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _AuthMode _mode = _AuthMode.login;

  // ── Login controllers ──────────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // ── Register controllers ───────────────────────────────────────────────────
  final _registerFormKey = GlobalKey<FormState>();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _regCodeCtrl = TextEditingController();

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _obscureLoginPwd = true;
  bool _obscureRegPwd = true;
  bool _obscureConfirmPwd = true;
  bool _isLoading = false;
  bool _sendingCode = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    _regCodeCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _countdown = 0;
      _loginFormKey.currentState?.reset();
      _registerFormKey.currentState?.reset();
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown <= 0) { t.cancel(); return; }
      setState(() => _countdown--);
    });
  }

  Future<void> _sendCode() async {
    final email = _regEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email first.');
      return;
    }
    setState(() => _sendingCode = true);
    try {
      await ref.read(authProvider.notifier).sendVerificationCode(email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! Check your email.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).loginWithEmail(
            email: _loginEmailCtrl.text.trim(),
            password: _loginPasswordCtrl.text,
          );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).registerWithEmail(
            email: _regEmailCtrl.text.trim(),
            code: _regCodeCtrl.text.trim(),
            password: _regPasswordCtrl.text,
            nickName: _regNameCtrl.text.trim(),
          );
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithApple();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Gap(40),

              // ── Logo ────────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront,
                    color: Colors.white, size: 44),
              ),
              const Gap(16),
              const Text(
                'DodoMiniMart',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const Gap(4),
              const Text(
                'Your community store, delivered.',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
              ),

              const Gap(28),

              // ── Tab 切换 ────────────────────────────────────────────────
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Log In',
                      selected: _mode == _AuthMode.login,
                      onTap: () => _switchMode(_AuthMode.login),
                    ),
                    _TabButton(
                      label: 'Register',
                      selected: _mode == _AuthMode.register,
                      onTap: () => _switchMode(_AuthMode.register),
                    ),
                  ],
                ),
              ),

              const Gap(24),

              // ── 表单区 ──────────────────────────────────────────────────
              _mode == _AuthMode.login
                  ? _buildLoginForm()
                  : _buildRegisterForm(),

              const Gap(20),

              // ── 分隔线 ──────────────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const Gap(16),

              // ── Google ──────────────────────────────────────────────────
              _GoogleSignInButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                isLoading: false,
              ),

              // ── Apple（仅非 Web 平台显示）────────────────────────────────
              if (!kIsWeb) ...[
                const Gap(12),
                SignInWithAppleButton(
                  onPressed: _isLoading ? () {} : _signInWithApple,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(12)),
                  height: 50,
                ),
              ],

              const Gap(24),

              // ── Terms ───────────────────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    'By continuing, you agree to our ',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/terms'),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const Text(
                    ' and ',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/privacy'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const Text(
                    '.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),

              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  // ── 登录表单 ─────────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const Gap(14),
          TextFormField(
            controller: _loginPasswordCtrl,
            obscureText: _obscureLoginPwd,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureLoginPwd = !_obscureLoginPwd),
              ),
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
          ),
          const Gap(20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Log In'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 注册表单 ─────────────────────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _regNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const Gap(14),
          TextFormField(
            controller: _regEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const Gap(14),
          TextFormField(
            controller: _regPasswordCtrl,
            obscureText: _obscureRegPwd,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureRegPwd = !_obscureRegPwd),
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'At least 8 characters';
              return null;
            },
          ),
          const Gap(14),
          TextFormField(
            controller: _regConfirmCtrl,
            obscureText: _obscureConfirmPwd,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v != _regPasswordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const Gap(14),
          // 验证码行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _regCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    prefixIcon: Icon(Icons.verified_outlined),
                    hintText: '6-digit code',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Code is required';
                    }
                    if (v.trim().length != 6) return 'Must be 6 digits';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_sendingCode || _countdown > 0) ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: (_sendingCode || _countdown > 0)
                        ? AppColors.surfaceVariant
                        : AppColors.primary,
                    foregroundColor: (_sendingCode || _countdown > 0)
                        ? AppColors.onSurfaceVariant
                        : Colors.white,
                  ),
                  child: _sendingCode
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _countdown > 0 ? '${_countdown}s' : 'Send Code',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
          const Gap(20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 按钮 ─────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? AppColors.onBackground
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google 登录按钮 ──────────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D1D1D),
          side: const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(_kGoogleLogoSvg, width: 20, height: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D1D1D)),
                  ),
                ],
              ),
      ),
    );
  }
}

const _kGoogleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.35-8.16 2.35-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';
