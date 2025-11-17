import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../env.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  late final Dio _dio;

  String? _token;
  bool _isLoading = true;

  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthService(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Agrega Bearer a cada request si hay token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );

    _restoreToken();
  }

  Future<void> _restoreToken() async {
    _token = await _storage.read(key: 'token');
    _isLoading = false;
    notifyListeners();
  }

  /// Login (POST /auth/login) - espera {access_token}
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        options: Options(contentType: Headers.formUrlEncodedContentType),
        data: {'username': username, 'password': password},
      );
      final token = res.data['access_token'] as String?;
      if (token == null) return 'Respuesta inválida del servidor';
      _token = token;
      await _storage.write(key: 'token', value: _token);
      notifyListeners();
      return null;
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) return 'Credenciales inválidas';
      return 'Error de red: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Registro (POST /auth/register) - body JSON
  Future<String?> register({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {'usuario': username, 'contrasenia': password},
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return 'Error inesperado (${res.statusCode})';
    } on DioError catch (e) {
      if (e.response?.statusCode == 409) return 'El usuario ya existe';
      return 'Error de red: ${e.message}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Perfil (GET /auth/me) - opcional para mostrar nombre
  Future<Map<String, dynamic>?> me() async {
    if (_token == null) return null;
    final res = await _dio.get(
      '/auth/me',
      queryParameters: {
        // si tu backend recibe token por query param (como te dejé),
        // si lo cambias a header Authorization ya lo adjunta el interceptor.
        'token': _token,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
