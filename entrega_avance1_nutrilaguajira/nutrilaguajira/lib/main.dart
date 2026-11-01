import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_services.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/tema.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriLaGuajiraApp());
}

class NutriLaGuajiraApp extends StatelessWidget {
  const NutriLaGuajiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLaGuajira',
      debugShowCheckedModeBanner: false,
      theme: construirTema(Brightness.light),
      darkTheme: construirTema(Brightness.dark),
      // La app se usa en campo y a plena luz: tema claro por defecto.
      themeMode: ThemeMode.light,
      // Toda la interfaz en español, incluidos los diálogos del sistema
      // (selector de fecha, menús de copiar/pegar, tooltips).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PantallaArranque(),
    );
  }
}

/// Inicializa la base local (esquema + semilla) antes de mostrar el login.
/// Si algo falla, se muestra el error en lugar de una pantalla en blanco.
class PantallaArranque extends StatefulWidget {
  const PantallaArranque({super.key});

  @override
  State<PantallaArranque> createState() => _PantallaArranqueState();
}

class _PantallaArranqueState extends State<PantallaArranque> {
  Object? _error;
  bool _listo = false;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      await AppServices.init();
      if (!mounted) return;
      setState(() => _listo = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  'No se pudo abrir la base local',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$_error', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _listo = false;
                    });
                    _iniciar();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_listo) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 72),
              SizedBox(height: 20),
              Text(
                'NutriLaGuajira',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text('Preparando datos locales...'),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return const LoginScreen();
  }
}

/// Ruta raiz reutilizable: vuelve a la pantalla principal limpiando la pila.
void irAlInicio(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    (route) => false,
  );
}
