import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class EditHydraulicStructureScreen extends StatefulWidget {
  final Map<String, dynamic> structure;

  const EditHydraulicStructureScreen({super.key, required this.structure});

  @override
  State<EditHydraulicStructureScreen> createState() =>
      _EditHydraulicStructureScreenState();
}

class _EditHydraulicStructureScreenState
    extends State<EditHydraulicStructureScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> get _s => widget.structure;

  // Campos editables
  String? _tipo; // Pozo / Sumidero

  late TextEditingController _geometriaCtrl;
  late TextEditingController _fechaCtrl;
  late TextEditingController _horaCtrl;
  late TextEditingController _climaCtrl;
  late TextEditingController _tipoViaCtrl;
  late TextEditingController _tipoSistemaCtrl;
  late TextEditingController _materialCtrl;

  late TextEditingController _alturaConoCtrl;
  late TextEditingController _profundidadPozoCtrl;
  late TextEditingController _diametroCamaraCtrl;

  late TextEditingController _cotaEstructuraCtrl;
  late TextEditingController _depositoPredominaCtrl;
  late TextEditingController _condicionesInvestigaCtrl;
  late TextEditingController _observacionesCtrl;

  late TextEditingController _tipoSumideroCtrl;
  late TextEditingController _anchoSumideroCtrl;
  late TextEditingController _largoSumideroCtrl;
  late TextEditingController _alturaSumideroCtrl;
  late TextEditingController _materialSumideroCtrl;

  late TextEditingController _anchoRejillaCtrl;
  late TextEditingController _largoRejillaCtrl;
  late TextEditingController _alturaRejillaCtrl;
  late TextEditingController _materialRejillaCtrl;

  late TextEditingController _idProyectoCtrl;

  bool? _conoReduccion;
  bool? _sedimentacion;
  bool? _coberturaTuberiaSalida;
  bool? _flujoRepresado;
  bool? _nivelCubreCotaSalida;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _tipo = _s['tipo']?.toString();

    _geometriaCtrl = TextEditingController(
      text: _s['geometria']?.toString() ?? '',
    );
    _fechaCtrl = TextEditingController(
      text: _s['fecha_inspeccion']?.toString() ?? '',
    );
    _horaCtrl = TextEditingController(
      text: _s['hora_inspeccion']?.toString() ?? '',
    );
    _climaCtrl = TextEditingController(
      text: _s['clima_inspeccion']?.toString() ?? '',
    );
    _tipoViaCtrl = TextEditingController(
      text: _s['tipo_via']?.toString() ?? '',
    );
    _tipoSistemaCtrl = TextEditingController(
      text: _s['tipo_sistema']?.toString() ?? '',
    );
    _materialCtrl = TextEditingController(
      text: _s['material']?.toString() ?? '',
    );

    _alturaConoCtrl = TextEditingController(
      text: _s['altura_cono']?.toString() ?? '',
    );
    _profundidadPozoCtrl = TextEditingController(
      text: _s['profundidad_pozo']?.toString() ?? '',
    );
    _diametroCamaraCtrl = TextEditingController(
      text: _s['diametro_camara']?.toString() ?? '',
    );

    _cotaEstructuraCtrl = TextEditingController(
      text: _s['cota_estructura']?.toString() ?? '',
    );
    _depositoPredominaCtrl = TextEditingController(
      text: _s['deposito_predomina']?.toString() ?? '',
    );
    _condicionesInvestigaCtrl = TextEditingController(
      text: _s['condiciones_investiga']?.toString() ?? '',
    );
    _observacionesCtrl = TextEditingController(
      text: _s['observaciones']?.toString() ?? '',
    );

    _tipoSumideroCtrl = TextEditingController(
      text: _s['tipo_sumidero']?.toString() ?? '',
    );
    _anchoSumideroCtrl = TextEditingController(
      text: _s['ancho_sumidero']?.toString() ?? '',
    );
    _largoSumideroCtrl = TextEditingController(
      text: _s['largo_sumidero']?.toString() ?? '',
    );
    _alturaSumideroCtrl = TextEditingController(
      text: _s['altura_sumidero']?.toString() ?? '',
    );
    _materialSumideroCtrl = TextEditingController(
      text: _s['material_sumidero']?.toString() ?? '',
    );

    _anchoRejillaCtrl = TextEditingController(
      text: _s['ancho_rejilla']?.toString() ?? '',
    );
    _largoRejillaCtrl = TextEditingController(
      text: _s['largo_rejilla']?.toString() ?? '',
    );
    _alturaRejillaCtrl = TextEditingController(
      text: _s['altura_rejilla']?.toString() ?? '',
    );
    _materialRejillaCtrl = TextEditingController(
      text: _s['material_rejilla']?.toString() ?? '',
    );

    _idProyectoCtrl = TextEditingController(
      text: _s['id_proyecto']?.toString() ?? '',
    );

    _conoReduccion = _asBool(_s['cono_reduccion']);
    _sedimentacion = _asBool(_s['sedimentacion']);
    _coberturaTuberiaSalida = _asBool(_s['cobertura_tuberia_salida']);
    _flujoRepresado = _asBool(_s['flujo_represado']);
    _nivelCubreCotaSalida = _asBool(_s['nivel_cubre_cotasalida']);
  }

  bool? _asBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  @override
  void dispose() {
    _geometriaCtrl.dispose();
    _fechaCtrl.dispose();
    _horaCtrl.dispose();
    _climaCtrl.dispose();
    _tipoViaCtrl.dispose();
    _tipoSistemaCtrl.dispose();
    _materialCtrl.dispose();

    _alturaConoCtrl.dispose();
    _profundidadPozoCtrl.dispose();
    _diametroCamaraCtrl.dispose();

    _cotaEstructuraCtrl.dispose();
    _depositoPredominaCtrl.dispose();
    _condicionesInvestigaCtrl.dispose();
    _observacionesCtrl.dispose();

    _tipoSumideroCtrl.dispose();
    _anchoSumideroCtrl.dispose();
    _largoSumideroCtrl.dispose();
    _alturaSumideroCtrl.dispose();
    _materialSumideroCtrl.dispose();

    _anchoRejillaCtrl.dispose();
    _largoRejillaCtrl.dispose();
    _alturaRejillaCtrl.dispose();
    _materialRejillaCtrl.dispose();

    _idProyectoCtrl.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final api = context.read<ApiClient>();
    final auth = context.read<AuthService>();

    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida. Inicia sesión de nuevo.'),
        ),
      );
      return;
    }

    final id = _s['id']?.toString();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de estructura inválido.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      double? _parseDouble(String text) {
        final t = text.trim();
        if (t.isEmpty) return null;
        return double.tryParse(t);
      }

      int? _parseInt(String text) {
        final t = text.trim();
        if (t.isEmpty) return null;
        return int.tryParse(t);
      }

      await api.updateHydraulicStructure(
        token: token,
        id: id,
        tipo: _tipo,

        geometria: _geometriaCtrl.text.trim().isEmpty
            ? null
            : _geometriaCtrl.text.trim(),
        fechaInspeccion: _fechaCtrl.text.trim().isEmpty
            ? null
            : _fechaCtrl.text.trim(),
        horaInspeccion: _horaCtrl.text.trim().isEmpty
            ? null
            : _horaCtrl.text.trim(),
        climaInspeccion: _climaCtrl.text.trim().isEmpty
            ? null
            : _climaCtrl.text.trim(),
        tipoVia: _tipoViaCtrl.text.trim().isEmpty
            ? null
            : _tipoViaCtrl.text.trim(),
        tipoSistema: _tipoSistemaCtrl.text.trim().isEmpty
            ? null
            : _tipoSistemaCtrl.text.trim(),
        material: _materialCtrl.text.trim().isEmpty
            ? null
            : _materialCtrl.text.trim(),

        conoReduccion: _conoReduccion,
        alturaCono: _parseDouble(_alturaConoCtrl.text),
        profundidadPozo: _parseDouble(_profundidadPozoCtrl.text),
        diametroCamara: _parseDouble(_diametroCamaraCtrl.text),

        sedimentacion: _sedimentacion,
        coberturaTuberiaSalida: _coberturaTuberiaSalida,
        depositoPredomina: _depositoPredominaCtrl.text.trim().isEmpty
            ? null
            : _depositoPredominaCtrl.text.trim(),
        flujoRepresado: _flujoRepresado,
        nivelCubreCotaSalida: _nivelCubreCotaSalida,
        cotaEstructura: _parseDouble(_cotaEstructuraCtrl.text),
        condicionesInvestiga: _condicionesInvestigaCtrl.text.trim().isEmpty
            ? null
            : _condicionesInvestigaCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),

        tipoSumidero: _tipoSumideroCtrl.text.trim().isEmpty
            ? null
            : _tipoSumideroCtrl.text.trim(),
        anchoSumidero: _parseDouble(_anchoSumideroCtrl.text),
        largoSumidero: _parseDouble(_largoSumideroCtrl.text),
        alturaSumidero: _parseDouble(_alturaSumideroCtrl.text),
        materialSumidero: _materialSumideroCtrl.text.trim().isEmpty
            ? null
            : _materialSumideroCtrl.text.trim(),

        anchoRejilla: _parseDouble(_anchoRejillaCtrl.text),
        largoRejilla: _parseDouble(_largoRejillaCtrl.text),
        alturaRejilla: _parseDouble(_alturaRejillaCtrl.text),
        materialRejilla: _materialRejillaCtrl.text.trim().isEmpty
            ? null
            : _materialRejillaCtrl.text.trim(),

        idProyecto: _parseInt(_idProyectoCtrl.text),
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estructura actualizada correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la estructura: $e')),
      );
    }
  }

  Widget _boolField({
    required String label,
    required bool? value,
    required void Function(bool?) onChanged,
  }) {
    return DropdownButtonFormField<bool?>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('Sin dato')),
        DropdownMenuItem<bool?>(value: true, child: Text('Sí')),
        DropdownMenuItem<bool?>(value: false, child: Text('No')),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final id = _s['id']?.toString() ?? 'Sin id';

    return Scaffold(
      appBar: AppBar(title: const Text('Editar estructura hidráulica')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Editar estructura',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: $id',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de estructura',
                        prefixIcon: Icon(Icons.category),
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

                    const SizedBox(height: 24),

                    Text(
                      'Datos generales',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _geometriaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Geometría',
                        prefixIcon: Icon(Icons.grid_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fechaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fecha de inspección (YYYY-MM-DD)',
                        prefixIcon: Icon(Icons.date_range),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _horaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hora de inspección (HH:mm:ss)',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _climaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Clima durante la inspección',
                        prefixIcon: Icon(Icons.wb_cloudy),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tipoViaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vía',
                        prefixIcon: Icon(Icons.route),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tipoSistemaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de sistema',
                        prefixIcon: Icon(Icons.device_hub),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        prefixIcon: Icon(Icons.architecture),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Condiciones hidráulicas y sedimentos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _boolField(
                      label: 'Sedimentación',
                      value: _sedimentacion,
                      onChanged: (v) => setState(() => _sedimentacion = v),
                    ),
                    const SizedBox(height: 12),
                    _boolField(
                      label: 'Cobertura tubería de salida',
                      value: _coberturaTuberiaSalida,
                      onChanged: (v) =>
                          setState(() => _coberturaTuberiaSalida = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _depositoPredominaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Depósito que predomina',
                        prefixIcon: Icon(Icons.layers),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _boolField(
                      label: 'Flujo represado',
                      value: _flujoRepresado,
                      onChanged: (v) => setState(() => _flujoRepresado = v),
                    ),
                    const SizedBox(height: 12),
                    _boolField(
                      label: 'Nivel cubre la cota de salida',
                      value: _nivelCubreCotaSalida,
                      onChanged: (v) =>
                          setState(() => _nivelCubreCotaSalida = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cotaEstructuraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cota de la estructura',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _condicionesInvestigaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Condiciones a investigar',
                        prefixIcon: Icon(Icons.search),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacionesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    if ((_tipo ?? '').toLowerCase() == 'pozo') ...[
                      Text(
                        'Datos del pozo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _boolField(
                        label: 'Cono de reducción',
                        value: _conoReduccion,
                        onChanged: (v) => setState(() => _conoReduccion = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alturaConoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Altura del cono',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _profundidadPozoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Profundidad del pozo',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _diametroCamaraCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Diámetro de la cámara',
                          prefixIcon: Icon(Icons.circle),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if ((_tipo ?? '').toLowerCase() == 'sumidero') ...[
                      Text(
                        'Datos del sumidero',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tipoSumideroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de sumidero',
                          prefixIcon: Icon(Icons.water_drop),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _anchoSumideroCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ancho sumidero',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _largoSumideroCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Largo sumidero',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alturaSumideroCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Altura sumidero',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _materialSumideroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Material sumidero',
                          prefixIcon: Icon(Icons.architecture),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Datos de la rejilla',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _anchoRejillaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ancho rejilla',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _largoRejillaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Largo rejilla',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _alturaRejillaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Altura rejilla',
                          prefixIcon: Icon(Icons.height),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _materialRejillaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Material rejilla',
                          prefixIcon: Icon(Icons.architecture),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Proyecto asociado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idProyectoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ID del proyecto (normalmente no modificar)',
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
        ),
      ),
    );
  }
}
