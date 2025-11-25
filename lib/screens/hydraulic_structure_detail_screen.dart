import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'create_pipe_screen.dart';
import 'pipe_diagram_screen.dart';
import 'pipes_for_structure_screen.dart';
import 'create_photo_record_screen.dart';

class HydraulicStructureDetailScreen extends StatefulWidget {
  final Map<String, dynamic> structure;
  final String token;

  const HydraulicStructureDetailScreen({
    super.key,
    required this.structure,
    required this.token,
  });

  @override
  State<HydraulicStructureDetailScreen> createState() =>
      _HydraulicStructureDetailScreenState();
}

class _HydraulicStructureDetailScreenState
    extends State<HydraulicStructureDetailScreen> {
  // tipo -> imagen base64
  final Map<String, String?> _photos = {
    'panoramica': null,
    'inicial': null,
    'abierto': null,
    'final': null,
  };

  bool _loadingPhotos = false;
  String? _photoError;

  Map<String, dynamic> get structure => widget.structure;

  String _stringOf(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Sí' : 'No';
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final id = structure['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() {
      _loadingPhotos = true;
      _photoError = null;
    });

    try {
      final api = ApiClient();
      final registros = await api.getPhotoRecordsForStructure(
        token: widget.token,
        estructuraId: id,
      );

      final updated = Map<String, String?>.from(_photos);
      for (final r in registros) {
        final tipo = (r['tipo'] as String?)?.toLowerCase();
        final imagenB64 = r['imagen'] as String?;
        if (tipo != null &&
            imagenB64 != null &&
            imagenB64.isNotEmpty &&
            updated.containsKey(tipo)) {
          updated[tipo] = imagenB64;
        }
      }

      if (!mounted) return;
      setState(() {
        _photos
          ..clear()
          ..addAll(updated);
        _loadingPhotos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPhotos = false;
        _photoError = 'Error cargando fotos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final id = structure['id']?.toString() ?? 'Sin id';
    final tipo = structure['tipo']?.toString() ?? 'Sin tipo';

    return Scaffold(
      appBar: AppBar(title: Text('Estructura $id')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailsColumn(theme, id, tipo),
                    const SizedBox(height: 24),
                    _buildRightPanel(context, theme, id),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildDetailsColumn(theme, id, tipo),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 320,
                    child: _buildRightPanel(context, theme, id),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==============================
  //    PANEL DERECHO ACTUALIZADO
  // ==============================

  Widget _buildRightPanel(BuildContext context, ThemeData theme, String id) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registro fotográfico',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estructura: $id',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),

            if (_photoError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _photoError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.redAccent,
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(child: _photoSlot('Panorámica', 'panoramica')),
                const SizedBox(width: 8),
                Expanded(child: _photoSlot('Inicial', 'inicial')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _photoSlot('Abierto', 'abierto')),
                const SizedBox(width: 8),
                Expanded(child: _photoSlot('Final', 'final')),
              ],
            ),

            const SizedBox(height: 16),

            // ==============================
            //   BOTÓN AGREGAR REGISTRO FOTOGRÁFICO
            // ==============================
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final tipo = structure['tipo']?.toString() ?? '';
                  final label = tipo.isEmpty ? id : '$id - $tipo';

                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreatePhotoRecordScreen(
                        estructuraId: id,
                        estructuraLabel: label,
                      ),
                    ),
                  );

                  // Recargar fotos al volver
                  if (mounted) {
                    _loadPhotos();
                  }
                },
                icon: const Icon(Icons.photo_camera),
                label: const Text('Agregar registro fotográfico'),
              ),
            ),

            const SizedBox(height: 8),

            // ==============================
            //   BOTÓN AGREGAR TUBERÍA
            // ==============================
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreatePipeScreen(structure: structure),
                    ),
                  );
                },
                icon: const Icon(Icons.device_hub),
                label: const Text('Agregar tubería'),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final tipo = structure['tipo']?.toString() ?? '';
                  final label = tipo.isEmpty ? id : '$id - $tipo';

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PipesForStructureScreen(
                        structureId: id,
                        structureLabel: label,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.linear_scale),
                label: const Text('Ver tubería'),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PipeDiagramScreen(
                        structureId: id,
                        anglesDegrees:
                            const [], // luego lo llenamos desde la BD
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.account_tree),
                label: const Text('Generar diagrama'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoSlot(String label, String tipo) {
    final b64 = _photos[tipo];

    Widget child;
    if (_loadingPhotos && b64 == null) {
      child = const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = Uint8List.fromList(base64Decode(b64));
        child = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      } catch (_) {
        child = _photoPlaceholder(label);
      }
    } else {
      child = _photoPlaceholder(label);
    }

    // 👇 Aquí se muestra el tipo ENCIMA de la foto
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _photoPlaceholder(String _label) {
    // El tipo ahora se muestra arriba; aquí dejamos solo el ícono
    return const Center(child: Icon(Icons.photo, size: 28, color: Colors.grey));
  }

  // ======================
  //   DETALLES ORIGINALES
  // ======================

  Widget _buildDetailsColumn(ThemeData theme, String id, String tipo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.water_damage, size: 40, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tipo: $tipo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _sectionTitle(theme, 'Datos básicos'),
        _infoTile('ID proyecto', _stringOf(structure['id_proyecto'])),
        _infoTile(
          'Fecha de inspección',
          _stringOf(structure['fecha_inspeccion']),
        ),
        _infoTile(
          'Hora de inspección',
          _stringOf(structure['hora_inspeccion']),
        ),
        _infoTile(
          'Clima de inspección',
          _stringOf(structure['clima_inspeccion']),
        ),
        _infoTile('Tipo de vía', _stringOf(structure['tipo_via'])),

        const SizedBox(height: 16),

        _sectionTitle(theme, 'Geometría'),
        _infoTile('Geometría (WKB/WKT)', _stringOf(structure['geometria'])),

        const SizedBox(height: 16),

        _sectionTitle(theme, 'Sistema y material'),
        _infoTile('Tipo de sistema', _stringOf(structure['tipo_sistema'])),
        _infoTile('Material', _stringOf(structure['material'])),

        const SizedBox(height: 16),

        if (tipo.toLowerCase() == 'pozo') ...[
          _sectionTitle(theme, 'Pozo'),
          _infoTile(
            'Cono de reducción',
            _stringOf(structure['cono_reduccion']),
          ),
          _infoTile('Altura del cono (m)', _stringOf(structure['altura_cono'])),
          _infoTile(
            'Profundidad del pozo (m)',
            _stringOf(structure['profundidad_pozo']),
          ),
          _infoTile(
            'Diámetro de la cámara (m)',
            _stringOf(structure['diametro_camara']),
          ),
          const SizedBox(height: 16),
        ],

        if (tipo.toLowerCase() == 'sumidero') ...[
          _sectionTitle(theme, 'Sumidero'),
          _infoTile('Tipo de sumidero', _stringOf(structure['tipo_sumidero'])),
          _infoTile(
            'Ancho sumidero (m)',
            _stringOf(structure['ancho_sumidero']),
          ),
          _infoTile(
            'Largo sumidero (m)',
            _stringOf(structure['largo_sumidero']),
          ),
          _infoTile(
            'Altura sumidero (m)',
            _stringOf(structure['altura_sumidero']),
          ),
          _infoTile(
            'Material sumidero',
            _stringOf(structure['material_sumidero']),
          ),
          _infoTile('Ancho rejilla (m)', _stringOf(structure['ancho_rejilla'])),
          _infoTile('Largo rejilla (m)', _stringOf(structure['largo_rejilla'])),
          _infoTile(
            'Altura rejilla (m)',
            _stringOf(structure['altura_rejilla']),
          ),
          _infoTile(
            'Material rejilla',
            _stringOf(structure['material_rejilla']),
          ),
          const SizedBox(height: 16),
        ],

        _sectionTitle(theme, 'Condiciones adicionales'),
        _infoTile('Sedimentación', _stringOf(structure['sedimentacion'])),
        _infoTile(
          'Cobertura tubería salida',
          _stringOf(structure['cobertura_tuberia_salida']),
        ),
        _infoTile(
          'Depósito que predomina',
          _stringOf(structure['deposito_predomina']),
        ),
        _infoTile('Flujo represado', _stringOf(structure['flujo_represado'])),
        _infoTile(
          'Nivel cubre cota salida',
          _stringOf(structure['nivel_cubre_cotasalida']),
        ),
        _infoTile(
          'Cota estructura (m)',
          _stringOf(structure['cota_estructura']),
        ),
        _infoTile(
          'Condiciones investigadas',
          _stringOf(structure['condiciones_investiga']),
        ),
        _infoTile('Observaciones', _stringOf(structure['observaciones'])),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[900],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, maxLines: 5, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
