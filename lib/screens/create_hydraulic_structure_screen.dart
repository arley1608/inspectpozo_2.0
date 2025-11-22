import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'create_photo_record_screen.dart';

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
  final _tipoSistemaCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();

  // Coordenadas
  final _longitudCtrl = TextEditingController();
  final _latitudCtrl = TextEditingController();

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
  bool _photosCompleted = false; // controla si ya se hicieron las 4 fotos

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
    _tipoSistemaCtrl.dispose();
    _materialCtrl.dispose();

    _longitudCtrl.dispose();
    _latitudCtrl.dispose();

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

  /// Construye el WKT a partir de longitud y latitud si ambos están presentes
  String? _buildGeometryWkt() {
    final lon = _longitudCtrl.text.trim();
    final lat = _latitudCtrl.text.trim();
    if (lon.isEmpty || lat.isEmpty) return null;
    // WKT: POINT(longitud latitud)
    return 'POINT($lon $lat)';
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

    // Bloquear si no se ha completado el registro fotográfico
    if (!_photosCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes completar el registro fotográfico (4 fotos) antes de guardar la estructura.',
          ),
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

    final geometria = _buildGeometryWkt();

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
        coberturaTuberiaSalida: _sedimentacion
            ? _coberturaTuberiaSalida
            : null, // si no hay sedimentación, lo mandamos null
        depositoPredomina: _depositoPredominaCtrl.text.trim().isEmpty
            ? null
            : _depositoPredominaCtrl.text.trim(),
        flujoRepresado: _flujoRepresado,
        nivelCubreCotaSalida: _flujoRepresado
            ? _nivelCubreCotaSalida
            : null, // si no hay flujo represado, lo mandamos null
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

        // Geometría (WKT)
        geometria: geometria,
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

                // ====== TIPO DE VÍA (DROPDOWN) ======
                DropdownButtonFormField<String>(
                  value: _tipoViaCtrl.text.isEmpty ? null : _tipoViaCtrl.text,
                  decoration: const InputDecoration(labelText: 'Tipo de vía'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Afirmado',
                      child: Text('Afirmado'),
                    ),
                    DropdownMenuItem(
                      value: 'Flexible',
                      child: Text('Flexible'),
                    ),
                    DropdownMenuItem(value: 'Rígido', child: Text('Rígido')),
                    DropdownMenuItem(value: 'Adoquín', child: Text('Adoquín')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoViaCtrl.text = value ?? '';
                    });
                  },
                ),

                const SizedBox(height: 8),

                // Longitud y Latitud
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _longitudCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _latitudCtrl,
                        decoration: const InputDecoration(labelText: 'Latitud'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Datos generales',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // ====== TIPO DE SISTEMA (DROPDOWN) ======
                DropdownButtonFormField<String>(
                  value: _tipoSistemaCtrl.text.isEmpty
                      ? null
                      : _tipoSistemaCtrl.text,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de sistema',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Residual',
                      child: Text('Residual'),
                    ),
                    DropdownMenuItem(value: 'Lluvias', child: Text('Lluvias')),
                    DropdownMenuItem(
                      value: 'Combinado',
                      child: Text('Combinado'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoSistemaCtrl.text = value ?? '';
                    });
                  },
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
                const SizedBox(height: 8),

                // ====== MATERIAL (DROPDOWN) ======
                DropdownButtonFormField<String>(
                  value: _materialCtrl.text.isEmpty ? null : _materialCtrl.text,
                  decoration: const InputDecoration(labelText: 'Material'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Ladrillo',
                      child: Text('Ladrillo'),
                    ),
                    DropdownMenuItem(
                      value: 'Concreto',
                      child: Text('Concreto'),
                    ),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _materialCtrl.text = value ?? '';
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ------ Sección Pozo ------
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
                  if (_conoReduccion) ...[
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
                  ],
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

                // ------ Sección Sumidero ------
                if (_tipo == 'Sumidero') ...[
                  Text(
                    'Sumidero',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ====== TIPO DE SUMIDERO (DROPDOWN) ======
                  DropdownButtonFormField<String>(
                    value: _tipoSumideroCtrl.text.isEmpty
                        ? null
                        : _tipoSumideroCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de sumidero',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Lateral',
                        child: Text('Lateral'),
                      ),
                      DropdownMenuItem(
                        value: 'Calzada',
                        child: Text('Calzada'),
                      ),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _tipoSumideroCtrl.text = value ?? '';
                      });
                    },
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

                // ------ Compartidos extra ------
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
                      if (!_sedimentacion) {
                        _coberturaTuberiaSalida = false;
                        _depositoPredominaCtrl.text = '';
                      }
                    });
                  },
                ),
                if (_sedimentacion)
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
                      if (!_flujoRepresado) {
                        _nivelCubreCotaSalida = false;
                      }
                    });
                  },
                ),
                if (_flujoRepresado)
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

                // ====== DEPÓSITO QUE PREDOMINA (DROPDOWN) ======
                if (_sedimentacion) ...[
                  DropdownButtonFormField<String>(
                    value: _depositoPredominaCtrl.text.isEmpty
                        ? null
                        : _depositoPredominaCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Depósito que predomina',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Basuras',
                        child: Text('Basuras'),
                      ),
                      DropdownMenuItem(
                        value: 'Arcillas y lodos',
                        child: Text('Arcillas y lodos'),
                      ),
                      DropdownMenuItem(
                        value: 'Arenas y gravillas',
                        child: Text('Arenas y gravillas'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _depositoPredominaCtrl.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],

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

                // ====== CONDICIONES INVESTIGADAS (DROPDOWN) ======
                DropdownButtonFormField<String>(
                  value: _condicionesInvestigaCtrl.text.isEmpty
                      ? null
                      : _condicionesInvestigaCtrl.text,
                  decoration: const InputDecoration(
                    labelText: 'Condiciones de Investigación',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Exitoso', child: Text('Exitoso')),
                    DropdownMenuItem(
                      value: 'No exitoso',
                      child: Text('No exitoso'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _condicionesInvestigaCtrl.text = value ?? '';
                    });
                  },
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
                    onPressed: (_saving || !_photosCompleted) ? null : _save,
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _generatedId == null
                        ? null
                        : () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreatePhotoRecordScreen(
                                  estructuraId: _generatedId!,
                                  estructuraLabel:
                                      '${_generatedId!} - ${_tipo ?? ''}',
                                ),
                              ),
                            );

                            if (result == true && mounted) {
                              setState(() {
                                _photosCompleted = true;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Registro fotográfico completado. Ya puedes guardar la estructura.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Agregar fotografía'),
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
