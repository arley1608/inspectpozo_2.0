import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'data/local/app_database.dart';
import 'data/repo/user_repository.dart';
import 'data/repo/project_repository.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  const storage = FlutterSecureStorage();
  final api = ApiClient();

  final userRepo = UserRepository(db: db, api: api);
  final projectRepo = ProjectRepository(db: db, api: api);

  // Sync de usuarios (como ya lo tenías)
  final sync = SyncService(userRepo);
  sync.start();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<ApiClient>.value(value: api),
        Provider<UserRepository>.value(value: userRepo),
        Provider<ProjectRepository>.value(value: projectRepo),
        Provider<SyncService>.value(value: sync),
        Provider<FlutterSecureStorage>.value(value: storage),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(storage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'inspect_pozo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: auth.isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
