import 'package:flutter/material.dart';

import '../app_services.dart';
import 'home_screen.dart';

/// Login local del prototipo.
///
/// Las credenciales demo viven en la tabla `usuarios` de SQLite
/// (promotor / demo123). No hay servidor, ni tokens, ni seguridad real:
/// es solo una puerta de entrada para el Avance 1.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();

  bool _cargando = false;
  bool _verClave = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _usarCredencialesDemo() {
    setState(() {
      _usuario.text = 'promotor';
      _clave.text = 'demo123';
      _error = null;
    });
  }

  Future<void> _ingresar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final usuario = await AppServices.repo.autenticar(
        _usuario.text,
        _clave.text,
      );
      if (!mounted) return;
      if (usuario == null) {
        setState(() {
          _cargando = false;
          _error = 'Usuario o contraseña incorrectos';
        });
        return;
      }
      Sesion.usuario = usuario;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo iniciar sesión: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 72,
                      color: esquema.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NutriLaGuajira',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Avance 1 · Tamizaje rápido y semáforo nutricional offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usuario,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                          ? 'Ingrese el usuario'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_verClave,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verClave
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(
                            _verClave ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _verClave = !_verClave),
                        ),
                      ),
                      validator: (valor) => (valor == null || valor.isEmpty)
                          ? 'Ingrese la contraseña'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esquema.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: esquema.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: esquema.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: esquema.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Credenciales demo',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Usuario: promotor'),
                            const Text('Contraseña: demo123'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _usarCredencialesDemo,
                              icon: const Icon(Icons.flash_on),
                              label: const Text('Usar credenciales demo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 18,
                          color: esquema.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Funciona sin internet · datos en el dispositivo',
                            style: TextStyle(
                              fontSize: 13,
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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
