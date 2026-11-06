import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// URL du backend. `localhost` fonctionne sur Web et Windows/macOS (desktop).
/// Pour un émulateur Android, surcharger avec --dart-define=API_URL=http://10.0.2.2:3001 ;
/// pour un appareil physique, utiliser l'adresse LAN de la machine qui héberge le backend.
class ApiClient {
  ApiClient(this._tokenStorage);

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3001',
  );

  final TokenStorage _tokenStorage;

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _parse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    } catch (_) {
      // corps non-JSON, on garde le texte brut
    }
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    return _parse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    return _parse(response);
  }
}
