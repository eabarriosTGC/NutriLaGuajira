import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/models/evaluacion.dart';
import '../services/fechas.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';
import 'detalle_evaluacion_screen.dart';
import 'seleccion_nino_screen.dart';

/// Historial de tamizajes, del más reciente al más antiguo.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<Evaluacion>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = AppServices.repo.historial();
  }

  Future<void> _recargar() async {
    final nuevo = AppServices.repo.historial();
    setState(() => _futuro = nuevo);
    await nuevo;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Evaluacion>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return PanelVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo leer el historial',
                mensaje: '${snapshot.error}',
              );
            }

            final evaluaciones = snapshot.data ?? const <Evaluacion>[];
            if (evaluaciones.isEmpty) {
              return PanelVacio(
                icono: Icons.assignment_outlined,
                titulo: 'Sin tamizajes registrados',
                mensaje:
                    'Cuando guarde una evaluación aparecerá aquí con el color '
                    'del semáforo.',
                accion: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SeleccionNinoScreen(),
                      ),
                    );
                    await _recargar();
                  },
                  icon: const Icon(Icons.add_chart),
                  label: const Text('Nuevo tamizaje'),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _recargar,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: evaluaciones.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final evaluacion = evaluaciones[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DetalleEvaluacionScreen(evaluacion: evaluacion),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Semaforo.fondoDesdeClave(
                                  evaluacion.color,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    evaluacion.ninoNombre ?? 'Infante',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    Fechas.conHora(evaluacion.fecha),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: esquema.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    evaluacion.comunidad ?? '—',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: esquema.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ChipSemaforo(
                                  claveColor: evaluacion.color,
                                  etiqueta: evaluacion.clasificacion,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Z ${evaluacion.zPesoTalla.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
