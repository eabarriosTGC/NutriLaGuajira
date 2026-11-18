import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/models/alerta_pendiente.dart';
import '../data/repositorio.dart';
import '../services/alerta_service.dart';
import '../services/fechas.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';

/// Cola local de alertas de desnutrición aguda (RF-10).
///
/// Permite ver el estado de cada alerta (PENDIENTE/ENVIADA/FALLIDA), enviarla
/// con un intent de SMS y reintentar las fallidas. El envío abre la app de
/// mensajes del sistema: no se envía en silencio ni requiere SEND_SMS.
class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key, this.repo, this.alertaService});

  /// Inyectables para pruebas; por defecto usan los servicios de la app.
  final Repositorio? repo;
  final AlertaService? alertaService;

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  late final Repositorio _repo = widget.repo ?? AppServices.repo;
  late final AlertaService _servicio =
      widget.alertaService ?? AppServices.alertas;

  late Future<List<AlertaPendiente>> _futuro;
  bool _enviandoTodas = false;

  @override
  void initState() {
    super.initState();
    _futuro = _repo.listarAlertas();
  }

  Future<void> _recargar() async {
    final nuevo = _repo.listarAlertas();
    setState(() {
      _futuro = nuevo;
    });
    await nuevo;
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _enviar(AlertaPendiente alerta) async {
    final resultado = await _servicio.enviar(alerta);
    if (!mounted) return;
    _avisar(
      resultado.exito
          ? 'Alerta enviada: se abrió la app de SMS.'
          : 'No se pudo enviar: ${resultado.detalle ?? 'error desconocido'}',
    );
    await _recargar();
  }

  Future<void> _reintentar(AlertaPendiente alerta) async {
    final resultado = await _servicio.reintentar(alerta);
    if (!mounted) return;
    if (resultado == null) {
      _avisar('Solo se pueden reintentar alertas fallidas.');
    } else {
      _avisar(
        resultado.exito
            ? 'Alerta enviada: se abrió la app de SMS.'
            : 'No se pudo enviar: ${resultado.detalle ?? 'error desconocido'}',
      );
    }
    await _recargar();
  }

  Future<void> _enviarTodas() async {
    final pendientes = await _repo.listarAlertas(
      estado: EstadoAlerta.pendiente,
    );
    if (!mounted) return;
    if (pendientes.isEmpty) {
      _avisar('No hay alertas pendientes para enviar.');
      return;
    }

    setState(() => _enviandoTodas = true);
    var enviadas = 0;
    try {
      for (final alerta in pendientes) {
        final resultado = await _servicio.enviar(alerta);
        if (resultado.exito) enviadas++;
      }
    } finally {
      if (mounted) setState(() => _enviandoTodas = false);
    }

    _avisar('Se enviaron $enviadas de ${pendientes.length} alertas.');
    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas SMS'),
        actions: [
          if (_enviandoTodas)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Enviar todas las pendientes',
              onPressed: _enviarTodas,
              icon: const Icon(Icons.send_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<AlertaPendiente>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return PanelVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo leer la cola de alertas',
                mensaje: '${snapshot.error}',
              );
            }

            final alertas = snapshot.data ?? const <AlertaPendiente>[];
            if (alertas.isEmpty) {
              return const PanelVacio(
                icono: Icons.mark_email_unread_outlined,
                titulo: 'No hay alertas pendientes',
                mensaje:
                    'Cuando registres una evaluación en estado ROJO, '
                    'aparecerá aquí para enviarla al centro de salud.',
              );
            }

            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: esquema.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El envío abre la app de mensajes del sistema; '
                              'usted elige el destinatario. No se envía en '
                              'silencio.',
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
                  const SizedBox(height: 12),
                  for (final alerta in alertas) ...[
                    _TarjetaAlerta(
                      alerta: alerta,
                      onEnviar: () => _enviar(alerta),
                      onReintentar: () => _reintentar(alerta),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TarjetaAlerta extends StatelessWidget {
  const _TarjetaAlerta({
    required this.alerta,
    required this.onEnviar,
    required this.onReintentar,
  });

  final AlertaPendiente alerta;
  final VoidCallback onEnviar;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final coordenadas = alerta.tieneUbicacion
        ? '${alerta.latitud!.toStringAsFixed(5)}, '
              '${alerta.longitud!.toStringAsFixed(5)}'
        : 'sin GPS';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alerta.nombreInfante ?? 'Infante #${alerta.idInfante}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ChipEstado(estado: alerta.estado),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${alerta.rancheria ?? '—'} · '
              '${Fechas.conHora(alerta.fechaCreacion)}',
              style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
            ),
            Text(
              'Severidad: ${alerta.severidad} · Coordenadas: $coordenadas',
              style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
            ),
            if (alerta.estado == EstadoAlerta.enviada &&
                alerta.fechaEnvio != null)
              Text(
                'Enviada: ${Fechas.conHora(alerta.fechaEnvio!)}',
                style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
              ),
            if (alerta.estado != EstadoAlerta.enviada) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: alerta.estado == EstadoAlerta.fallida
                    ? OutlinedButton.icon(
                        onPressed: onReintentar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      )
                    : FilledButton.icon(
                        onPressed: onEnviar,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Enviar'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.estado});

  final EstadoAlerta estado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final (Color fondo, Color texto) = switch (estado) {
      EstadoAlerta.pendiente => (
        esquema.surfaceContainerHighest,
        esquema.onSurfaceVariant,
      ),
      EstadoAlerta.enviada => (Semaforo.verde, Colors.white),
      EstadoAlerta.fallida => (Semaforo.rojo, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: texto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
