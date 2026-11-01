import 'package:flutter/material.dart';

import '../app_services.dart';
import '../widgets/componentes.dart';
import 'acerca_de_screen.dart';
import 'historial_screen.dart';
import 'login_screen.dart';
import 'seleccion_nino_screen.dart';

/// Menu principal del prototipo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(int, int)> _resumen;

  @override
  void initState() {
    super.initState();
    _resumen = _cargarResumen();
  }

  Future<(int, int)> _cargarResumen() async {
    final ninos = await AppServices.repo.contarNinos();
    final evaluaciones = (await AppServices.repo.historial()).length;
    return (ninos, evaluaciones);
  }

  void _recargar() {
    setState(() => _resumen = _cargarResumen());
  }

  Future<void> _salir() async {
    Sesion.cerrar();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriLaGuajira'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _salir,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _recargar(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Hola, ${Sesion.nombre}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Tamizaje rápido de desnutrición infantil · modo offline',
                style: TextStyle(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FutureBuilder<(int, int)>(
                future: _resumen,
                builder: (context, snapshot) {
                  final datos = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: _TarjetaResumen(
                          valor: datos == null ? '—' : '${datos.$1}',
                          etiqueta: 'Infantes',
                          icono: Icons.child_care,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TarjetaResumen(
                          valor: datos == null ? '—' : '${datos.$2}',
                          etiqueta: 'Tamizajes',
                          icono: Icons.assignment_turned_in_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              BotonMenu(
                icono: Icons.monitor_heart_outlined,
                titulo: 'Nuevo tamizaje',
                descripcion: 'Registrar infante y evaluación antropométrica con semáforo',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SeleccionNinoScreen(),
                    ),
                  );
                  _recargar();
                },
              ),
              const SizedBox(height: 14),
              BotonMenu(
                icono: Icons.history,
                titulo: 'Historial',
                descripcion: 'Evaluaciones guardadas en este dispositivo',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HistorialScreen(),
                    ),
                  );
                  _recargar();
                },
              ),
              const SizedBox(height: 14),
              BotonMenu(
                icono: Icons.info_outline,
                titulo: 'Acerca de',
                descripcion: 'Alcance, limitaciones y aviso académico',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AcercaDeScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Próximo sprint',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: esquema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChipProximoSprint(etiqueta: 'GPS/Reportes: próximo sprint'),
                  ChipProximoSprint(etiqueta: 'SMS: próximo sprint'),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined, color: esquema.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Todo se guarda en SQLite dentro del teléfono. '
                          'No se envía información a internet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: esquema.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({
    required this.valor,
    required this.etiqueta,
    required this.icono,
  });

  final String valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icono, color: esquema.primary, size: 26),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 13,
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
