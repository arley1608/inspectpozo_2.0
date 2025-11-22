import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/local/app_database.dart';
import '../data/repo/project_repository.dart';
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

    final projectRepo = context.read<ProjectRepository>();
    final api = context.read<ApiClient>();
    final auth = context.read<AuthService>();

    setState(() => _saving = true);

    final String nombre = _nombreCtrl.text.trim();
    final String? contrato = _contratoCtrl.text.trim().isEmpty
        ? null
        : _contratoCtrl.text.trim();
    final String? contratante = _contratanteCtrl.text.trim().isEmpty
        ? null
        : _contratanteCtrl.text.trim();
    final String? contratista = _contratistaCtrl.text.trim().isEmpty
        ? null
        : _contratistaCtrl.text.trim();
    final String? encargado = _encargadoCtrl.text.trim().isEmpty
        ? null
        : _encargadoCtrl.text.trim();

    try {
      // 1) Si hay serverId y token, actualizamos en el servidor
      final token = auth.token;
      final serverId = widget.project.serverId;

      if (token != null && serverId != null) {
        await api.updateProject(
          token: token,
          serverId: serverId,
          nombre: nombre,
          contrato: contrato,
          contratante: contratante,
          contratista: contratista,
          encargado: encargado,
        );
      }

      // 2) Siempre actualizamos el registro local
      await projectRepo.updateLocalProjectFields(
        localId: widget.project.id,
        nombre: nombre,
        contrato: contrato,
        contratante: contratante,
        contratista: contratista,
        encargado: encargado,
      );

      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto actualizado correctamente')),
      );

      // Volvemos pasando true para que el listado refresque
      Navigator.of(context).pop(true);
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

                    // Nombre
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

                    // Contrato
                    TextFormField(
                      controller: _contratoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contrato',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contratante
                    TextFormField(
                      controller: _contratanteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contratante',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Contratista
                    TextFormField(
                      controller: _contratistaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contratista',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Encargado
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
