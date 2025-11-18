import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/api_client.dart';

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

  // ID generado por backend (pzXXXX / smXXXX)
  final TextEditingController _idCtrl = TextEditingController();

  // Compartidos
  final TextEditingController _climaCtrl = TextEditingController();
  final TextEditingController _tipoViaCtrl = TextEditingController();
  final TextEditingController _condicionesCtrl = TextEditingController();
  final TextEditingController _observacionesCtrl = TextEditingController();

  // Pozo
  final TextEditingController _tipoSistemaCtrl = TextEditingController();
  final TextEditingController _materialCtrl = TextEditingController();
  final TextEditingController _alturaConoCtrl = TextEditingController();
  final TextEditingController _profundidadPozoCtrl = TextEditingController();
  final TextEditingController _diametroCamaraCtrl = TextEditingController();
  final TextEditingController _elementosPozoCtrl = TextEditingController();
  final TextEditingController _estadoElementoCtrl = TextEditingController();
  final TextEditingController _materialElementoCtrl = TextEditingController();

  // Sumidero
  final TextEditingController _tipoSumideroCtrl = TextEditingController();
  final TextEditingController _anchoSumideroCtrl = TextEditingController();
  final TextEditingController _largoSumideroCtrl = TextEditingController();
  final TextEditingController _alturaSumideroCtrl = TextEditingController();
  final TextEditingController _materialSumideroCtrl = TextEditingController();
  final TextEditingController _anchoRejillaCtrl = TextEditingController();
  final TextEditingController _largoRejillaCtrl = TextEditingController();
  final TextEditingController _alturaRejillaCtrl = TextEditingController();
  final TextEditingController _materialRejillaCtrl = TextEditingController();

  // Booleans compartidos / pozo
  bool _sedimentacion = false;
  bool _coberturaTuberiaSalida = false;
  bool _flujoRepresado = false;
  bool _nivelCubreCotaSalida = false;
  bool _conoReduccion = false;

  // Otros compartidos
  final TextEditingController _cotaEstructuraCtrl = TextEditingController();
  final TextEditingController _depositoPredominaCtrl = TextEditingController();

  String? _selectedTipo; // "Pozo" o "Sumidero"
  bool _loadingId = false;

  DateTime? _fechaInspeccion;
  TimeOfDay? _horaInspeccion;

  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _climaCtrl.dispose();
    _tipoViaCtrl.dispose();
    _condicionesCtrl.dispose();
    _observacionesCtrl.dispose();

    _tipoSistemaCtrl.dispose();
    _materialCtrl.dispose();
    _alturaConoCtrl.dispose();
    _profundidadPozoCtrl.dispose();
    _diametroCamaraCtrl.dispose();
    _elementosPozoCtrl.dispose();
    _estadoElementoCtrl.dispose();
    _materialElementoCtrl.dispose();

    _tipoSumideroCtrl.dispose();
    _anchoSumideroCtrl.dispose();
    _largoSumideroCtrl.dispose();
    _alturaSumideroCtrl.dispose();
    _materialSumideroCtrl.dispose();
    _anchoRejillaCtrl.dispose();
    _largoRejillaCtrl.dispose();
    _alturaRejillaCtrl.dispose();
    _materialRejillaCtrl.dispose();

    _cotaEstructuraCtrl.dispose();
    _depositoPredominaCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInspeccion ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _fechaInspeccion = picked);
    }
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInspeccion ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _horaInspeccion = picked);
    }
  }

  double? _parseDouble(TextEditingController c) {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _onTipoChanged(String value) async {
    setState(() {
      _selectedTipo = value;
      _loadingId = true;
      _idCtrl.text = '';
    });

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();

    final token = auth.token;
    if (token == null) {
      setState(() => _loadingId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay sesión activa. Vuelve a iniciar sesión.'),
        ),
      );
      return;
    }

    try {
      final id = await api.getNextHydraulicStructureId(
        token: token,
        tipo: value,
      );

      setState(() {
        _idCtrl.text = id;
        _loadingId = false;
      });
    } catch (e) {
      setState(() => _loadingId = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar ID para la estructura: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();

    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay sesión activa. Vuelve a iniciar sesión.'),
        ),
      );
      return;
    }

    final serverProjectId = widget.project['serverId'] as int?;
    if (serverProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este proyecto aún no está sincronizado con el servidor.\n'
            'Primero sincroniza el proyecto antes de agregar estructuras.',
          ),
        ),
      );
      return;
    }

    if (_selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el tipo de estructura (Pozo o Sumidero).'),
        ),
      );
      return;
    }

    if (_fechaInspeccion == null || _horaInspeccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha y la hora de la inspección.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final h = _horaInspeccion!;
      final horaStr =
          '${h.hour.toString().padLeft(2, '0')}:${h.minute.toString().padLeft(2, '0')}:00';

      await api.createHydraulicStructure(
        token: token,
        id: _idCtrl.text.trim(),
        tipo: _selectedTipo!, // "Pozo" o "Sumidero"
        fechaInspeccion: _fechaInspeccion!,
        horaInspeccion: horaStr,
        climaInspeccion: _climaCtrl.text.trim().isEmpty
            ? null
            : _climaCtrl.text.trim(),
        tipoVia: _tipoViaCtrl.text.trim().isEmpty
            ? null
            : _tipoViaCtrl.text.trim(),

        // Pozo
        tipoSistema: _tipoSistemaCtrl.text.trim(),
        material: _materialCtrl.text.trim().isEmpty
            ? null
            : _materialCtrl.text.trim(),
        conoReduccion: _conoReduccion,
        alturaCono: _parseDouble(_alturaConoCtrl),
        profundidadPozo: _parseDouble(_profundidadPozoCtrl),
        diametroCamara: _parseDouble(_diametroCamaraCtrl),
        elementosPozo: _elementosPozoCtrl.text.trim().isEmpty
            ? null
            : _elementosPozoCtrl.text.trim(),
        estadoElemento: _estadoElementoCtrl.text.trim().isEmpty
            ? null
            : _estadoElementoCtrl.text.trim(),
        materialElemento: _materialElementoCtrl.text.trim().isEmpty
            ? null
            : _materialElementoCtrl.text.trim(),

        // Compartidos extra
        sedimentacion: _sedimentacion,
        coberturaTuberiaSalida: _coberturaTuberiaSalida,
        depositoPredomina: _depositoPredominaCtrl.text.trim().isEmpty
            ? null
            : _depositoPredominaCtrl.text.trim(),
        flujoRepresado: _flujoRepresado,
        nivelCubreCotaSalida: _nivelCubreCotaSalida,
        cotaEstructura: _parseDouble(_cotaEstructuraCtrl),
        condicionesInvestiga: _condicionesCtrl.text.trim().isEmpty
            ? null
            : _condicionesCtrl.text.trim(),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),

        // Sumidero
        tipoSumidero:
            _selectedTipo == 'Sumidero' &&
                _tipoSumideroCtrl.text.trim().isNotEmpty
            ? _tipoSumideroCtrl.text.trim()
            : null,
        anchoSumidero: _selectedTipo == 'Sumidero'
            ? _parseDouble(_anchoSumideroCtrl)
            : null,
        largoSumidero: _selectedTipo == 'Sumidero'
            ? _parseDouble(_largoSumideroCtrl)
            : null,
        alturaSumidero: _selectedTipo == 'Sumidero'
            ? _parseDouble(_alturaSumideroCtrl)
            : null,
        materialSumidero: _selectedTipo == 'Sumidero'
            ? _parseDouble(_materialSumideroCtrl)
            : null,
        anchoRejilla: _selectedTipo == 'Sumidero'
            ? _parseDouble(_anchoRejillaCtrl)
            : null,
        largoRejilla: _selectedTipo == 'Sumidero'
            ? _parseDouble(_largoRejillaCtrl)
            : null,
        alturaRejilla: _selectedTipo == 'Sumidero'
            ? _parseDouble(_alturaRejillaCtrl)
            : null,
        materialRejilla:
            _selectedTipo == 'Sumidero' &&
                _materialRejillaCtrl.text.trim().isNotEmpty
            ? _materialRejillaCtrl.text.trim()
            : null,

        idProyecto: serverProjectId,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estructura hidráulica creada correctamente.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar estructura: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fechaText = _fechaInspeccion == null
        ? 'Seleccionar fecha'
        : '${_fechaInspeccion!.day.toString().padLeft(2, '0')}/'
              '${_fechaInspeccion!.month.toString().padLeft(2, '0')}/'
              '${_fechaInspeccion!.year}';

    final horaText = _horaInspeccion == null
        ? 'Seleccionar hora'
        : '${_horaInspeccion!.hour.toString().padLeft(2, '0')}:'
              '${_horaInspeccion!.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva estructura hidráulica')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proyecto: ${widget.project['nombre'] ?? ''}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ID
                    TextFormField(
                      controller: _idCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'ID de la estructura',
                        helperText:
                            'Se genera automáticamente según el tipo (pz/sm).',
                        prefixIcon: const Icon(Icons.tag),
                        suffixIcon: _loadingId
                            ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Primero selecciona el tipo para generar el ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de estructura',
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _selectedTipo,
                      items: const [
                        DropdownMenuItem(value: 'Pozo', child: Text('Pozo')),
                        DropdownMenuItem(
                          value: 'Sumidero',
                          child: Text('Sumidero'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _onTipoChanged(value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el tipo de estructura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Datos de inspección',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Fecha de inspección'),
                      subtitle: Text(fechaText),
                      onTap: _pickFecha,
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Hora de inspección'),
                      subtitle: Text(horaText),
                      onTap: _pickHora,
                    ),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _climaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Clima durante la inspección',
                        prefixIcon: Icon(Icons.cloud),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tipoViaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vía',
                        prefixIcon: Icon(Icons.alt_route),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Pozo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _tipoSistemaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de sistema',
                        prefixIcon: Icon(Icons.account_tree),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el tipo de sistema';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material (pozo)',
                        prefixIcon: Icon(Icons.construction),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text('Cono de reducción'),
                      value: _conoReduccion,
                      onChanged: (v) => setState(() => _conoReduccion = v),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _alturaConoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Altura del cono (m)',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _profundidadPozoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Profundidad del pozo (m)',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _diametroCamaraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Diámetro de cámara (m)',
                        prefixIcon: Icon(Icons.circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _elementosPozoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Elementos del pozo',
                        prefixIcon: Icon(Icons.list),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _estadoElementoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Estado del elemento',
                        prefixIcon: Icon(Icons.report_problem),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialElementoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material del elemento',
                        prefixIcon: Icon(Icons.construction),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Condición hidráulica (compartido)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Sedimentación'),
                      value: _sedimentacion,
                      onChanged: (v) => setState(() => _sedimentacion = v),
                    ),
                    SwitchListTile(
                      title: const Text('Cobertura en tubería de salida'),
                      value: _coberturaTuberiaSalida,
                      onChanged: (v) =>
                          setState(() => _coberturaTuberiaSalida = v),
                    ),
                    SwitchListTile(
                      title: const Text('Flujo represado'),
                      value: _flujoRepresado,
                      onChanged: (v) => setState(() => _flujoRepresado = v),
                    ),
                    SwitchListTile(
                      title: const Text('Nivel cubre cota de salida'),
                      value: _nivelCubreCotaSalida,
                      onChanged: (v) =>
                          setState(() => _nivelCubreCotaSalida = v),
                    ),

                    TextFormField(
                      controller: _cotaEstructuraCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cota de estructura (m)',
                        prefixIcon: Icon(Icons.height),
                      ),
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

                    TextFormField(
                      controller: _condicionesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Condiciones de investigación',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Sumidero',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _tipoSumideroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de sumidero',
                        prefixIcon: Icon(Icons.grain),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _anchoSumideroCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Ancho del sumidero (m)',
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
                        labelText: 'Largo del sumidero (m)',
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
                        labelText: 'Altura del sumidero (m)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialSumideroCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Material sumidero (valor)',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _anchoRejillaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Ancho de rejilla (m)',
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
                        labelText: 'Largo de rejilla (m)',
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
                        labelText: 'Altura de rejilla (m)',
                        prefixIcon: Icon(Icons.height),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialRejillaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material de rejilla',
                        prefixIcon: Icon(Icons.construction),
                      ),
                    ),

                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _observacionesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes),
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
                        label: const Text('Guardar estructura'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🔹 NUEVO BOTÓN: Agregar fotografía (sin funcionalidad)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving
                            ? null
                            : () {
                                // Aquí luego conectaremos la lógica de fotos
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
        ),
      ),
    );
  }
}
