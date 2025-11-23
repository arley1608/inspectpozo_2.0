import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class CreatePipeScreen extends StatefulWidget {
  /// Mapa completo de la estructura seleccionada en el detalle.
  /// Debe contener al menos:
  /// - 'id'              → id de la estructura de inicio
  /// - 'tipo'            → tipo de estructura (Pozo / Sumidero)
  /// - 'id_proyecto'     → id del proyecto en el servidor
  /// - 'cota_estructura' → cota de la estructura (m)
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
  double? _cotaEstructuraInicio;
  double? _cotaEstructuraDestino;

  // ---- Campos básicos tubería ----
  final _idCtrl = TextEditingController();
  final _diametroCtrl = TextEditingController(); // pulgadas
  final _materialCtrl = TextEditingController(); // texto desde dropdown
  final _estadoCtrl = TextEditingController(); // texto desde dropdown
  bool _flujo = false; // flujo como booleano en UI
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

  // ----- Estructuras destino -----
  String? _estructuraDestinoId;
  List<Map<String, dynamic>> _estructurasProyecto = [];
  bool _loadingEstructuras = true;

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

    // Cota estructura inicio
    final cotaIniRaw = s['cota_estructura'];
    _cotaEstructuraInicio = _parseDynamicToDouble(cotaIniRaw);

    _loadEstructurasProyecto();

    // 👉 Recalcular campos automáticos cuando cambien estos valores
    _diametroCtrl.addListener(_recalcularCamposAutomaticos);
    _profClaveInicioCtrl.addListener(_recalcularCamposAutomaticos);
    _profClaveDestinoCtrl.addListener(_recalcularCamposAutomaticos);
  }

  @override
  void dispose() {
    _idCtrl.dispose();
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

  double? _toDouble(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  double? _parseDynamicToDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
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

  /// 👉 Calcula:
  /// - profundidad_batea = profundidad_clave + diámetro_en_metros
  /// - cota_clave        = cota_estructura - profundidad_clave
  /// - cota_batea        = cota_estructura - profundidad_batea
  /// para inicio y destino.
  void _recalcularCamposAutomaticos() {
    final diamPulg = _toDouble(_diametroCtrl.text);
    final diamMetros = (diamPulg != null && diamPulg > 0)
        ? diamPulg * 0.0254
        : null;

    // ----- INICIO -----
    final profClaveIni = _toDouble(_profClaveInicioCtrl.text);
    double? profBateaIni;

    if (profClaveIni != null && profClaveIni > 0) {
      // Profundidad batea inicio
      if (diamMetros != null) {
        profBateaIni = profClaveIni + diamMetros;
        _profBateaInicioCtrl.text = profBateaIni.toStringAsFixed(3);
      } else {
        profBateaIni = null;
        _profBateaInicioCtrl.text = '';
      }

      // Cota clave inicio = cota estructura inicio - profundidad clave
      if (_cotaEstructuraInicio != null) {
        final cotaClaveIni = _cotaEstructuraInicio! - profClaveIni;
        _cotaClaveInicioCtrl.text = cotaClaveIni.toStringAsFixed(3);
      } else {
        _cotaClaveInicioCtrl.text = '';
      }

      // Cota batea inicio = cota estructura inicio - profundidad batea
      if (_cotaEstructuraInicio != null && profBateaIni != null) {
        final cotaBateaIni = _cotaEstructuraInicio! - profBateaIni;
        _cotaBateaInicioCtrl.text = cotaBateaIni.toStringAsFixed(3);
      } else {
        _cotaBateaInicioCtrl.text = '';
      }
    } else {
      _profBateaInicioCtrl.text = '';
      _cotaClaveInicioCtrl.text = '';
      _cotaBateaInicioCtrl.text = '';
    }

    // ----- DESTINO -----
    final profClaveDest = _toDouble(_profClaveDestinoCtrl.text);
    double? profBateaDest;

    if (profClaveDest != null && profClaveDest > 0) {
      // Profundidad batea destino
      if (diamMetros != null) {
        profBateaDest = profClaveDest + diamMetros;
        _profBateaDestinoCtrl.text = profBateaDest.toStringAsFixed(3);
      } else {
        profBateaDest = null;
        _profBateaDestinoCtrl.text = '';
      }

      // Cota clave destino = cota estructura destino - profundidad clave
      if (_cotaEstructuraDestino != null) {
        final cotaClaveDest = _cotaEstructuraDestino! - profClaveDest;
        _cotaClaveDestinoCtrl.text = cotaClaveDest.toStringAsFixed(3);
      } else {
        _cotaClaveDestinoCtrl.text = '';
      }

      // Cota batea destino = cota estructura destino - profundidad batea
      if (_cotaEstructuraDestino != null && profBateaDest != null) {
        final cotaBateaDest = _cotaEstructuraDestino! - profBateaDest;
        _cotaBateaDestinoCtrl.text = cotaBateaDest.toStringAsFixed(3);
      } else {
        _cotaBateaDestinoCtrl.text = '';
      }
    } else {
      _profBateaDestinoCtrl.text = '';
      _cotaClaveDestinoCtrl.text = '';
      _cotaBateaDestinoCtrl.text = '';
    }
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
        diametro: _toDouble(_diametroCtrl.text), // pulgadas
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
                                // Actualizamos cota_estructura destino
                                if (value != null) {
                                  final dest = _estructurasProyecto.firstWhere(
                                    (e) => (e['id']?.toString() ?? '') == value,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  _cotaEstructuraDestino =
                                      _parseDynamicToDouble(
                                        dest['cota_estructura'],
                                      );
                                } else {
                                  _cotaEstructuraDestino = null;
                                }
                              });
                              // Recalcular porque ahora tenemos nueva cota destino
                              _recalcularCamposAutomaticos();
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

                    // Profundidad batea inicio (auto)
                    TextFormField(
                      controller: _profBateaInicioCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad batea inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cota clave inicio (auto)
                    TextFormField(
                      controller: _cotaClaveInicioCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Cota clave inicio (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cota batea inicio (auto)
                    TextFormField(
                      controller: _cotaBateaInicioCtrl,
                      readOnly: true,
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
                      validator: (v) => _validatePositiveOptional(
                        v,
                        label: 'Profundidad clave destino',
                        required: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Profundidad batea destino (auto)
                    TextFormField(
                      controller: _profBateaDestinoCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad batea destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cota clave destino (auto)
                    TextFormField(
                      controller: _cotaClaveDestinoCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Cota clave destino (m)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cota batea destino (auto)
                    TextFormField(
                      controller: _cotaBateaDestinoCtrl,
                      readOnly: true,
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
