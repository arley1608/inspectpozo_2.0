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

  // ---------- Usuarios ----------

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

  // ---------- Proyectos ----------

  Future<Map<String, dynamic>> createProject({
    required String token,
    required String nombre,
    String? contrato,
    String? contratante,
    String? contratista,
    String? encargado,
  }) async {
    final res = await dio.post(
      '/proyectos/',
      queryParameters: {'token': token},
      data: {
        'nombre': nombre,
        'contrato': contrato,
        'contratante': contratante,
        'contratista': contratista,
        'encargado': encargado,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getProjects({
    required String token,
  }) async {
    final res = await dio.get('/proyectos/', queryParameters: {'token': token});

    final data = res.data;
    if (data is List) {
      return data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      throw Exception('Respuesta inesperada al obtener los proyectos');
    }
  }

  Future<void> deleteProject({
    required String token,
    required int serverId,
  }) async {
    await dio.delete('/proyectos/$serverId', queryParameters: {'token': token});
  }

  // ---------- Estructuras hidráulicas ----------

  Future<void> createHydraulicStructure({
    required String token,
    required String id,
    String? tipo,
    required DateTime fechaInspeccion,
    required String horaInspeccion, // "HH:mm:ss"
    String? climaInspeccion,
    String? tipoVia,
    String? tipoSistema,
    String? material,
    String? observaciones,
    required int idProyecto,
  }) async {
    await dio.post(
      '/estructuras/',
      queryParameters: {'token': token},
      data: {
        'id': id,
        'tipo': tipo,
        'fecha_inspeccion': fechaInspeccion.toIso8601String().split('T')[0],
        'hora_inspeccion': horaInspeccion,
        'clima_inspeccion': climaInspeccion,
        'tipo_via': tipoVia,
        'tipo_sistema': tipoSistema,
        'material': material,
        'observaciones': observaciones,
        'id_proyecto': idProyecto,
      },
    );
  }
}
