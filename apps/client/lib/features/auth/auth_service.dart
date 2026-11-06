import '../../core/api_client.dart';
import '../../core/token_storage.dart';

class AuthService {
  AuthService(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<void> register(String email, String password) async {
    final result = await _api.post('/auth/register', {'email': email, 'password': password}, auth: false);
    await _tokenStorage.saveTokens(accessToken: result['accessToken'], refreshToken: result['refreshToken']);
  }

  Future<void> login(String email, String password) async {
    final result = await _api.post('/auth/login', {'email': email, 'password': password}, auth: false);
    await _tokenStorage.saveTokens(accessToken: result['accessToken'], refreshToken: result['refreshToken']);
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null;
  }

  Future<void> logout() => _tokenStorage.clear();
}
