import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class CreateHydraulicStructureScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const CreateHydraulicStructureScreen({super.key, required this.project});

  @override
  State<CreateHydraulicStructureScreen> createState() =>
      _CreateHydraulicStructureScreenState();
}

class _CreateHydraulicStructureScreenState
    extends State<CreateHydraulicStructureScreen> {
  final _formKey = GlobalKey<FormState>();

  // ----------- Campos básicos / compartidos -----------
  String? _tipo; // Pozo / Sumidero
  String? _generatedId;

  DateTime? _fechaInspeccion;
  TimeOfDay? _horaInspeccion;

  final _climaCtrl = TextEditingController();
  final _tipoViaCtrl = TextEditingController();

  // Lat / Long
  final _latitudCtrl = TextEditingController();
  final _longitudCtrl = TextEditingController();

  final _tipoSistemaCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();

  bool _sedimentacion = false;
  bool _coberturaTuberiaSalida = false;
  bool _flujoRepresado = false;
  bool _nivelCubreCotaSalida = false;

  final _depositoPredominaCtrl = TextEditingController();
  final _cotaEstructuraCtrl = TextEditingController();
  final _condicionesInvestigaCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // ----------- Campos Pozo -----------
  bool _conoReduccion = false;
  final _alturaConoCtrl = TextEditingController();
  final _profundidadPozoCtrl = TextEditingController();
  final _diametroCamaraCtrl = TextEditingController();

  // ----------- Campos Sumidero -----------
  final _tipoSumideroCtrl = TextEditingController();
  final _anchoSumideroCtrl = TextEditingController();
  final _largoSumideroCtrl = TextEditingController();
  final _alturaSumideroCtrl = TextEditingController();
  final _materialSumideroCtrl = TextEditingController();

  final _anchoRejillaCtrl = TextEditingController();
  final _largoRejillaCtrl = TextEditingController();
  final _alturaRejillaCtrl = TextEditingController();
  final _materialRejillaCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tipo = 'Pozo'; // valor por defecto
    _fetchNextId();
  }

  @override
  void dispose() {
    _climaCtrl.dispose();
    _tipoViaCtrl.dispose();
    _latitudCtrl.dispose();
    _longitudCtrl.dispose();
    _tipoSistemaCtrl.dispose();
    _materialCtrl.dispose();
    _depositoPredominaCtrl.dispose();
    _cotaEstructuraCtrl.dispose();
    _condicionesInvestigaCtrl.dispose();
    _observacionesCtrl.dispose();

    _alturaConoCtrl.dispose();
    _profundidadPozoCtrl.dispose();
    _diametroCamaraCtrl.dispose();

    _tipoSumideroCtrl.dispose();
    _anchoSumideroCtrl.dispose();
    _largoSumideroCtrl.dispose();
    _alturaSumideroCtrl.dispose();
    _materialSumideroCtrl.dispose();

    _anchoRejillaCtrl.dispose();
    _largoRejillaCtrl.dispose();
    _alturaRejillaCtrl.dispose();
    _materialRejillaCtrl.dispose();

    super.dispose();
  }

  // ---------- Helpers ----------

  double? _toDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  String? _formatHora(TimeOfDay? t) {
    if (t == null) return null;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  // 👉 Construir WKT POINT(long lat)
  String? _buildGeometria() {
    final lat = _toDouble(_latitudCtrl.text);
    final lon = _toDouble(_longitudCtrl.text);
    if (lat == null || lon == null) return null;
    return 'POINT($lon $lat)';
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: _fechaInspeccion ?? now,
    );
    if (picked != null) {
      setState(() {
        _fechaInspeccion = picked;
      });
    }
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInspeccion ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaInspeccion = picked;
      });
    }
  }

  Future<void> _fetchNextId() async {
    final auth = context.read<AuthService>();
    final token = auth.token;
    if (token == null || _tipo == null) return;

    try {
      final api = context.read<ApiClient>();
      final nextId = await api.getNextHydraulicStructureId(
        token: token,
        tipo: _tipo!,
      );
      setState(() {
        _generatedId = nextId;
      });
    } catch (_) {
      // en caso de error dejamos el ID como está
    }
  }

  // ---------- Guardar estructura ----------

  Future<void> _save() async {
    if (_tipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de estructura')),
      );
      return;
    }

    if (_fechaInspeccion == null || _horaInspeccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar fecha y hora de inspección'),
        ),
      );
      return;
    }

    if (_generatedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el ID de la estructura'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final token = auth.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión de nuevo'),
        ),
      );
      return;
    }

    final serverId = widget.project['serverId'] as int?;
    if (serverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este proyecto aún no está sincronizado')),
      );
      return;
    }

    // Construimos geometría WKT
    final geometriaWkt = _buildGeometria();

    setState(() {
      _saving = true;
    });

    try {
      final api = context.read<ApiClient>();

      await api.createHydraulicStructure(
        token: token,
        id: _generatedId!,
        tipo: _tipo!,
        fechaInspeccion: _fechaInspeccion!,
        horaInspeccion: _formatHora(_horaInspeccion!)!,
        climaInspeccion: _climaCtrl.text.trim().isEmpty
            ? null
            : _climaCtrl.text.trim(),
        tipoVia: _tipoViaCtrl.text.trim().isEmpty
            ? null
            : _tipoViaCtrl.text.trim(),

        // 👉 Enviamos geometría al backend
        geometria: geometriaWkt,

        tipoSistema: _tipoSistemaCtrl.text.trim(),
        material: _materialCtrl.text.trim().isEmpty
            ? null
            : _materialCtrl.text.trim(),

        // Pozo
        conoReduccion: _tipo == 'Pozo' ? _conoReduccion : null,
        alturaCono: _tipo == 'Pozo' ? _toDouble(_alturaConoCtrl.text) : null,
        profundidadPozo: _tipo == 'Pozo'
            ? _toDouble(_profundidadPozoCtrl.text)
            : null,
        diametroCamara: _tipo == 'Pozo'
            ? _toDouble(_diametroCamaraCtrl.text)
            : null,

        // Compartidos
        sedimentacion: _sedimentacion,
        coberturaTuberiaSalida: _coberturaTuberiaSalida,
        depositoPredomina: _depositoPredominaCtrl.text.trim().isEmpty
            ? null
            : _depositoPredominaCtrl.text.trim(),
        flujoRepresado: _flujoRepresado,
        nivelCubreCotaSalida: _nivelCubreCotaSalida,
        cotaEstructura: _toDouble(_cotaEstructuraCtrl.text),
        condicionesInvestiga: _condicionesInvestigaCtrl.text.trim().isEmpty
            ? null
            : _condicionesInvestigaCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),

        // Sumidero
        tipoSumidero: _tipo == 'Sumidero'
            ? (_tipoSumideroCtrl.text.trim().isEmpty
                  ? null
                  : _tipoSumideroCtrl.text.trim())
            : null,
        anchoSumidero: _tipo == 'Sumidero'
            ? _toDouble(_anchoSumideroCtrl.text)
            : null,
        largoSumidero: _tipo == 'Sumidero'
            ? _toDouble(_largoSumideroCtrl.text)
            : null,
        alturaSumidero: _tipo == 'Sumidero'
            ? _toDouble(_alturaSumideroCtrl.text)
            : null,
        materialSumidero: _tipo == 'Sumidero'
            ? (_materialSumideroCtrl.text.trim().isEmpty
                  ? null
                  : _materialSumideroCtrl.text.trim())
            : null,
        anchoRejilla: _tipo == 'Sumidero'
            ? _toDouble(_anchoRejillaCtrl.text)
            : null,
        largoRejilla: _tipo == 'Sumidero'
            ? _toDouble(_largoRejillaCtrl.text)
            : null,
        alturaRejilla: _tipo == 'Sumidero'
            ? _toDouble(_alturaRejillaCtrl.text)
            : null,
        materialRejilla: _tipo == 'Sumidero'
            ? (_materialRejillaCtrl.text.trim().isEmpty
                  ? null
                  : _materialRejillaCtrl.text.trim())
            : null,

        idProyecto: serverId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estructura creada correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar estructura hidráulica')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo + ID
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipo,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de estructura',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Pozo', child: Text('Pozo')),
                          DropdownMenuItem(
                            value: 'Sumidero',
                            child: Text('Sumidero'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _tipo = value;
                          });
                          _fetchNextId();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'ID',
                          hintText: _generatedId ?? 'Generando...',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Fecha y hora
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de inspección',
                          ),
                          child: Text(
                            _fechaInspeccion == null
                                ? 'Seleccionar'
                                : '${_fechaInspeccion!.day.toString().padLeft(2, "0")}/'
                                      '${_fechaInspeccion!.month.toString().padLeft(2, "0")}/'
                                      '${_fechaInspeccion!.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickHora,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Hora de inspección',
                          ),
                          child: Text(
                            _horaInspeccion == null
                                ? 'Seleccionar'
                                : _horaInspeccion!.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _climaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clima de inspección',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tipoViaCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo de vía'),
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _latitudCtrl,
                  decoration: const InputDecoration(labelText: 'Latitud'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _longitudCtrl,
                  decoration: const InputDecoration(labelText: 'Longitud'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Datos generales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _tipoSistemaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de sistema',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _materialCtrl,
                  decoration: const InputDecoration(labelText: 'Material'),
                ),

                const SizedBox(height: 16),

                if (_tipo == 'Pozo') ...[
                  Text(
                    'Pozo',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Cono de reducción'),
                    value: _conoReduccion,
                    onChanged: (v) {
                      setState(() {
                        _conoReduccion = v;
                      });
                    },
                  ),
                  TextFormField(
                    controller: _alturaConoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Altura del cono (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _profundidadPozoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Profundidad del pozo (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _diametroCamaraCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diámetro de la cámara (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_tipo == 'Sumidero') ...[
                  Text(
                    'Sumidero',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _tipoSumideroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de sumidero',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _anchoSumideroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ancho del sumidero (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _largoSumideroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Largo del sumidero (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _alturaSumideroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Altura del sumidero (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _materialSumideroCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material del sumidero',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _anchoRejillaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ancho de la rejilla (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _largoRejillaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Largo de la rejilla (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _alturaRejillaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Altura de la rejilla (m)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _materialRejillaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material de la rejilla',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  'Condiciones adicionales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Sedimentación'),
                  value: _sedimentacion,
                  onChanged: (v) {
                    setState(() {
                      _sedimentacion = v;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Cobertura tubería salida'),
                  value: _coberturaTuberiaSalida,
                  onChanged: (v) {
                    setState(() {
                      _coberturaTuberiaSalida = v;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Flujo represado'),
                  value: _flujoRepresado,
                  onChanged: (v) {
                    setState(() {
                      _flujoRepresado = v;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Nivel cubre cota salida'),
                  value: _nivelCubreCotaSalida,
                  onChanged: (v) {
                    setState(() {
                      _nivelCubreCotaSalida = v;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _depositoPredominaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Depósito que predomina',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cotaEstructuraCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cota de la estructura (m)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _condicionesInvestigaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Condiciones investigadas',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observacionesCtrl,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar estructura'),
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
