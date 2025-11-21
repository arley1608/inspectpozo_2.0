import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/repo/project_repository.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import 'project_manage_screen.dart';
import 'edit_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<Project>> _futureProjects;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    final repo = Provider.of<ProjectRepository>(context, listen: false);
    _futureProjects = repo.getAllProjects();
  }

  Future<void> _deleteProject(Project project) async {
    final repo = context.read<ProjectRepository>();
    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();
    final theme = Theme.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Seguro que deseas eliminar el proyecto "${project.nombre}"?\n\n'
          'Esta acción eliminará el registro local y, si ya fue sincronizado, '
          'también lo eliminará del servidor.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final serverId = project.serverId;
    final token = auth.token;

    if (serverId != null && token != null) {
      try {
        await api.deleteProject(token: token, serverId: serverId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar en el servidor: $e')),
        );
        return;
      }
    }

    await repo.deleteLocalProjectById(project.id);

    _loadProjects();
    if (!mounted) return;
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proyecto eliminado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthService>();
    final currentUserId = auth.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Proyectos activos')),
      body: FutureBuilder<List<Project>>(
        future: _futureProjects,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al cargar proyectos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                  ),
                ),
              ),
            );
          }

          var projects = snapshot.data ?? [];

          if (currentUserId != null) {
            projects = projects
                .where((p) => p.usuarioServerId == currentUserId)
                .toList();
          }

          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aún no tienes proyectos registrados para tu usuario.\n\n'
                  'Crea un nuevo proyecto desde la pantalla de inicio.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];

              final nombre = p.nombre;
              final contrato = p.contrato ?? '';
              final contratante = p.contratante ?? '';
              final contratista = p.contratista ?? '';
              final encargado = p.encargado ?? '';

              final detalles = <String>[];
              if (contrato.isNotEmpty) detalles.add('Contrato: $contrato');
              if (contratante.isNotEmpty)
                detalles.add('Contratante: $contratante');
              if (contratista.isNotEmpty)
                detalles.add('Contratista: $contratista');
              if (encargado.isNotEmpty) detalles.add('Encargado: $encargado');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.folder,
                            size: 32,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nombre.isEmpty ? 'Proyecto sin nombre' : nombre,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (detalles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final d in detalles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2.0),
                                child: Text(
                                  d,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProjectManageScreen(project: p.toJson()),
                                ),
                              );
                            },
                            icon: const Icon(Icons.manage_accounts),
                            label: const Text('Gestionar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditProjectScreen(project: p),
                                ),
                              );

                              if (result == true) {
                                _loadProjects();
                                if (mounted) setState(() {});
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Modificar'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _deleteProject(p),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Eliminar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
