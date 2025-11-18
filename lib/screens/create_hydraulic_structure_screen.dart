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

  // Campos
  final _idCtrl = TextEditingController();
  final _climaCtrl = TextEditingController();
  final _tipoViaCtrl = TextEditingController();
  final _tipoSistemaCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // Nuevo: tipo de estructura (Pozo / Sumidero)
  String? _selectedTipo; // "Pozo" o "Sumidero"

  DateTime? _fechaInspeccion;
  TimeOfDay? _horaInspeccion;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _idCtrl.text =
        'EH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _climaCtrl.dispose();
    _tipoViaCtrl.dispose();
    _tipoSistemaCtrl.dispose();
    _materialCtrl.dispose();
    _observacionesCtrl.dispose();
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

    if (_fechaInspeccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de inspección.')),
      );
      return;
    }

    if (_horaInspeccion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la hora de inspección.')),
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
        tipo: _selectedTipo, // 👈 Pozo o Sumidero
        fechaInspeccion: _fechaInspeccion!,
        horaInspeccion: horaStr,
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
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Proyecto: ${widget.project['nombre'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ID de la estructura
                    TextFormField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID de la estructura',
                        helperText:
                            'Debe ser único (puedes dejar el generado automáticamente).',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un ID para la estructura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // 🔽 Tipo de estructura: Pozo / Sumidero
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
                        setState(() => _selectedTipo = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el tipo de estructura';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Fecha de inspección
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: const Text('Fecha de inspección'),
                      subtitle: Text(fechaText),
                      onTap: _pickFecha,
                    ),
                    const SizedBox(height: 4),

                    // Hora de inspección
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
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _tipoSistemaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de sistema',
                        prefixIcon: Icon(Icons.account_tree),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material principal',
                        prefixIcon: Icon(Icons.construction),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _observacionesCtrl,
                      maxLines: 4,
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
