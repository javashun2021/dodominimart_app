import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'web_storage_util.dart';

class StorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'saved_username';
  static const _termsAgreedKey = 'terms_agreed';

  // flutter_secure_storage 在 web 端的 localStorage key 前缀
  static const _webPrefix = 'FlutterSecureStorage';

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<String?> getSavedUsername() => _storage.read(key: _usernameKey);

  Future<void> saveUsername(String username) =>
      _storage.write(key: _usernameKey, value: username);

  Future<bool> hasAgreedToTerms() async {
    final val = await _storage.read(key: _termsAgreedKey);
    return val == 'true';
  }

  Future<void> saveTermsAgreed() async {
    await _storage.write(key: _termsAgreedKey, value: 'true');
  }

  Future<void> clearAll() async {
    // 先走 secure storage 的删除
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    // Web 端直接删 localStorage，防止 secure_storage 删不干净
    clearLocalStorageKeys([
      _webPrefix,
      '$_webPrefix.$_tokenKey',
      '$_webPrefix.$_usernameKey',
    ]);
  }
}
