import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../env.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage;

  String? _token;
  bool _loading = true;

  int? _userId;
  String? _userUsuario;
  String? _userNombre;

  AuthService(this._storage) {
    _loadFromStorage();
  }

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userUsuarioKey = 'user_usuario';
  static const _userNombreKey = 'user_nombre';

  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null;

  String? get token => _token;

  int? get currentUserId => _userId;
  String? get currentUserUsuario => _userUsuario;
  String? get currentUserNombre => _userNombre;

  Future<void> _loadFromStorage() async {
    try {
      _token = await _storage.read(key: _tokenKey);

      final idStr = await _storage.read(key: _userIdKey);
      if (idStr != null) {
        final parsed = int.tryParse(idStr);
        if (parsed != null) _userId = parsed;
      }

      _userUsuario = await _storage.read(key: _userUsuarioKey);
      _userNombre = await _storage.read(key: _userNombreKey);
    } catch (_) {
      _token = null;
      _userId = null;
      _userUsuario = null;
      _userNombre = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<bool> login({
    required String usuario,
    required String contrasenia,
  }) async {
    final dio = _buildDio();

    try {
      final res = await dio.post(
        '/auth/login',
        data: {'username': usuario, 'password': contrasenia},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (res.statusCode == 200 && res.data != null) {
        final data = Map<String, dynamic>.from(res.data);
        final token = data['access_token'] as String?;

        if (token == null || token.isEmpty) {
          return false;
        }

        _token = token;
        await _storage.write(key: _tokenKey, value: token);

        await _fetchAndCacheMe();

        notifyListeners();
        return true;
      }

      return false;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchAndCacheMe() async {
    if (_token == null) return;

    final dio = _buildDio();

    try {
      final res = await dio.get('/auth/me', queryParameters: {'token': _token});

      if (res.data == null) return;

      final data = Map<String, dynamic>.from(res.data);
      final id = data['id'];
      final usuario = data['usuario']?.toString();
      final nombre = data['nombre']?.toString();

      if (id is int) {
        _userId = id;
        await _storage.write(key: _userIdKey, value: id.toString());
      }

      _userUsuario = usuario;
      _userNombre = nombre;

      if (usuario != null) {
        await _storage.write(key: _userUsuarioKey, value: usuario);
      }
      if (nombre != null) {
        await _storage.write(key: _userNombreKey, value: nombre);
      }

      notifyListeners();
    } on DioException {
      // ignoramos errores
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> me() async {
    if (_userId != null || _userUsuario != null || _userNombre != null) {
      return {'id': _userId, 'usuario': _userUsuario, 'nombre': _userNombre};
    }

    if (_token == null) return null;

    final dio = _buildDio();

    try {
      final res = await dio.get('/auth/me', queryParameters: {'token': _token});

      if (res.data == null) return null;

      final data = Map<String, dynamic>.from(res.data);
      final id = data['id'];
      final usuario = data['usuario']?.toString();
      final nombre = data['nombre']?.toString();

      if (id is int) {
        _userId = id;
        await _storage.write(key: _userIdKey, value: id.toString());
      }

      _userUsuario = usuario;
      _userNombre = nombre;

      if (usuario != null) {
        await _storage.write(key: _userUsuarioKey, value: usuario);
      }
      if (nombre != null) {
        await _storage.write(key: _userNombreKey, value: nombre);
      }

      notifyListeners();
      return {'id': _userId, 'usuario': _userUsuario, 'nombre': _userNombre};
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userUsuario = null;
    _userNombre = null;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userUsuarioKey);
    await _storage.delete(key: _userNombreKey);

    notifyListeners();
  }
}
