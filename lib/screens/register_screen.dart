import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repo/user_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _obsc1 = true;
  bool _obsc2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final repo = context.read<UserRepository>();

    try {
      // 1) Crear usuario local + encolar para sync
      await repo.createUserOffline(
        usuario: _userCtrl.text.trim(),
        nombre: _nameCtrl.text.trim(),
        contrasenia: _passCtrl.text,
      );

      // 2) Intentar sincronizar inmediatamente con el servidor (si hay red)
      try {
        await repo.syncPending();

        if (!mounted) return;
        setState(() => _loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario creado y sincronizado correctamente. Ahora puedes iniciar sesión.',
            ),
          ),
        );
      } catch (_) {
        // Si no hay internet o falla, se sincronizará más tarde.
        if (!mounted) return;
        setState(() => _loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuario creado localmente. Se sincronizará con el servidor cuando haya conexión.',
            ),
          ),
        );
      }

      // 3) Volver al login SIN iniciar sesión automáticamente
      Navigator.pop(context);
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
    final spacing = const SizedBox(height: 16);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 24),

                    // Logo arriba, mismo que en login
                    Image.asset(
                      'assets/logo_inspectpozo.png',
                      height: size.height * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const FlutterLogo(size: 100),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Crear cuenta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registra un nuevo usuario para acceder a InspectPozo.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Campo NOMBRE
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        if (value.length < 3) {
                          return 'El nombre debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),

                    spacing,

                    // Campo USUARIO
                    TextFormField(
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ej: arley.rod',
                        prefixIcon: Icon(Icons.alternate_email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) {
                          return 'Ingresa un usuario';
                        }
                        if (value.length < 3) {
                          return 'El usuario debe tener al menos 3 caracteres';
                        }
                        return null;
                      },
                    ),

                    spacing,

                    // Campo CONTRASEÑA
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obsc1,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obsc1 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obsc1 = !_obsc1),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa una contraseña';
                        }
                        if (v.length < 4) {
                          return 'La contraseña debe tener al menos 4 caracteres';
                        }
                        return null;
                      },
                    ),

                    spacing,

                    // Campo REPETIR CONTRASEÑA
                    TextFormField(
                      controller: _pass2Ctrl,
                      obscureText: _obsc2,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Repetir contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obsc2 ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obsc2 = !_obsc2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Repite la contraseña';
                        }
                        if (v != _passCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (!_loading) _submit();
                      },
                    ),

                    const SizedBox(height: 24),

                    // Botón principal: Crear cuenta (mismo estilo que login)
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear cuenta'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón secundario: Volver al login
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver al inicio de sesión'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
