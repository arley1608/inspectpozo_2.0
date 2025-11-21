import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _contratoCtrl;
  late TextEditingController _contratanteCtrl;
  late TextEditingController _contratistaCtrl;
  late TextEditingController _encargadoCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.project.nombre);
    _contratoCtrl = TextEditingController(text: widget.project.contrato ?? '');
    _contratanteCtrl = TextEditingController(
      text: widget.project.contratante ?? '',
    );
    _contratistaCtrl = TextEditingController(
      text: widget.project.contratista ?? '',
    );
    _encargadoCtrl = TextEditingController(
      text: widget.project.encargado ?? '',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _contratoCtrl.dispose();
    _contratanteCtrl.dispose();
    _contratistaCtrl.dispose();
    _encargadoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final api = context.read<ApiClient>();

    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión inválida, inicia sesión de nuevo.'),
        ),
      );
      return;
    }

    final serverId = widget.project.serverId;
    if (serverId == null) {
      // Si el proyecto aún no está sincronizado con el servidor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este proyecto aún no está sincronizado con el servidor. '
            'Primero sincronízalo antes de modificarlo allí.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Actualizar proyecto en el servidor
      await api.updateProject(
        token: token,
        serverId: serverId,
        nombre: _nombreCtrl.text.trim(),
        contrato: _contratoCtrl.text.trim().isEmpty
            ? null
            : _contratoCtrl.text.trim(),
        contratante: _contratanteCtrl.text.trim().isEmpty
            ? null
            : _contratanteCtrl.text.trim(),
        contratista: _contratistaCtrl.text.trim().isEmpty
            ? null
            : _contratistaCtrl.text.trim(),
        encargado: _encargadoCtrl.text.trim().isEmpty
            ? null
            : _encargadoCtrl.text.trim(),
      );

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proyecto actualizado correctamente en el servidor.'),
        ),
      );

      // Avisamos a la pantalla anterior para que recargue la lista
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar proyecto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar proyecto')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      'Modificar proyecto',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del proyecto',
                        prefixIcon: Icon(Icons.folder),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un nombre para el proyecto';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contratoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contrato',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contratanteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contratante',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contratistaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contratista',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _encargadoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Encargado',
                        prefixIcon: Icon(Icons.engineering),
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
