import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class EditHydraulicStructureScreen extends StatefulWidget {
  final Map<String, dynamic> structure;
  final Map<String, dynamic> project;

  const EditHydraulicStructureScreen({
    super.key,
    required this.structure,
    required this.project,
  });

  @override
  State<EditHydraulicStructureScreen> createState() =>
      _EditHydraulicStructureScreenState();
}

class _EditHydraulicStructureScreenState
    extends State<EditHydraulicStructureScreen> {
  final _formKey = GlobalKey<FormState>();

  // ----------- Campos básicos / compartidos -----------
  String? _tipo; // Pozo / Sumidero
  late final String _id; // ID existente, solo lectura

  DateTime? _fechaInspeccion;
  TimeOfDay? _horaInspeccion;

  final _climaCtrl = TextEditingController();
  final _tipoViaCtrl = TextEditingController();
  final _tipoSistemaCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();

  // Coordenadas (para geometría WKT)
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

  @override
  void initState() {
    super.initState();
    final s = widget.structure;

    _id = (s['id'] ?? '').toString();
    _tipo = (s['tipo'] as String?) ?? 'Pozo';

    // Fecha
    if (s['fecha_inspeccion'] != null) {
      try {
        _fechaInspeccion = DateTime.parse(s['fecha_inspeccion'] as String);
      } catch (_) {
        _fechaInspeccion = null;
      }
    }

    // Hora
    if (s['hora_inspeccion'] != null) {
      _horaInspeccion = _timeOfDayFromString(s['hora_inspeccion'] as String);
    }

    _climaCtrl.text = (s['clima_inspeccion'] ?? '').toString();
    _tipoViaCtrl.text = (s['tipo_via'] ?? '').toString();
    _tipoSistemaCtrl.text = (s['tipo_sistema'] ?? '').toString();
    _materialCtrl.text = (s['material'] ?? '').toString();

    // ---------- Geometría: intentar precargar lon/lat ----------
    String? lonStr;
    String? latStr;

    // 1) Si vienen como lon/lat
    if (s['lon'] != null && s['lat'] != null) {
      lonStr = s['lon'].toString();
      latStr = s['lat'].toString();
    }
    // 2) Si vienen como longitud/latitud
    else if (s['longitud'] != null && s['latitud'] != null) {
      lonStr = s['longitud'].toString();
      latStr = s['latitud'].toString();
    }
    // 3) Si vienen como WKT en geometria_wkt
    else if (s['geometria_wkt'] is String) {
      final p = _parsePointFromWkt(s['geometria_wkt'] as String);
      if (p != null) {
        lonStr = p['lon']!.toString();
        latStr = p['lat']!.toString();
      }
    }
    // 4) O en geometria (string WKT)
    else if (s['geometria'] is String) {
      final p = _parsePointFromWkt(s['geometria'] as String);
      if (p != null) {
        lonStr = p['lon']!.toString();
        latStr = p['lat']!.toString();
      }
    }

    _longitudCtrl.text = lonStr ?? '';
    _latitudCtrl.text = latStr ?? '';

    _sedimentacion = _toBool(s['sedimentacion']);
    _coberturaTuberiaSalida = _toBool(s['cobertura_tuberia_salida']);
    _flujoRepresado = _toBool(s['flujo_represado']);
    _nivelCubreCotaSalida = _toBool(s['nivel_cubre_cotasalida']);

    _depositoPredominaCtrl.text = (s['deposito_predomina'] ?? '').toString();
    _cotaEstructuraCtrl.text = s['cota_estructura'] != null
        ? s['cota_estructura'].toString()
        : '';
    _condicionesInvestigaCtrl.text = (s['condiciones_investiga'] ?? '')
        .toString();
    _observacionesCtrl.text = (s['observaciones'] ?? '').toString();

    _conoReduccion = _toBool(s['cono_reduccion']);
    _alturaConoCtrl.text = s['altura_cono'] != null
        ? s['altura_cono'].toString()
        : '';
    _profundidadPozoCtrl.text = s['profundidad_pozo'] != null
        ? s['profundidad_pozo'].toString()
        : '';
    _diametroCamaraCtrl.text = s['diametro_camara'] != null
        ? s['diametro_camara'].toString()
        : '';

    _tipoSumideroCtrl.text = (s['tipo_sumidero'] ?? '').toString();
    _anchoSumideroCtrl.text = s['ancho_sumidero'] != null
        ? s['ancho_sumidero'].toString()
        : '';
    _largoSumideroCtrl.text = s['largo_sumidero'] != null
        ? s['largo_sumidero'].toString()
        : '';
    _alturaSumideroCtrl.text = s['altura_sumidero'] != null
        ? s['altura_sumidero'].toString()
        : '';
    _materialSumideroCtrl.text = (s['material_sumidero'] ?? '').toString();

    _anchoRejillaCtrl.text = s['ancho_rejilla'] != null
        ? s['ancho_rejilla'].toString()
        : '';
    _largoRejillaCtrl.text = s['largo_rejilla'] != null
        ? s['largo_rejilla'].toString()
        : '';
    _alturaRejillaCtrl.text = s['altura_rejilla'] != null
        ? s['altura_rejilla'].toString()
        : '';
    _materialRejillaCtrl.text = (s['material_rejilla'] ?? '').toString();
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

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 't';
    }
    return false;
  }

  /// Validador para campos numéricos (excepto lat/lon): >= 0
  String? _nonNegativeValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // opcional
    final v = double.tryParse(text.replaceAll(',', '.'));
    if (v == null) return 'Valor numérico inválido';
    if (v < 0) return 'Debe ser mayor o igual a 0';
    return null;
  }

  /// Validador de longitud: -180 a 180
  String? _longitudeValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // opcional
    final v = double.tryParse(text.replaceAll(',', '.'));
    if (v == null) return 'Valor numérico inválido';
    if (v < -180 || v > 180) {
      return 'Longitud debe estar entre -180 y 180';
    }
    return null;
  }

  /// Validador de latitud: -90 a 90
  String? _latitudeValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null; // opcional
    final v = double.tryParse(text.replaceAll(',', '.'));
    if (v == null) return 'Valor numérico inválido';
    if (v < -90 || v > 90) {
      return 'Latitud debe estar entre -90 y 90';
    }
    return null;
  }

  /// Parsea WKT del tipo "POINT(lon lat)" y devuelve {lon, lat} si es posible.
  Map<String, double>? _parsePointFromWkt(String wkt) {
    final text = wkt.trim();
    if (!text.toUpperCase().startsWith('POINT')) return null;

    final start = text.indexOf('(');
    final end = text.indexOf(')', start + 1);
    if (start == -1 || end == -1) return null;

    final inside = text.substring(start + 1, end).trim();
    final parts = inside.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final lon = double.tryParse(parts[0].replaceAll(',', '.'));
    final lat = double.tryParse(parts[1].replaceAll(',', '.'));
    if (lon == null || lat == null) return null;

    return {'lon': lon, 'lat': lat};
  }

  String? _formatHora(TimeOfDay? t) {
    if (t == null) return null;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  TimeOfDay? _timeOfDayFromString(String value) {
    try {
      final parts = value.split(':');
      if (parts.length < 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
    }
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

  /// Construye el WKT a partir de longitud y latitud si ambos están presentes.
  /// Si están vacíos, retornamos null para NO modificar la geometría existente.
  String? _buildGeometryWkt() {
    final lon = _longitudCtrl.text.trim();
    final lat = _latitudCtrl.text.trim();
    if (lon.isEmpty || lat.isEmpty) return null;
    return 'POINT($lon $lat)';
  }

  // ---------- Guardar cambios ----------

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

    final geometria = _buildGeometryWkt();

    setState(() {
      _saving = true;
    });

    try {
      final api = context.read<ApiClient>();

      await api.updateHydraulicStructure(
        token: token,
        id: _id,

        // Generales
        tipo: _tipo,
        geometria: geometria, // solo se envía si el usuario puso lon/lat
        fechaInspeccion: _fechaInspeccion!.toIso8601String().split('T')[0],
        horaInspeccion: _formatHora(_horaInspeccion!)!,
        climaInspeccion: _climaCtrl.text.trim().isEmpty
            ? null
            : _climaCtrl.text.trim(),
        tipoVia: _tipoViaCtrl.text.trim().isEmpty
            ? null
            : _tipoViaCtrl.text.trim(),

        // Sistema
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

        // Condiciones
        sedimentacion: _sedimentacion,
        coberturaTuberiaSalida: _sedimentacion ? _coberturaTuberiaSalida : null,
        depositoPredomina: _depositoPredominaCtrl.text.trim().isEmpty
            ? null
            : _depositoPredominaCtrl.text.trim(),
        flujoRepresado: _flujoRepresado,
        nivelCubreCotaSalida: _flujoRepresado ? _nivelCubreCotaSalida : null,
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
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estructura actualizada correctamente')),
        );
        Navigator.pop(context, true);
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

  // ---------- UI (idéntica a Create, pero con ID fijo) ----------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar estructura hidráulica')),
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
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: _id,
                        decoration: const InputDecoration(labelText: 'ID'),
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

                // ====== CLIMA (DROPDOWN) ======
                DropdownButtonFormField<String>(
                  value: _climaCtrl.text.isEmpty ? null : _climaCtrl.text,
                  decoration: const InputDecoration(
                    labelText: 'Clima de inspección',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Soleado', child: Text('Soleado')),
                    DropdownMenuItem(value: 'Nublado', child: Text('Nublado')),
                    DropdownMenuItem(
                      value: 'Lluvioso',
                      child: Text('Lluvioso'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _climaCtrl.text = value ?? '';
                    });
                  },
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

                // Longitud y Latitud (con validadores de rango)
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
                        validator: _longitudeValidator,
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
                        validator: _latitudeValidator,
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
                      validator: _nonNegativeValidator,
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
                      validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
                  ),
                  const SizedBox(height: 8),

                  // ====== MATERIAL DEL SUMIDERO (DROPDOWN) ======
                  DropdownButtonFormField<String>(
                    value: _materialSumideroCtrl.text.isEmpty
                        ? null
                        : _materialSumideroCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Material del sumidero',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Concreto',
                        child: Text('Concreto'),
                      ),
                      DropdownMenuItem(
                        value: 'Ladrillo',
                        child: Text('Ladrillo'),
                      ),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _materialSumideroCtrl.text = value ?? '';
                      });
                    },
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
                    validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
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
                    validator: _nonNegativeValidator,
                  ),
                  const SizedBox(height: 8),

                  // ====== MATERIAL DE LA REJILLA (DROPDOWN) ======
                  DropdownButtonFormField<String>(
                    value: _materialRejillaCtrl.text.isEmpty
                        ? null
                        : _materialRejillaCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'Material de la rejilla',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Hierro', child: Text('Hierro')),
                      DropdownMenuItem(
                        value: 'Concreto',
                        child: Text('Concreto'),
                      ),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _materialRejillaCtrl.text = value ?? '';
                      });
                    },
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
                  validator: _nonNegativeValidator,
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
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar cambios'),
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
