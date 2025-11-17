import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../env.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage;

  String? _token;
  bool _loading = true;

  AuthService(this._storage) {
    _loadToken();
  }

  static const _tokenKey = 'auth_token';

  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null;

  /// 👉 Para que otras partes (HomeScreen, repos) puedan usar el token
  String? get token => _token;

  Future<void> _loadToken() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } catch (_) {
      _token = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Login contra el backend.
  /// El backend está esperando "username" y "password"
  /// en formato application/x-www-form-urlencoded.
  Future<void> login({
    required String usuario,
    required String contrasenia,
  }) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl, // ej: http://192.168.0.34:8000
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      final res = await dio.post(
        '/auth/login',
        data: {
          // 👇 Lo que espera FastAPI (OAuth2PasswordRequestForm)
          'username': usuario,
          'password': contrasenia,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = res.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token no recibido desde el servidor');
      }

      _token = accessToken;
      await _storage.write(key: _tokenKey, value: _token);
      notifyListeners();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception('Error de login: $msg');
    } catch (e) {
      rethrow;
    }
  }

  /// Consulta /auth/me usando el token como query param: ?token=...
  Future<Map<String, dynamic>?> me() async {
    if (_token == null) return null;

    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      final res = await dio.get('/auth/me', queryParameters: {'token': _token});
      if (res.data == null) return null;
      return Map<String, dynamic>.from(res.data);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cierra sesión, borra token de memoria y del almacenamiento seguro
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
