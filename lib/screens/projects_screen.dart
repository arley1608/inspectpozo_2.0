import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/repo/project_repository.dart';
import 'project_manage_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aún no tienes proyectos registrados.\n\n'
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
              if (contratante.isNotEmpty) {
                detalles.add('Contratante: $contratante');
              }
              if (contratista.isNotEmpty) {
                detalles.add('Contratista: $contratista');
              }
              if (encargado.isNotEmpty) {
                detalles.add('Encargado: $encargado');
              }

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
                      // fila principal: icono + nombre
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

                      // detalles alineados hacia abajo
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

                      // botón "Gestionar"
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
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
