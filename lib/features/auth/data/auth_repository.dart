import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';

// ─── Interface ───────────────────────────────────────────────────────────────

abstract class IAuthRepository {
  Future<LoginResponse> signInWithApple();
  Future<void> sendVerificationCode(String email);
  Future<LoginResponse> registerWithEmail({
    required String email,
    required String code,
    required String password,
    required String nickName,
  });
  Future<LoginResponse> loginWithEmail({
    required String email,
    required String password,
  });
  Future<LoginResponse> signInWithGoogle();
  Future<void> logout();
  Future<UserModel> getUserInfo();
  Future<void> updateProfile({
    String? nickname,
    required String phoneNumber,
    String address,
    int? addressId,
    String? avatarUrl,
  });
}

// ─── Mock ─────────────────────────────────────────────────────────────────────

class MockAuthRepository implements IAuthRepository {
  UserModel _user = const UserModel(
    uid: 'google-uid-001',
    username: 'testuser',
    nickname: 'Test User',
    email: 'testuser@gmail.com',
    role: 'customer',
  );

  @override
  Future<LoginResponse> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return LoginResponse(
      token: 'mock_apple_token_${DateTime.now().millisecondsSinceEpoch}',
      user: _user,
    );
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<LoginResponse> registerWithEmail({
    required String email,
    required String code,
    required String password,
    required String nickName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _user = _user.copyWith(nickname: nickName, email: email);
    return LoginResponse(
      token: 'mock_email_token_${DateTime.now().millisecondsSinceEpoch}',
      user: _user,
    );
  }

  @override
  Future<LoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return LoginResponse(
      token: 'mock_email_token_${DateTime.now().millisecondsSinceEpoch}',
      user: _user,
    );
  }

  @override
  Future<LoginResponse> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return LoginResponse(
      token: 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}',
      user: _user,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<UserModel> getUserInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _user;
  }

  @override
  Future<void> updateProfile({
    String? nickname,
    required String phoneNumber,
    String address = '',
    int? addressId,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _user = _user.copyWith(
      nickname: nickname,
      phoneNumber: phoneNumber,
      avatar: avatarUrl,
    );
  }
}

// ─── Real API ─────────────────────────────────────────────────────────────────

class ApiAuthRepository implements IAuthRepository {
  final ApiClient _client;
  final _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '600271771039-p4bmnq6r0np6bignuiqempniupeb7oqt.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
    serverClientId: kIsWeb
        ? null
        : '600271771039-p4bmnq6r0np6bignuiqempniupeb7oqt.apps.googleusercontent.com',
  );

  ApiAuthRepository(this._client);

  @override
  Future<LoginResponse> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw Exception('Failed to get Apple identity token');
    }
    final givenName = credential.givenName;
    final familyName = credential.familyName;
    final fullName = [givenName, familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    final response = await _client.post(
      ApiEndpoints.appleAuth,
      data: {
        'identityToken': identityToken,
        if (fullName.isNotEmpty) 'fullName': fullName,
      },
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return LoginResponse.fromJson(json);
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    final response = await _client.post(
      ApiEndpoints.sendCode,
      data: {'email': email},
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
  }

  @override
  Future<LoginResponse> registerWithEmail({
    required String email,
    required String code,
    required String password,
    required String nickName,
  }) async {
    final response = await _client.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'code': code,
        'password': password,
        'nickName': nickName,
      },
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return LoginResponse.fromJson(json);
  }

  @override
  Future<LoginResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiEndpoints.emailLogin,
      data: {'email': email, 'password': password},
    );
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return LoginResponse.fromJson(json);
  }

  @override
  Future<LoginResponse> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign-in cancelled');

    final googleAuth = await googleUser.authentication;

    // Web GIS Token Client only returns accessToken; mobile returns idToken
    if (kIsWeb) {
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw Exception('Failed to get Google access token');
      final response = await _client.post(
        ApiEndpoints.googleAuth,
        data: {'accessToken': accessToken},
      );
      final json = response.data!;
      if (json['code'] != 0) throw Exception(json['msg']);
      return LoginResponse.fromJson(json);
    } else {
      final idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');
      final response = await _client.post(
        ApiEndpoints.googleAuth,
        data: {'idToken': idToken},
      );
      final json = response.data!;
      if (json['code'] != 0) throw Exception(json['msg']);
      return LoginResponse.fromJson(json);
    }
  }

  @override
  Future<void> logout() async {
    // 先调后端登出接口，再退 Google
    try {
      await _client.post(ApiEndpoints.logout, data: {});
    } catch (_) {
      // 接口失败不影响本地登出
    }
    await _googleSignIn.signOut().catchError((_) => null);
  }

  @override
  Future<UserModel> getUserInfo() async {
    final response = await _client.get(ApiEndpoints.memberProfile);
    final json = response.data!;
    if (json['code'] != 0) throw Exception(json['msg']);
    return UserModel.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateProfile({
    String? nickname,
    required String phoneNumber,
    String address = '',
    int? addressId,
    String? avatarUrl,
  }) async {
    // 1. Update member profile
    final profileData = <String, dynamic>{'phone': phoneNumber};
    if (nickname != null && nickname.isNotEmpty) {
      profileData['nickName'] = nickname;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      profileData['avatarUrl'] = avatarUrl;
    }
    final profileRes = await _client.put(
      ApiEndpoints.memberProfile,
      data: profileData,
    );
    final profileJson = profileRes.data!;
    if (profileJson['code'] != 0) throw Exception(profileJson['msg']);

    // 2. Create or update delivery address (only if address string provided)
    if (address.isNotEmpty) {
      final addrData = {
        'label': 'Home',
        'fullAddress': address,
        'phone': phoneNumber,
        'isDefault': '1',
      };
      if (addressId != null) {
        final addrRes = await _client.put(
          ApiEndpoints.memberAddress(addressId.toString()),
          data: addrData,
        );
        final addrJson = addrRes.data!;
        if (addrJson['code'] != 0) throw Exception(addrJson['msg']);
      } else {
        final addrRes = await _client.post(
          ApiEndpoints.memberAddresses,
          data: addrData,
        );
        final addrJson = addrRes.data!;
        if (addrJson['code'] != 0) throw Exception(addrJson['msg']);
      }
    }
  }
}
