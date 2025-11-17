import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// id en el servidor (Postgres), cuando ya sincronizó
  IntColumn get serverId => integer().nullable()();

  /// correo del usuario
  TextColumn get usuario => text()();

  /// nombre para el saludo en home
  TextColumn get nombre => text()();

  /// contraseña (texto plano por ahora)
  TextColumn get contrasenia => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get endpoint => text()();
  TextColumn get method => text()();
  TextColumn get payloadJson => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get retries => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  /// Referencia local, p.ej. "users:3"
  TextColumn get localRef => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users, Outbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openDb());

  @override
  int get schemaVersion => 1;

  // ---- Users ----
  Future<int> insertUser(UsersCompanion entry) => into(users).insert(entry);

  Future<void> markUserServerId({
    required int localId,
    required int serverId,
  }) async {
    await (update(users)..where((tbl) => tbl.id.equals(localId))).write(
      UsersCompanion(
        serverId: Value(serverId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<User>> listUsers() => select(users).get();

  // ---- Outbox ----
  Future<int> enqueueOutbox(OutboxCompanion entry) =>
      into(outbox).insert(entry);

  Future<void> setOutboxStatus(int id, String status, {String? error}) async {
    await (update(outbox)..where((o) => o.id.equals(id))).write(
      OutboxCompanion(
        status: Value(status),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> bumpRetries(int id, {String? error}) async {
    final row = await (select(
      outbox,
    )..where((o) => o.id.equals(id))).getSingleOrNull();
    final next = (row?.retries ?? 0) + 1;
    await (update(outbox)..where((o) => o.id.equals(id))).write(
      OutboxCompanion(
        retries: Value(next),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<OutboxData>> pendingOutbox() =>
      (select(outbox)..where((o) => o.status.equals('pending'))).get();
}

LazyDatabase _openDb() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'inspect_pozo.db'));
    return SqfliteQueryExecutor(path: file.path);
  });
}
