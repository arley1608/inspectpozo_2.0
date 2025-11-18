import 'package:flutter/material.dart';

import 'create_hydraulic_structure_screen.dart';

class ProjectManageScreen extends StatelessWidget {
  final Map<String, dynamic> project;

  const ProjectManageScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nombre = (project['nombre'] ?? '').toString();
    final contrato = (project['contrato'] ?? '').toString();
    final contratante = (project['contratante'] ?? '').toString();
    final contratista = (project['contratista'] ?? '').toString();
    final encargado = (project['encargado'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar proyecto')),
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Marca de agua con el logo =====
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 0.07,
                    child: Image.asset(
                      'assets/images/app_logo.png', // ajusta ruta si es diferente
                      width: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            // ===== Contenido principal =====
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombre.isEmpty ? 'Proyecto sin nombre' : nombre,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                                    Icons.folder_open,
                                    size: 32,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      nombre.isEmpty
                                          ? 'Proyecto sin nombre'
                                          : nombre,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueGrey[900],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (contrato.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.receipt_long,
                                  label: 'Contrato',
                                  value: contrato,
                                ),
                              if (contratante.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.person,
                                  label: 'Contratante',
                                  value: contratante,
                                ),
                              if (contratista.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.business,
                                  label: 'Contratista',
                                  value: contratista,
                                ),
                              if (encargado.isNotEmpty)
                                _InfoRow(
                                  icon: Icons.engineering,
                                  label: 'Encargado',
                                  value: encargado,
                                ),

                              if (contrato.isEmpty &&
                                  contratante.isEmpty &&
                                  contratista.isEmpty &&
                                  encargado.isEmpty)
                                Text(
                                  'No hay información adicional registrada para este proyecto.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateHydraulicStructureScreen(
                                  project: project,
                                ),
                              ),
                            );
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey[900],
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
