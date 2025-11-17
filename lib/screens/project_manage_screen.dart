import 'package:flutter/material.dart';

class ProjectManageScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectManageScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = (project['nombre'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar proyecto')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título con el nombre del proyecto
                Text(
                  nombre.isEmpty ? 'Proyecto sin nombre' : nombre,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[900],
                  ),
                ),
                const SizedBox(height: 24),

                // Botón principal: Agregar estructura hidráulica
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Aquí implementaremos la navegación
                    // hacia la pantalla de creación de estructura hidráulica.
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Agregar estructura hidráulica'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
