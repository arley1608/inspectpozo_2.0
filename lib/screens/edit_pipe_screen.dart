import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class EditPipeScreen extends StatefulWidget {
  final Map<String, dynamic> pipe;

  const EditPipeScreen({super.key, required this.pipe});

  @override
  State<EditPipeScreen> createState() => _EditPipeScreenState();
}

class _EditPipeScreenState extends State<EditPipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // ---- Datos de la tubería ----
  late final String _pipeId;
  late final String _estructuraInicioId;
  late final String _estructuraDestinoId;

  // Campos básicos
  final _diametroCtrl = TextEditingController(); // pulgadas
  final _materialCtrl = TextEditingController(); // se rellena desde dropdown
  final _estadoCtrl = TextEditingController(); // se rellena desde dropdown
  bool _flujo = false;
  bool _sedimento = false;
  final _gradosCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // Profundidades / cotas inicio
  final _profClaveInicioCtrl = TextEditingController();
  final _profBateaInicioCtrl = TextEditingController();
  final _cotaClaveInicioCtrl = TextEditingController();
  final _cotaBateaInicioCtrl = TextEditingController();

  // Profundidades / cotas destino
  final _profClaveDestinoCtrl = TextEditingController();
  final _profBateaDestinoCtrl = TextEditingController();
  final _cotaClaveDestinoCtrl = TextEditingController();
  final _cotaBateaDestinoCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pipe;

    _pipeId = p['id']?.toString() ?? '';
    _estructuraInicioId = p['id_estructura_inicio']?.toString() ?? '';
    _estructuraDestinoId = p['id_estructura_destino']?.toString() ?? '';

    // Cargar valores en los controllers
    _diametroCtrl.text = _toText(p['diametro']);
    _materialCtrl.text = p['material']?.toString() ?? '';
    _estadoCtrl.text = p['estado']?.toString() ?? '';
    _flujo = p['flujo'] == true;
    _sedimento = p['sedimento'] == true;
    _gradosCtrl.text = _toText(p['grados']);
    _observacionesCtrl.text = p['observaciones']?.toString() ?? '';

    _profClaveInicioCtrl.text = _toText(p['profundidad_clave_inicio']);
    _profBateaInicioCtrl.text = _toText(p['profundidad_batea_inicio']);
    _cotaClaveInicioCtrl.text = _toText(p['cota_clave_inicio']);
    _cotaBateaInicioCtrl.text = _toText(p['cota_batea_inicio']);

    _profClaveDestinoCtrl.text = _toText(p['profundidad_clave_destino']);
    _profBateaDestinoCtrl.text = _toText(p['profundidad_batea_destino']);
    _cotaClaveDestinoCtrl.text = _toText(p['cota_clave_destino']);
    _cotaBateaDestinoCtrl.text = _toText(p['cota_batea_destino']);
  }

  @override
  void dispose() {
    _diametroCtrl.dispose();
    _materialCtrl.dispose();
    _estadoCtrl.dispose();
    _gradosCtrl.dispose();
    _observacionesCtrl.dispose();

    _profClaveInicioCtrl.dispose();
    _profBateaInicioCtrl.dispose();
    _cotaClaveInicioCtrl.dispose();
    _cotaBateaInicioCtrl.dispose();

    _profClaveDestinoCtrl.dispose();
    _profBateaDestinoCtrl.dispose();
    _cotaClaveDestinoCtrl.dispose();
    _cotaBateaDestinoCtrl.dispose();

    super.dispose();
  }

  // ------------ Helpers numéricos ------------

  String _toText(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  double? _toDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  String? _validatePositiveOptional(
    String? value, {
    String label = 'valor',
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'Ingresa $label';
      return null;
    }
    final d = double.tryParse(value.replaceAll(',', '.'));
    if (d == null) return 'Valor inválido en $label';
    if (d <= 0) return '$label debe ser mayor a 0';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();
    final token = auth.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión nuevamente.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await api.updatePipe(
        token: token,
        id: _pipeId,
        diametro: _toDouble(_diametroCtrl.text),
        material: _materialCtrl.text.trim().isEmpty
            ? null
            : _materialCtrl.text.trim(),
        flujo: _flujo,
        estado: _estadoCtrl.text.trim().isEmpty
            ? null
            : _estadoCtrl.text.trim(),
        sedimento: _sedimento,
        cotaClaveInicio: _toDouble(_cotaClaveInicioCtrl.text),
        cotaBateaInicio: _toDouble(_cotaBateaInicioCtrl.text),
        profundidadClaveInicio: _toDouble(_profClaveInicioCtrl.text),
        profundidadBateaInicio: _toDouble(_profBateaInicioCtrl.text),
        cotaClaveDestino: _toDouble(_cotaClaveDestinoCtrl.text),
        cotaBateaDestino: _toDouble(_cotaBateaDestinoCtrl.text),
        profundidadClaveDestino: _toDouble(_profClaveDestinoCtrl.text),
        profundidadBateaDestino: _toDouble(_profBateaDestinoCtrl.text),
        grados: _toDouble(_gradosCtrl.text),
        observaciones: _observacionesCtrl.text.trim().isEmpty
            ? null
            : _observacionesCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tubería modificada correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al modificar tubería: $e')));
    }
  }

  // ------------ UI ------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Modificar tubería')),
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
                      'Editar tubería',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: $_pipeId\n'
                      'Estructura inicio: $_estructuraInicioId\n'
                      'Estructura destino: $_estructuraDestinoId',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ID tubería (solo lectura)
                    TextFormField(
                      initialValue: _pipeId,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'ID de la tubería',
                        prefixIcon: Icon(Icons.plumbing),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estructura inicio (solo lectura)
                    TextFormField(
                      initialValue: _estructuraInicioId,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Estructura de inicio',
                        prefixIcon: Icon(Icons.play_arrow),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Estructura destino (solo lectura)
                    TextFormField(
                      initialValue: _estructuraDestinoId,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Estructura de destino',
                        prefixIcon: Icon(Icons.stop_circle),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Parámetros hidráulicos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Diámetro en pulgadas (0 < d < 32)
                    TextFormField(
                      controller: _diametroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Diámetro (pulgadas)',
                        prefixIcon: Icon(Icons.radar),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el diámetro en pulgadas';
                        }
                        final d = double.tryParse(value.replaceAll(',', '.'));
                        if (d == null) return 'Valor inválido';
                        if (d <= 0) {
                          return 'El diámetro debe ser mayor a 0';
                        }
                        if (d >= 32) {
                          return 'El diámetro debe ser menor a 32 pulgadas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Material (dropdown)
                    DropdownButtonFormField<String>(
                      value: _materialCtrl.text.isEmpty
                          ? null
                          : _materialCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Concreto',
                          child: Text('Concreto'),
                        ),
                        DropdownMenuItem(value: 'Gres', child: Text('Gres')),
                        DropdownMenuItem(value: 'PVC', child: Text('PVC')),
                        DropdownMenuItem(value: 'Acero', child: Text('Acero')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _materialCtrl.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el material';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Flujo como booleano
                    SwitchListTile(
                      title: const Text('Flujo'),
                      subtitle: const Text('Indica si presenta flujo'),
                      value: _flujo,
                      onChanged: (v) {
                        setState(() {
                          _flujo = v;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Estado (dropdown)
                    DropdownButtonFormField<String>(
                      value: _estadoCtrl.text.isEmpty ? null : _estadoCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Bueno', child: Text('Bueno')),
                        DropdownMenuItem(
                          value: 'Regular',
                          child: Text('Regular'),
                        ),
                        DropdownMenuItem(value: 'Malo', child: Text('Malo')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _estadoCtrl.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona un estado';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Sedimento'),
                      value: _sedimento,
                      onChanged: (v) {
                        setState(() {
                          _sedimento = v;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _gradosCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Grados (0° a 360°)',
                        prefixIcon: Icon(Icons.rotate_right),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa los grados';
                        }

                        final g = double.tryParse(value.replaceAll(',', '.'));
                        if (g == null) return 'Valor inválido';

                        if (g < 0 || g > 360) {
                          return 'Debe estar entre 0 y 360 grados';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Cotas y profundidades — Inicio',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profClaveInicioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad clave inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Profundidad clave inicio',
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profBateaInicioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad batea inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Profundidad batea inicio',
                        required: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cotaClaveInicioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cota clave inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Cota clave inicio',
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cotaBateaInicioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cota batea inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Cota batea inicio',
                        required: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Cotas y profundidades — Destino',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profClaveDestinoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad clave destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Profundidad clave destino',
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _profBateaDestinoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad batea destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Profundidad batea destino',
                        required: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cotaClaveDestinoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cota clave destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Cota clave destino',
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cotaBateaDestinoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cota batea destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Cota batea destino',
                        required: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _observacionesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
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
