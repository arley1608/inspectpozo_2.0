import 'package:flutter/material.dart';

class HydraulicStructureDetailScreen extends StatelessWidget {
  final Map<String, dynamic> structure;

  const HydraulicStructureDetailScreen({super.key, required this.structure});

  String _stringOf(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Sí' : 'No';
    return value.toString();
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_damage,
                    size: 40,
                    color: Colors.blueGrey,
                  ),
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

              // ==== Datos básicos ====
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

              // ==== Geometría ====
              _sectionTitle(theme, 'Geometría'),
              _infoTile(
                'Geometría (WKB/WKT)',
                _stringOf(structure['geometria']),
              ),

              const SizedBox(height: 16),

              // ==== Sistema y material ====
              _sectionTitle(theme, 'Sistema y material'),
              _infoTile(
                'Tipo de sistema',
                _stringOf(structure['tipo_sistema']),
              ),
              _infoTile('Material', _stringOf(structure['material'])),

              const SizedBox(height: 16),

              // ==== Pozo ====
              if (tipo.toLowerCase() == 'pozo') ...[
                _sectionTitle(theme, 'Pozo'),
                _infoTile(
                  'Cono de reducción',
                  _stringOf(structure['cono_reduccion']),
                ),
                _infoTile(
                  'Altura del cono (m)',
                  _stringOf(structure['altura_cono']),
                ),
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

              // ==== Sumidero ====
              if (tipo.toLowerCase() == 'sumidero') ...[
                _sectionTitle(theme, 'Sumidero'),
                _infoTile(
                  'Tipo de sumidero',
                  _stringOf(structure['tipo_sumidero']),
                ),
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
                _infoTile(
                  'Ancho rejilla (m)',
                  _stringOf(structure['ancho_rejilla']),
                ),
                _infoTile(
                  'Largo rejilla (m)',
                  _stringOf(structure['largo_rejilla']),
                ),
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

              // ==== Condiciones adicionales ====
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
              _infoTile(
                'Flujo represado',
                _stringOf(structure['flujo_represado']),
              ),
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
          ),
        ),
      ),
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
