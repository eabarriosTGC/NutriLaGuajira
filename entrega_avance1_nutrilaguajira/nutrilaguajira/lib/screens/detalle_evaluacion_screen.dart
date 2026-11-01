import 'package:flutter/material.dart';

import '../data/models/evaluacion.dart';
import '../services/fechas.dart';
import '../services/nutricion_service.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';

/// Detalle de una evaluación guardada (abierta desde el historial).
class DetalleEvaluacionScreen extends StatelessWidget {
  const DetalleEvaluacionScreen({super.key, required this.evaluacion});

  final Evaluacion evaluacion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final clasificacion = ClasificacionNutricional.desdeClave(evaluacion.color);
    final recomendacion = NutricionService.recomendacionPara(
      clasificacion,
      edema: evaluacion.edema,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del tamizaje')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Semaforo.fondoDesdeClave(evaluacion.color),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Semaforo.iconoDesdeClave(evaluacion.color),
                    size: 40,
                    color: Semaforo.textoDesdeClave(evaluacion.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evaluacion.clasificacion,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Semaforo.textoDesdeClave(evaluacion.color),
                          ),
                        ),
                        Text(
                          'Z Peso/Talla ${evaluacion.zPesoTalla.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Semaforo.textoDesdeClave(evaluacion.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluacion.ninoNombre ?? 'Infante',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    FilaDato(
                      etiqueta: 'Fecha y hora',
                      valor: Fechas.conHora(evaluacion.fecha),
                      icono: Icons.schedule,
                    ),
                    FilaDato(
                      etiqueta: 'Edad',
                      valor: '${evaluacion.edadMeses} meses',
                      icono: Icons.child_care,
                    ),
                    FilaDato(
                      etiqueta: 'Peso',
                      valor: '${evaluacion.pesoKg.toStringAsFixed(2)} kg',
                      icono: Icons.monitor_weight_outlined,
                    ),
                    FilaDato(
                      etiqueta: 'Talla',
                      valor: '${evaluacion.tallaCm.toStringAsFixed(1)} cm',
                      icono: Icons.straighten,
                    ),
                    FilaDato(
                      etiqueta: 'MUAC',
                      valor: '${evaluacion.muacCm.toStringAsFixed(1)} cm',
                      icono: Icons.accessibility_new,
                    ),
                    FilaDato(
                      etiqueta: 'Edema bilateral',
                      valor: evaluacion.edema ? 'Sí' : 'No',
                      icono: Icons.water_drop_outlined,
                    ),
                    FilaDato(
                      etiqueta: 'Comunidad',
                      valor: evaluacion.comunidad ?? '—',
                      icono: Icons.location_on_outlined,
                    ),
                    FilaDato(
                      etiqueta: 'Sincronizado',
                      valor: evaluacion.sincronizado
                          ? 'Sí'
                          : 'No (pendiente: próximo sprint)',
                      icono: Icons.cloud_off,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rule_outlined, color: esquema.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Criterios aplicados',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final criterio in evaluacion.observacion.split(' | '))
                      if (criterio.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '· $criterio',
                            style: const TextStyle(height: 1.35),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          color: esquema.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recomendación',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recomendacion,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al historial'),
            ),
          ],
        ),
      ),
    );
  }
}
