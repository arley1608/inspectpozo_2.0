import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = context.read<AuthService>();

    try {
      await auth.login(
        usuario: _userCtrl.text.trim(),
        contrasenia: _passCtrl.text,
      );
      // Si llega aquí, login OK.
      // MyApp cambiará de LoginScreen a HomeScreen según isAuthenticated.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
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

                    // Logo arriba (sin texto), con fallback si el asset no existe
                    Image.asset(
                      'assets/logo_inspectpozo.png',
                      height: size.height * 0.25,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const FlutterLogo(size: 100),
                    ),

                    const SizedBox(height: 40),

                    // Campo USUARIO
                    TextFormField(
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa tu usuario';
                        }
                        if (v.trim().length < 3) {
                          return 'Mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),

                    spacing,

                    // Campo CONTRASEÑA
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Ingresa tu contraseña';
                        }
                        if (v.length < 4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                    ),

                    const SizedBox(height: 24),

                    // Botón principal: Iniciar sesión
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Iniciar sesión'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón secundario: Registrarse
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Registrarse'),
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
