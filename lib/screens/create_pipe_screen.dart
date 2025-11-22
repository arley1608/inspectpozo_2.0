import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class CreatePipeScreen extends StatefulWidget {
  /// Mapa completo de la estructura seleccionada en el detalle.
  /// Debe contener al menos:
  /// - 'id'          → id de la estructura de inicio
  /// - 'tipo'        → tipo de estructura (Pozo / Sumidero)
  /// - 'id_proyecto' → id del proyecto en el servidor
  final Map<String, dynamic> structure;

  const CreatePipeScreen({super.key, required this.structure});

  @override
  State<CreatePipeScreen> createState() => _CreatePipeScreenState();
}

class _CreatePipeScreenState extends State<CreatePipeScreen> {
  final _formKey = GlobalKey<FormState>();

  // ---- Datos derivados de la estructura de inicio ----
  late final String _estructuraInicioId;
  late final String _estructuraInicioLabel; // ej. "PZ0001 - Pozo"
  int? _projectServerId; // id_proyecto en servidor

  // ---- Campos básicos tubería ----
  final _idCtrl = TextEditingController();
  final _diametroCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _flujoCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
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

  // ----- Estructuras -----
  String? _estructuraDestinoId;
  List<Map<String, dynamic>> _estructurasProyecto = [];
  bool _loadingEstructuras = true;

  // ----- Foto opcional -----
  final ImagePicker _picker = ImagePicker();
  XFile? _fotoInspeccion;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Tomamos los datos de la estructura de inicio desde el Map
    final s = widget.structure;
    _estructuraInicioId = (s['id'] ?? '').toString();
    final tipo = (s['tipo'] ?? '').toString();
    _estructuraInicioLabel = tipo.isEmpty
        ? _estructuraInicioId
        : '$_estructuraInicioId - $tipo';

    final proj = s['id_proyecto'];
    if (proj is int) {
      _projectServerId = proj;
    } else if (proj is String) {
      _projectServerId = int.tryParse(proj);
    } else {
      _projectServerId = null;
    }

    _loadEstructurasProyecto();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _diametroCtrl.dispose();
    _materialCtrl.dispose();
    _flujoCtrl.dispose();
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

  // ------------ Helpers ------------

  double? _toDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  Future<void> _loadEstructurasProyecto() async {
    if (_projectServerId == null) {
      setState(() {
        _loadingEstructuras = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este registro no tiene id_proyecto válido; '
              'no es posible cargar estructuras del proyecto.',
            ),
          ),
        );
      }
      return;
    }

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();
    final token = auth.token;

    if (token == null) {
      setState(() {
        _loadingEstructuras = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión de nuevo.'),
        ),
      );
      return;
    }

    try {
      final list = await api.getHydraulicStructures(
        token: token,
        projectServerId: _projectServerId!,
      );

      // Opcional: excluir la propia estructura inicio
      final filtered = list.where((e) {
        final id = e['id']?.toString();
        return id != null && id != _estructuraInicioId;
      }).toList();

      setState(() {
        _estructurasProyecto = filtered;
        _loadingEstructuras = false;
      });
    } catch (e) {
      setState(() {
        _loadingEstructuras = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando estructuras: $e')));
    }
  }

  Future<void> _pickSimplePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() {
      _fotoInspeccion = picked;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_estructuraDestinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la estructura de destino.')),
      );
      return;
    }

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
      await api.createPipe(
        token: token,
        id: _idCtrl.text.trim(),
        diametro: _toDouble(_diametroCtrl.text),
        material: _materialCtrl.text.trim().isEmpty
            ? null
            : _materialCtrl.text.trim(),
        flujo: _flujoCtrl.text.trim().isEmpty ? null : _flujoCtrl.text.trim(),
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
        idEstructuraInicio: _estructuraInicioId,
        idEstructuraDestino: _estructuraDestinoId!,
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tubería creada correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear tubería: $e')));
    }
  }

  // ------------ UI ------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar tubería')),
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
                      'Nueva tubería',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proyecto: ${_projectServerId ?? 'sin id'}\n'
                      'Estructura de inicio: $_estructuraInicioLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ID tubería
                    TextFormField(
                      controller: _idCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID de la tubería',
                        prefixIcon: Icon(Icons.plumbing),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un ID para la tubería';
                        }
                        return null;
                      },
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

                    // Estructura destino (dropdown)
                    _loadingEstructuras
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: LinearProgressIndicator(),
                          )
                        : DropdownButtonFormField<String>(
                            value: _estructuraDestinoId,
                            decoration: const InputDecoration(
                              labelText: 'Estructura de destino',
                              prefixIcon: Icon(Icons.stop_circle),
                            ),
                            items: _estructurasProyecto.map((e) {
                              final id = e['id']?.toString() ?? '';
                              final tipo = e['tipo']?.toString() ?? '';
                              return DropdownMenuItem<String>(
                                value: id,
                                child: Text(tipo.isEmpty ? id : '$id ($tipo)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _estructuraDestinoId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecciona la estructura de destino';
                              }
                              return null;
                            },
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

                    TextFormField(
                      controller: _diametroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Diámetro (m)',
                        prefixIcon: Icon(Icons.radar),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _materialCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _flujoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Flujo',
                        prefixIcon: Icon(Icons.water),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _estadoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
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
                        labelText: 'Grados (inclinación)',
                        prefixIcon: Icon(Icons.rotate_right),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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

                    if (_fotoInspeccion != null)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_fotoInspeccion!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickSimplePhoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(
                          _fotoInspeccion == null
                              ? 'Tomar foto de referencia (opcional)'
                              : 'Repetir foto de referencia',
                        ),
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
                        label: const Text('Guardar tubería'),
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
