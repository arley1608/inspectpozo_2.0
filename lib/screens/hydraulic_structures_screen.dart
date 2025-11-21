import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class HydraulicStructuresScreen extends StatefulWidget {
  final int projectServerId;
  final String projectName;

  const HydraulicStructuresScreen({
    super.key,
    required this.projectServerId,
    required this.projectName,
  });

  @override
  State<HydraulicStructuresScreen> createState() =>
      _HydraulicStructuresScreenState();
}

class _HydraulicStructuresScreenState extends State<HydraulicStructuresScreen> {
  late Future<List<Map<String, dynamic>>> _futureStructures;

  @override
  void initState() {
    super.initState();
    _loadStructures();
  }

  void _loadStructures() {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthService>();
    final token = auth.token;

    if (token == null) {
      _futureStructures = Future.error(
        'Sesión inválida. Inicia sesión nuevamente.',
      );
      return;
    }

    _futureStructures = api.getHydraulicStructures(
      token: token,
      projectServerId: widget.projectServerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Estructuras · ${widget.projectName}')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadStructures();
            setState(() {});
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureStructures,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Error al cargar estructuras:\n${snapshot.error}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                );
              }

              final structures = snapshot.data ?? [];

              if (structures.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Este proyecto aún no tiene estructuras hidráulicas registradas.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: structures.length,
                itemBuilder: (context, index) {
                  final e = structures[index];
                  final id = e['id']?.toString() ?? 'Sin id';
                  final tipo = e['tipo']?.toString() ?? 'Sin tipo';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.water_damage,
                        color: Colors.blueGrey,
                      ),
                      title: Text(
                        id,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      subtitle: Text(
                        'Tipo: $tipo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
