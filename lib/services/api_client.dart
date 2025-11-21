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

  /// Actualizar proyecto en el servidor
  Future<Map<String, dynamic>> updateProject({
    required String token,
    required int serverId,
    String? nombre,
    String? contrato,
    String? contratante,
    String? contratista,
    String? encargado,
  }) async {
    final body = <String, dynamic>{};

    if (nombre != null) body['nombre'] = nombre;
    if (contrato != null) body['contrato'] = contrato;
    if (contratante != null) body['contratante'] = contratante;
    if (contratista != null) body['contratista'] = contratista;
    if (encargado != null) body['encargado'] = encargado;

    final res = await dio.put(
      '/proyectos/$serverId',
      queryParameters: {'token': token},
      data: body,
    );

    return Map<String, dynamic>.from(res.data);
  }

  // ---------- Estructuras hidráulicas ----------

  Future<void> createHydraulicStructure({
    required String token,
    required String id,
    required String tipo, // "Pozo" o "Sumidero"
    required DateTime fechaInspeccion,
    required String horaInspeccion, // "HH:mm:ss"
    String? climaInspeccion,
    String? tipoVia,

    // Pozo
    required String tipoSistema,
    String? material,
    bool? conoReduccion,
    double? alturaCono,
    double? profundidadPozo,
    double? diametroCamara,
    String? elementosPozo,
    String? estadoElemento,
    String? materialElemento,

    // Compartidos extra
    bool? sedimentacion,
    bool? coberturaTuberiaSalida,
    String? depositoPredomina,
    bool? flujoRepresado,
    bool? nivelCubreCotaSalida,
    double? cotaEstructura,
    String? condicionesInvestiga,
    String? observaciones,

    // Sumidero
    String? tipoSumidero,
    double? anchoSumidero,
    double? largoSumidero,
    double? alturaSumidero,
    String? materialSumidero,
    double? anchoRejilla,
    double? largoRejilla,
    double? alturaRejilla,
    String? materialRejilla,

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
        'cono_reduccion': conoReduccion,
        'altura_cono': alturaCono,
        'profundidad_pozo': profundidadPozo,
        'diametro_camara': diametroCamara,
        'sedimentacion': sedimentacion,
        'cobertura_tuberia_salida': coberturaTuberiaSalida,
        'deposito_predomina': depositoPredomina,
        'flujo_represado': flujoRepresado,
        'nivel_cubre_cotasalida': nivelCubreCotaSalida,
        'cota_estructura': cotaEstructura,
        'condiciones_investiga': condicionesInvestiga,
        'observaciones': observaciones,
        'tipo_sumidero': tipoSumidero,
        'ancho_sumidero': anchoSumidero,
        'largo_sumidero': largoSumidero,
        'altura_sumidero': alturaSumidero,
        'material_sumidero': materialSumidero,
        'ancho_rejilla': anchoRejilla,
        'largo_rejilla': largoRejilla,
        'altura_rejilla': alturaRejilla,
        'material_rejilla': materialRejilla,
        'id_proyecto': idProyecto,
      },
    );
  }

  Future<String> getNextHydraulicStructureId({
    required String token,
    required String tipo, // "Pozo" o "Sumidero"
  }) async {
    final res = await dio.get(
      '/estructuras/next-id',
      queryParameters: {'token': token, 'tipo': tipo},
    );

    final data = res.data;
    if (data is Map && data['id'] is String) {
      return data['id'] as String;
    } else {
      throw Exception('Respuesta inesperada al solicitar el siguiente ID');
    }
  }

  /// 🔹 NUEVO: obtener lista de estructuras hidráulicas por proyecto
  Future<List<Map<String, dynamic>>> getHydraulicStructures({
    required String token,
    required int projectServerId,
  }) async {
    final res = await dio.get(
      '/estructuras/',
      queryParameters: {'token': token, 'id_proyecto': projectServerId},
    );

    final data = res.data;
    if (data is List) {
      return data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      throw Exception('Respuesta inesperada al obtener las estructuras');
    }
  }
}
