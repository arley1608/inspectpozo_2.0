import 'dart:io';

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

    // Geometría WKT
    String? geometria,

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
        'geometria': geometria,
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

  Future<void> deleteHydraulicStructure({
    required String token,
    required String id,
  }) async {
    await dio.delete('/estructuras/$id', queryParameters: {'token': token});
  }

  Future<Map<String, dynamic>> updateHydraulicStructure({
    required String token,
    required String id,

    // Campos generales
    String? tipo,
    String? geometria,
    String? fechaInspeccion, // "YYYY-MM-DD"
    String? horaInspeccion, // "HH:mm:ss"
    String? climaInspeccion,
    String? tipoVia,

    // Pozo / sistema
    String? tipoSistema,
    String? material,
    bool? conoReduccion,
    double? alturaCono,
    double? profundidadPozo,
    double? diametroCamara,

    // Condiciones hidráulicas / sedimentos
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

    // Rejilla
    double? anchoRejilla,
    double? largoRejilla,
    double? alturaRejilla,
    String? materialRejilla,

    // Proyecto relacionado
    int? idProyecto,
  }) async {
    final body = <String, dynamic>{};

    // Generales
    if (tipo != null) body['tipo'] = tipo;
    if (geometria != null) body['geometria'] = geometria;
    if (fechaInspeccion != null) {
      body['fecha_inspeccion'] = fechaInspeccion;
    }
    if (horaInspeccion != null) {
      body['hora_inspeccion'] = horaInspeccion;
    }
    if (climaInspeccion != null) {
      body['clima_inspeccion'] = climaInspeccion;
    }
    if (tipoVia != null) body['tipo_via'] = tipoVia;

    // Pozo / sistema
    if (tipoSistema != null) body['tipo_sistema'] = tipoSistema;
    if (material != null) body['material'] = material;
    if (conoReduccion != null) body['cono_reduccion'] = conoReduccion;
    if (alturaCono != null) body['altura_cono'] = alturaCono;
    if (profundidadPozo != null) {
      body['profundidad_pozo'] = profundidadPozo;
    }
    if (diametroCamara != null) {
      body['diametro_camara'] = diametroCamara;
    }

    // Condiciones / sedimentos
    if (sedimentacion != null) body['sedimentacion'] = sedimentacion;
    if (coberturaTuberiaSalida != null) {
      body['cobertura_tuberia_salida'] = coberturaTuberiaSalida;
    }
    if (depositoPredomina != null) {
      body['deposito_predomina'] = depositoPredomina;
    }
    if (flujoRepresado != null) body['flujo_represado'] = flujoRepresado;
    if (nivelCubreCotaSalida != null) {
      body['nivel_cubre_cotasalida'] = nivelCubreCotaSalida;
    }
    if (cotaEstructura != null) {
      body['cota_estructura'] = cotaEstructura;
    }
    if (condicionesInvestiga != null) {
      body['condiciones_investiga'] = condicionesInvestiga;
    }
    if (observaciones != null) {
      body['observaciones'] = observaciones;
    }

    // Sumidero
    if (tipoSumidero != null) body['tipo_sumidero'] = tipoSumidero;
    if (anchoSumidero != null) body['ancho_sumidero'] = anchoSumidero;
    if (largoSumidero != null) body['largo_sumidero'] = largoSumidero;
    if (alturaSumidero != null) body['altura_sumidero'] = alturaSumidero;
    if (materialSumidero != null) {
      body['material_sumidero'] = materialSumidero;
    }

    // Rejilla
    if (anchoRejilla != null) body['ancho_rejilla'] = anchoRejilla;
    if (largoRejilla != null) body['largo_rejilla'] = largoRejilla;
    if (alturaRejilla != null) body['altura_rejilla'] = alturaRejilla;
    if (materialRejilla != null) {
      body['material_rejilla'] = materialRejilla;
    }

    // Proyecto
    if (idProyecto != null) body['id_proyecto'] = idProyecto;

    final res = await dio.put(
      '/estructuras/$id',
      queryParameters: {'token': token},
      data: body,
    );

    return Map<String, dynamic>.from(res.data);
  }

  // ---------- Tuberías ----------

  Future<void> createPipe({
    required String token,
    required String id,
    double? diametro, // pulgadas
    String? material,
    required bool flujo, // booleano
    String? estado,
    required bool sedimento,
    double? cotaClaveInicio,
    double? cotaBateaInicio,
    double? profundidadClaveInicio,
    double? profundidadBateaInicio,
    double? cotaClaveDestino,
    double? cotaBateaDestino,
    double? profundidadClaveDestino,
    double? profundidadBateaDestino,
    double? grados,
    String? observaciones,
    required String idEstructuraInicio,
    required String idEstructuraDestino,
  }) async {
    await dio.post(
      '/tuberias/',
      queryParameters: {'token': token},
      data: {
        'id': id,
        'diametro': diametro,
        'material': material,
        'flujo': flujo,
        'estado': estado,
        'sedimento': sedimento,
        'cota_clave_inicio': cotaClaveInicio,
        'cota_batea_inicio': cotaBateaInicio,
        'profundidad_clave_inicio': profundidadClaveInicio,
        'profundidad_batea_inicio': profundidadBateaInicio,
        'cota_clave_destino': cotaClaveDestino,
        'cota_batea_destino': cotaBateaDestino,
        'profundidad_clave_destino': profundidadClaveDestino,
        'profundidad_batea_destino': profundidadBateaDestino,
        'grados': grados,
        'observaciones': observaciones,
        'id_estructura_inicio': idEstructuraInicio,
        'id_estructura_destino': idEstructuraDestino,
      },
    );
  }

  Future<Map<String, dynamic>> updatePipe({
    required String token,
    required String id,
    double? diametro,
    String? material,
    bool? flujo,
    String? estado,
    bool? sedimento,
    double? cotaClaveInicio,
    double? cotaBateaInicio,
    double? profundidadClaveInicio,
    double? profundidadBateaInicio,
    double? cotaClaveDestino,
    double? cotaBateaDestino,
    double? profundidadClaveDestino,
    double? profundidadBateaDestino,
    double? grados,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{};

    if (diametro != null) body['diametro'] = diametro;
    if (material != null) body['material'] = material;
    if (flujo != null) body['flujo'] = flujo;
    if (estado != null) body['estado'] = estado;
    if (sedimento != null) body['sedimento'] = sedimento;

    if (cotaClaveInicio != null) body['cota_clave_inicio'] = cotaClaveInicio;
    if (cotaBateaInicio != null) body['cota_batea_inicio'] = cotaBateaInicio;
    if (profundidadClaveInicio != null) {
      body['profundidad_clave_inicio'] = profundidadClaveInicio;
    }
    if (profundidadBateaInicio != null) {
      body['profundidad_batea_inicio'] = profundidadBateaInicio;
    }

    if (cotaClaveDestino != null) body['cota_clave_destino'] = cotaClaveDestino;
    if (cotaBateaDestino != null) body['cota_batea_destino'] = cotaBateaDestino;
    if (profundidadClaveDestino != null) {
      body['profundidad_clave_destino'] = profundidadClaveDestino;
    }
    if (profundidadBateaDestino != null) {
      body['profundidad_batea_destino'] = profundidadBateaDestino;
    }

    if (grados != null) body['grados'] = grados;
    if (observaciones != null) body['observaciones'] = observaciones;

    final res = await dio.put(
      '/tuberias/$id',
      queryParameters: {'token': token},
      data: body,
    );

    return Map<String, dynamic>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getPipesForStructure({
    required String token,
    required String estructuraId,
  }) async {
    final res = await dio.get(
      '/tuberias/$estructuraId',
      queryParameters: {'token': token},
    );

    final data = res.data;
    if (data is List) {
      return data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      throw Exception('Respuesta inesperada al obtener las tuberías');
    }
  }

  Future<void> deletePipe({
    required String token,
    required String pipeId,
  }) async {
    await dio.delete('/tuberias/$pipeId', queryParameters: {'token': token});
  }

  Future<String> getNextPipeId({required String token}) async {
    final res = await dio.get(
      '/tuberias/next-id',
      queryParameters: {'token': token},
    );

    final data = res.data;
    if (data is Map && data['id'] is String) {
      return data['id'] as String;
    } else {
      throw Exception(
        'Respuesta inesperada al solicitar el siguiente ID de tubería',
      );
    }
  }

  Future<Map<String, dynamic>> getProjectMapData({
    required String token,
    required int projectId,
  }) async {
    final res = await dio.get(
      '/proyectos/$projectId/map-data',
      queryParameters: {'token': token},
    );

    final data = res.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Respuesta inesperada al obtener datos de mapa');
    }
  }

  // ---------- Registro fotográfico ----------

  Future<Map<String, dynamic>> uploadPhotoRecord({
    required String token,
    required String estructuraId,
    required String tipo, // 'panoramica' | 'inicial' | 'abierto' | 'final'
    required File file,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'id_estructura': estructuraId,
      'tipo': tipo,
      // el backend sólo espera id_estructura, tipo y file
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final res = await dio.post(
      '/registros-fotograficos/',
      queryParameters: {'token': token},
      data: formData,
    );

    return Map<String, dynamic>.from(res.data);
  }

  /// Lista los registros fotográficos para una estructura.
  /// El backend devuelve `imagen` en base64.
  Future<List<Map<String, dynamic>>> getPhotoRecordsForStructure({
    required String token,
    required String estructuraId,
  }) async {
    final res = await dio.get(
      '/estructuras/$estructuraId/registros-fotograficos',
      queryParameters: {'token': token},
    );

    final data = res.data;
    if (data is List) {
      return data
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      throw Exception(
        'Respuesta inesperada al obtener los registros fotográficos',
      );
    }
  }
}
