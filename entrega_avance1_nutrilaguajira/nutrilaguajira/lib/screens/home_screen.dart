import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../services/sync_manager.dart';
import '../widgets/componentes.dart';
import 'acerca_de_screen.dart';
import 'alertas_screen.dart';
import 'historial_screen.dart';
import 'login_screen.dart';
import 'reportes_screen.dart';
import 'seleccion_nino_screen.dart';
import 'zonas_riesgo_screen.dart';

/// Menu principal del prototipo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<(int, int)> _resumen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumen = _cargarResumen();
    if (AppServices.listo) {
      unawaited(AppServices.sync.iniciar());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app (por ejemplo, tras caminar a un punto con señal) se
    // intenta sincronizar sin bloquear la interfaz.
    if (state == AppLifecycleState.resumed && AppServices.listo) {
      unawaited(AppServices.sync.solicitarSincronizacion());
    }
  }

  Future<(int, int)> _cargarResumen() async {
    final ninos = await AppServices.repo.contarNinos();
    final evaluaciones = (await AppServices.repo.historial()).length;
    return (ninos, evaluaciones);
  }

  void _recargar() {
    setState(() => _resumen = _cargarResumen());
    if (AppServices.listo) unawaited(AppServices.sync.refrescar());
  }

  Future<void> _salir() async {
    try {
      await AppServices.sync.detener();
      await AppServices.auth.cerrarSesion();
    } catch (_) {
      // Aunque falle la red o Firebase, la sesión local se cierra.
    }
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
              if (AppServices.listo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TarjetaSincronizacion(
                    onSincronizar: () async {
                      await AppServices.sync.solicitarSincronizacion();
                      _recargar();
                    },
                  ),
                ),
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
                icono: Icons.description,
                titulo: 'Reportes',
                descripcion: 'Exportar CSV y PDF por fecha, ranchería y estado',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReportesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BotonMenu(
                icono: Icons.sms,
                titulo: 'Alertas SMS',
                descripcion:
                    'Cola de alertas de desnutrición aguda para enviar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AlertasScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BotonMenu(
                icono: Icons.warning_amber,
                titulo: 'Zonas en riesgo',
                descripcion:
                    'Consolidado por ranchería, ordenado por criticidad',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ZonasRiesgoScreen(),
                  ),
                ),
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
                          'SQLite es la fuente de verdad y funciona sin '
                          'internet. Al recuperar señal, los registros se '
                          'copian a Firebase solo si iniciaste sesión con tu '
                          'correo.',
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

/// Indicador de sincronización: nube, conectividad y registros pendientes.
///
/// Se actualiza solo con el [ValueNotifier] de [SyncManager]; no consulta la
/// base desde el `build`.
class _TarjetaSincronizacion extends StatelessWidget {
  const _TarjetaSincronizacion({required this.onSincronizar});

  final Future<void> Function() onSincronizar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return ValueListenableBuilder<EstadoSync>(
      valueListenable: AppServices.sync.estado,
      builder: (context, estado, _) {
        final IconData icono;
        final String titulo;
        final String detalle;
        Color color = esquema.primary;

        if (!Sesion.esFirebase) {
          icono = Icons.cloud_off;
          color = esquema.onSurfaceVariant;
          titulo = 'Sincronización inactiva';
          detalle =
              'Inicia sesión con tu correo de Firebase para respaldar los '
              'datos en la nube.';
        } else if (estado.sincronizando) {
          icono = Icons.cloud_sync;
          titulo = 'Sincronizando…';
          detalle = 'Enviando ${estado.pendientes} registro(s) a Firestore.';
        } else if (!estado.enLinea) {
          icono = Icons.cloud_off;
          color = esquema.onSurfaceVariant;
          titulo = 'Sin conexión';
          detalle = estado.pendientes == 0
              ? 'Todo está guardado en el dispositivo.'
              : '${estado.pendientes} registro(s) pendiente(s); se enviarán '
                    'al recuperar la señal.';
        } else if (estado.pendientes > 0) {
          icono = Icons.cloud_upload_outlined;
          color = esquema.tertiary;
          titulo = '${estado.pendientes} por sincronizar';
          detalle = 'Toca el botón para enviarlos ahora a Firestore.';
        } else {
          icono = Icons.cloud_done_outlined;
          titulo = 'Todo sincronizado';
          detalle = estado.ultimaSincronizacion == null
              ? 'No hay registros pendientes.'
              : 'Última sincronización: '
                    '${estado.ultimaSincronizacion!.toLocal().toString().substring(0, 16)}';
        }

        return Card(
          key: const Key('tarjeta-sincronizacion'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: TextStyle(
                          fontSize: 12,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (Sesion.esFirebase)
                  IconButton(
                    tooltip: 'Sincronizar ahora',
                    onPressed: estado.sincronizando ? null : onSincronizar,
                    icon: const Icon(Icons.sync),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
