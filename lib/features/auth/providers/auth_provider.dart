import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/storage_service.dart';
import '../data/auth_repository.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

// ─── Switch between mock and real API ────────────────────────────────────────
// Set to false when the backend is ready
const _useMock = false;

// ─── Providers ────────────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(storageServiceProvider)),
);

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (_useMock) return MockAuthRepository();
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

// ─── Auth State ───────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState._({required this.status, this.user, this.error});

  const AuthState.initial() : this._(status: AuthStatus.initial);
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.authenticated(UserModel user)
      : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated({String? error})
      : this._(status: AuthStatus.unauthenticated, error: error);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.initial;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _repository;
  final StorageService _storage;

  AuthNotifier(this._repository, this._storage)
      : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getToken();
    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _repository.getUserInfo();
      state = AuthState.authenticated(user);
    } catch (_) {
      await _storage.clearAll();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> _handleLoginResponse(LoginResponse response) async {
    await _storage.saveToken(response.token);
    final user = await _repository.getUserInfo();
    state = AuthState.authenticated(user);
    // Upload FCM token — non-blocking, must not throw
    try {
      final fcmToken = await FcmService.getToken();
      if (fcmToken != null) await _repository.updateFcmToken(fcmToken);
    } catch (_) {}
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    try {
      final response = await _repository.signInWithApple();
      await _handleLoginResponse(response);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      rethrow;
    }
  }

  Future<void> sendVerificationCode(String email) async {
    await _repository.sendVerificationCode(email);
  }

  Future<void> registerWithEmail({
    required String email,
    required String code,
    required String password,
    required String nickName,
  }) async {
    state = const AuthState.loading();
    try {
      final response = await _repository.registerWithEmail(
        email: email,
        code: code,
        password: password,
        nickName: nickName,
      );
      await _handleLoginResponse(response);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      rethrow;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final response = await _repository.loginWithEmail(
        email: email,
        password: password,
      );
      await _handleLoginResponse(response);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      final response = await _repository.signInWithGoogle();
      await _handleLoginResponse(response);
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await _storage.clearAll();
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    String? nickname,
    required String phoneNumber,
    String address = '',
    int? addressId,
    String? avatarUrl,
  }) async {
    await _repository.updateProfile(
      nickname: nickname,
      phoneNumber: phoneNumber,
      address: address,
      addressId: addressId,
      avatarUrl: avatarUrl,
    );
    final current = state.user;
    if (current != null) {
      state = AuthState.authenticated(
        current.copyWith(
          nickname: nickname ?? current.nickname,
          phoneNumber: phoneNumber,
          defaultAddress: address.isEmpty ? current.defaultAddress : address,
          avatar: avatarUrl ?? current.avatar,
        ),
      );
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(
          ref.watch(authRepositoryProvider),
          ref.watch(storageServiceProvider),
        ));
