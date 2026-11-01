import 'package:flutter/material.dart';

import '../data/models/evaluacion.dart';
import '../services/fechas.dart';
import '../services/nutricion_service.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';
import 'historial_screen.dart';
import 'seleccion_nino_screen.dart';

/// Pantalla de resultado con el semáforo nutricional.
class ResultadoScreen extends StatelessWidget {
  const ResultadoScreen({
    super.key,
    required this.evaluacion,
    required this.resultado,
  });

  final Evaluacion evaluacion;
  final ResultadoNutricional resultado;

  ClasificacionNutricional get _clasificacion => resultado.clasificacion;

  void _nuevoTamizaje(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SeleccionNinoScreen()),
      (route) => route.isFirst,
    );
  }

  void _verHistorial(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HistorialScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = Semaforo.fondo(_clasificacion);
    final colorTexto = Semaforo.texto(_clasificacion);

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del tamizaje')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ---------------------------------------------------- semáforo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Semaforo.icono(_clasificacion),
                    size: 64,
                    color: colorTexto,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _clasificacion.etiqueta,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descripcionClasificacion(_clasificacion),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.check_circle, color: Semaforo.verde, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guardado localmente · ${Fechas.conHora(evaluacion.fecha)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // ------------------------------------------------------ z-score
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Z-score Peso/Talla',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultado.zTexto,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      etiqueta: 'Edad',
                      valor: '${evaluacion.edadMeses} meses',
                      icono: Icons.child_care,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // -------------------------------------------------- recomendación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                      resultado.recomendacion,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ---------------------------------------------------- criterios
            Card(
              child: ExpansionTile(
                leading: Icon(Icons.rule_outlined, color: esquema.primary),
                title: const Text(
                  'Cómo se calculó',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final criterio in resultado.criterios)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '· $criterio',
                        style: const TextStyle(height: 1.35),
                      ),
                    ),
                  const Divider(),
                  Text(
                    'Tabla de referencia en modo DEMOSTRACIÓN: no es validación '
                    'clínica final.',
                    style: TextStyle(
                      fontSize: 12,
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _nuevoTamizaje(context),
              icon: const Icon(Icons.add_chart),
              label: const Text('Nuevo tamizaje'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _verHistorial(context),
              icon: const Icon(Icons.history),
              label: const Text('Ver historial'),
            ),
          ],
        ),
      ),
    );
  }
}
