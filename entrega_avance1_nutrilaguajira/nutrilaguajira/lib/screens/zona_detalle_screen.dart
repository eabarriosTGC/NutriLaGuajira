import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/evaluacion_reporte.dart';
import '../data/repositorio.dart';
import '../services/fechas.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';

/// Detalle de los casos ROJO de una ranchería, con sus coordenadas.
class ZonaDetalleScreen extends StatefulWidget {
  const ZonaDetalleScreen({
    super.key,
    required this.rancheria,
    required this.repo,
    this.desde,
    this.alCopiar,
  });

  final String rancheria;
  final Repositorio repo;
  final DateTime? desde;

  /// Inyectable para pruebas (evita el portapapeles real).
  final Future<void> Function(String texto)? alCopiar;

  @override
  State<ZonaDetalleScreen> createState() => _ZonaDetalleScreenState();
}

class _ZonaDetalleScreenState extends State<ZonaDetalleScreen> {
  late Future<List<EvaluacionReporte>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<EvaluacionReporte>> _cargar() async {
    final todas = await widget.repo.evaluacionesParaReporte();
    final criticos =
        todas
            .where(
              (e) =>
                  e.rancheria == widget.rancheria &&
                  e.esDesnutricionAguda &&
                  (widget.desde == null ||
                      !e.fechaEvaluacion.isBefore(widget.desde!)),
            )
            .toList()
          ..sort((a, b) => b.fechaEvaluacion.compareTo(a.fechaEvaluacion));
    return criticos;
  }

  Future<void> _copiar(EvaluacionReporte evaluacion) async {
    final texto =
        '${evaluacion.latitud!.toStringAsFixed(5)}, '
        '${evaluacion.longitud!.toStringAsFixed(5)}';
    final callback = widget.alCopiar;
    if (callback != null) {
      await callback(texto);
    } else {
      await Clipboard.setData(ClipboardData(text: texto));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordenadas copiadas'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.rancheria)),
      body: SafeArea(
        child: FutureBuilder<List<EvaluacionReporte>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return PanelVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo leer el detalle',
                mensaje: '${snapshot.error}',
              );
            }

            final criticos = snapshot.data ?? const <EvaluacionReporte>[];
            if (criticos.isEmpty) {
              return const PanelVacio(
                icono: Icons.check_circle_outline,
                titulo: 'Sin casos críticos',
                mensaje:
                    'No hay casos ROJO en esta ranchería con el filtro '
                    'seleccionado.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: criticos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final evaluacion = criticos[index];
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
                                evaluacion.nombreCompleto,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(Icons.warning_amber, color: Semaforo.rojo),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Fechas.conHora(evaluacion.fechaEvaluacion)} · '
                          'Z P/T ${evaluacion.zPesoTalla.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: esquema.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (evaluacion.tieneUbicacion)
                          InkWell(
                            onTap: () => _copiar(evaluacion),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: esquema.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${evaluacion.latitud!.toStringAsFixed(5)}, '
                                    '${evaluacion.longitud!.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            'Coordenadas: sin GPS',
                            style: TextStyle(
                              fontSize: 13,
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
