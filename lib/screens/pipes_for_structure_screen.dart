import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class PipesForStructureScreen extends StatefulWidget {
  final String structureId;
  final String structureLabel;

  const PipesForStructureScreen({
    super.key,
    required this.structureId,
    required this.structureLabel,
  });

  @override
  State<PipesForStructureScreen> createState() =>
      _PipesForStructureScreenState();
}

class _PipesForStructureScreenState extends State<PipesForStructureScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _pipes = [];

  @override
  void initState() {
    super.initState();
    _loadPipes();
  }

  Future<void> _loadPipes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      final api = context.read<ApiClient>();
      final token = auth.token;

      if (token == null) {
        setState(() {
          _loading = false;
          _error = 'Sesión inválida. Inicia sesión nuevamente.';
        });
        return;
      }

      final list = await api.getPipesForStructure(
        token: token,
        estructuraId: widget.structureId,
      );

      setState(() {
        _pipes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error al cargar tuberías: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Tuberías de ${widget.structureId}')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            : _pipes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay tuberías asociadas a esta estructura.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _pipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pipe = _pipes[index];

                  final id = pipe['id']?.toString() ?? 'Sin ID';
                  final diametro = pipe['diametro'];
                  final material = pipe['material']?.toString() ?? '—';
                  final estado = pipe['estado']?.toString() ?? '—';
                  final grados = pipe['grados'];

                  final idInicio =
                      pipe['id_estructura_inicio']?.toString() ?? '';
                  final idDestino =
                      pipe['id_estructura_destino']?.toString() ?? '';

                  final bool esSalida = idInicio == widget.structureId;
                  final bool esEntrada = idDestino == widget.structureId;

                  String rol;
                  IconData icono;
                  Color? color;

                  if (esSalida) {
                    rol = 'Tubería de salida';
                    icono = Icons.arrow_outward;
                    color = Colors.green[700];
                  } else if (esEntrada) {
                    rol = 'Tubería de entrada';
                    icono = Icons.arrow_back;
                    color = Colors.blueGrey[700];
                  } else {
                    rol = 'Tubería relacionada';
                    icono = Icons.linear_scale;
                    color = Colors.grey[700];
                  }

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color?.withOpacity(0.15),
                        child: Icon(icono, color: color),
                      ),
                      title: Text(
                        id,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            rol,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Diámetro: '
                            '${diametro != null ? '$diametro"' : '—'}'
                            ' • Material: $material',
                          ),
                          Text(
                            'Estado: $estado'
                            '${grados != null ? ' • Grados: $grados°' : ''}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
