import 'package:dio/dio.dart';
import '../env.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String? token})
    : dio = Dio(
        BaseOptions(
          baseUrl: Env.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    if (token != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          },
        ),
      );
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String usuario,
    required String nombre,
    required String contrasenia,
  }) async {
    final res = await dio.post(
      '/auth/register',
      data: {'usuario': usuario, 'nombre': nombre, 'contrasenia': contrasenia},
    );
    return Map<String, dynamic>.from(res.data);
  }
}
