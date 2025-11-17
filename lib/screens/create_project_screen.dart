import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repo/project_repository.dart';
import '../services/auth_service.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _contratoCtrl = TextEditingController();
  final _contratanteCtrl = TextEditingController();
  final _contratistaCtrl = TextEditingController();
  final _encargadoCtrl = TextEditingController();

  bool _saving = false;

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

    setState(() => _saving = true);

    final projectRepo = context.read<ProjectRepository>();
    final auth = context.read<AuthService>();

    try {
      // 1) Crear proyecto en modo offline (SQLite + Outbox)
      await projectRepo.createProjectOffline(
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

      // 2) Intentar sincronizar inmediatamente si tenemos token (y conexión)
      final token = auth.token;
      if (token != null) {
        try {
          await projectRepo.syncPending(token: token);
        } catch (_) {
          // Si no hay internet o falla, no rompemos el flujo:
          // el proyecto quedará pendiente y se sincronizará después.
        }
      }

      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proyecto creado localmente. Se sincronizará con el servidor cuando sea posible.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear proyecto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 420.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear nuevo proyecto')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del proyecto',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingrese el nombre del proyecto';
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
                        prefixIcon: Icon(Icons.engineering),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _encargadoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Encargado',
                        prefixIcon: Icon(Icons.account_circle),
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
                        label: const Text('Guardar proyecto'),
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
