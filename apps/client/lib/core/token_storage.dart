import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé des jetons (Keychain/Keystore/DPAPI selon la plateforme).
class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'swvertex_access_token';
  static const _refreshKey = 'swvertex_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
