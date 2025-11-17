import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repo/user_repository.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _obsc1 = true;
  bool _obsc2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final repo = context.read<UserRepository>();
    final auth = context.read<AuthService>();

    try {
      // 1) Crear usuario local + encolar para sync
      await repo.createUserOffline(
        usuario: _emailCtrl.text.trim(),
        nombre: _nameCtrl.text.trim(),
        contrasenia: _passCtrl.text,
      );

      // 2) Intentar sincronizar inmediatamente con el servidor (si hay red)
      try {
        await repo.syncPending();
      } catch (_) {
        // Si no hay internet o falla, se sincronizará más tarde.
      }

      // 3) Intentar login online con el usuario recién creado
      try {
        await auth.login(
          usuario: _emailCtrl.text.trim(),
          contrasenia: _passCtrl.text,
        );

        if (!mounted) return;
        setState(() => _loading = false);

        // Si el login fue exitoso, volvemos.
        Navigator.pop(context);
      } catch (_) {
        if (!mounted) return;
        setState(() => _loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario creado localmente. Se sincronizará con el servidor cuando haya conexión.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo igual que en login
                    Image.asset(
                      'assets/logo_inspectpozo.png',
                      height: size.height * 0.18,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const FlutterLogo(size: 80),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingrese un correo';
                        }
                        if (!v.contains('@')) {
                          return 'Correo no válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'Ingrese su nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obsc1 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obsc1 = !_obsc1),
                        ),
                      ),
                      obscureText: _obsc1,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingrese una contraseña';
                        }
                        if (v.length < 4) {
                          return 'Mínimo 4 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass2Ctrl,
                      decoration: InputDecoration(
                        labelText: 'Repite la contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obsc2 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obsc2 = !_obsc2),
                        ),
                      ),
                      obscureText: _obsc2,
                      validator: (v) {
                        if (v != _passCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: const Text('Crear cuenta'),
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
