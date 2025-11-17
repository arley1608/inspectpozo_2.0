import 'dart:convert';
import 'package:drift/drift.dart';

import '../../data/local/app_database.dart';
import '../../services/api_client.dart';

class UserRepository {
  final AppDatabase db;
  final ApiClient api;

  UserRepository({required this.db, required this.api});

  /// Crea usuario local y encola la operación para el servidor
  Future<int> createUserOffline({
    required String usuario,
    required String nombre,
    required String contrasenia,
  }) async {
    final localId = await db.insertUser(
      UsersCompanion.insert(
        usuario: usuario,
        nombre: Value(nombre),
        contrasenia: contrasenia,
      ),
    );

    final payload = jsonEncode({
      'usuario': usuario,
      'nombre': nombre,
      'contrasenia': contrasenia,
    });

    final localRef = 'users:$localId';

    await db.enqueueOutbox(
      OutboxCompanion.insert(
        endpoint: '/auth/register',
        method: 'POST',
        payloadJson: payload,
        localRef: Value(localRef),
      ),
    );

    return localId;
  }

  /// Sincroniza SOLO los jobs relacionados con usuarios (/auth/register)
  Future<void> syncPending() async {
    final pending = await db.pendingOutbox();

    for (final job in pending) {
      try {
        // ignorar jobs que no sean de usuarios
        if (!(job.endpoint == '/auth/register' && job.method == 'POST')) {
          continue;
        }

        await db.setOutboxStatus(job.id, 'in_progress');
        final payload = jsonDecode(job.payloadJson) as Map<String, dynamic>;

        final resp = await api.registerUser(
          usuario: payload['usuario'] as String,
          nombre: payload['nombre'] as String,
          contrasenia: payload['contrasenia'] as String,
        );

        final serverId = resp['id'] as int?;

        if (serverId != null && job.localRef != null) {
          final parts = job.localRef!.split(':');
          if (parts.length == 2 && parts.first == 'users') {
            final localId = int.tryParse(parts.last);
            if (localId != null) {
              await db.markUserServerId(localId: localId, serverId: serverId);
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

  Future<List<User>> listUsers() => db.listUsers();
}
