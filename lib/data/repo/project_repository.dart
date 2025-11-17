import 'dart:convert';

import 'package:drift/drift.dart';

import '../../data/local/app_database.dart';
import '../../services/api_client.dart';

class ProjectRepository {
  final AppDatabase db;
  final ApiClient api;

  ProjectRepository({required this.db, required this.api});

  /// Crea proyecto localmente y encola la operación para sincronizarla.
  Future<int> createProjectOffline({
    required String nombre,
    String? contrato,
    String? contratante,
    String? contratista,
    String? encargado,
    int? usuarioServerId,
  }) async {
    // 1) Insertar en tabla Projects
    final localId = await db.insertProject(
      ProjectsCompanion.insert(
        nombre: nombre,
        contrato: Value(contrato),
        contratante: Value(contratante),
        contratista: Value(contratista),
        encargado: Value(encargado),
        usuarioServerId: Value(usuarioServerId),
      ),
    );

    // 2) Encolar en Outbox
    final payload = jsonEncode({
      'nombre': nombre,
      'contrato': contrato,
      'contratante': contratante,
      'contratista': contratista,
      'encargado': encargado,
      'usuarioServerId': usuarioServerId,
    });

    final localRef = 'projects:$localId';

    await db.enqueueOutbox(
      OutboxCompanion.insert(
        endpoint: '/proyectos/',
        method: 'POST',
        payloadJson: payload,
        localRef: Value(localRef),
      ),
    );

    return localId;
  }

  /// Sincroniza proyectos pendientes usando el token actual del usuario.
  Future<void> syncPending({required String token}) async {
    final pending = await db.pendingOutbox();

    for (final job in pending) {
      try {
        if (!(job.endpoint == '/proyectos/' && job.method == 'POST')) {
          continue; // dejamos que otros repos manejen sus endpoints
        }

        await db.setOutboxStatus(job.id, 'in_progress');

        final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;

        final resp = await api.createProject(
          token: token,
          nombre: payload['nombre'] as String,
          contrato: payload['contrato'] as String?,
          contratante: payload['contratante'] as String?,
          contratista: payload['contratista'] as String?,
          encargado: payload['encargado'] as String?,
        );

        final serverId = resp['id'] as int?;

        if (serverId != null && job.localRef != null) {
          final parts = job.localRef!.split(':');
          if (parts.length == 2 && parts.first == 'projects') {
            final localId = int.tryParse(parts.last);
            if (localId != null) {
              await (db.update(
                db.projects,
              )..where((tbl) => tbl.id.equals(localId))).write(
                ProjectsCompanion(
                  serverId: Value(serverId),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            }
          }
        }

        await db.setOutboxStatus(job.id, 'done', error: null);
      } catch (e) {
        await db.bumpRetries(job.id, error: e.toString());
        await db.setOutboxStatus(job.id, 'pending');
      }
    }
  }

  Future<List<Project>> getAllProjects() => db.listProjects();

  Future<void> deleteLocalProjectById(int id) async {
    await db.deleteProjectById(id);
  }
}
