import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../data/repo/project_repository.dart';
import 'create_project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    final auth = context.read<AuthService>();
    final me = await auth.me();

    // intentar sincronizar proyectos si tenemos token
    final token = auth.token;
    if (token != null) {
      final projectRepo = context.read<ProjectRepository>();
      try {
        await projectRepo.syncPending(token: token);
      } catch (_) {
        // si falla (sin internet, etc.), simplemente se quedan pendientes
      }
    }

    if (!mounted) return;
    setState(() {
      _me = me;
      _loading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final auth = context.read<AuthService>();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await auth.logout();
      // MyApp se encargará de mostrar la pantalla de login
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final name = (_me?['nombre']?.toString().trim().isNotEmpty ?? false)
        ? _me!['nombre'].toString().trim()
        : (_me?['usuario']?.toString().trim().isNotEmpty ?? false)
        ? _me!['usuario'].toString().trim()
        : 'Usuario';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Saludo centrado arriba
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Text(
                _loading ? 'Cargando…' : '👋 Bienvenido, $name',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
            ),

            // Contenido principal (logo + botones)
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/logo_inspectpozo.png',
                          height: size.height * 0.22,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const FlutterLogo(size: 100),
                        ),
                        const SizedBox(height: 60),

                        // Botón primario: Crear nuevo proyecto
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateProjectScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Crear nuevo proyecto'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón secundario: Proyectos activos (por ahora sin lógica)
                        OutlinedButton.icon(
                          onPressed: () {
                            // Aquí luego conectamos la lista de proyectos
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Proyectos activos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Botón de cerrar sesión con confirmación
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
