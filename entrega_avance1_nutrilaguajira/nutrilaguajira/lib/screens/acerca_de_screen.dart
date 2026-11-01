import 'package:flutter/material.dart';

/// Pantalla "Acerca de" con alcance, limitaciones y aviso académico.
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  static const String version = '1.0.0 (Avance 1)';

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tema = Theme.of(context);

    Widget titulo(String texto) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(texto, style: tema.textTheme.titleLarge),
    );

    Widget parrafo(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto, style: const TextStyle(fontSize: 15, height: 1.45)),
    );

    Widget vineta(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('· ', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, size: 44, color: esquema.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NutriLaGuajira',
                        style: tema.textTheme.headlineMedium,
                      ),
                      Text(
                        'Versión $version',
                        style: TextStyle(color: esquema.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            parrafo(
              'Prototipo académico de tamizaje rápido y semáforo nutricional '
              'offline para el control y la alerta temprana de desnutrición '
              'infantil en comunidades rurales dispersas de La Guajira.',
            ),
            titulo('¿Qué incluye este avance?'),
            vineta('Login local con usuario demo y datos semilla.'),
            vineta('Registro de infantes menores de 5 años y su tutor.'),
            vineta(
              'Evaluación antropométrica: peso, talla, MUAC y edema bilateral.',
            ),
            vineta('Cálculo automático de Z-score Peso/Talla con tabla DEMO.'),
            vineta('Semáforo nutricional: verde, amarillo y rojo.'),
            vineta('Persistencia local en SQLite (funciona sin internet).'),
            vineta('Historial de evaluaciones con el color del semáforo.'),
            titulo('¿Qué NO incluye todavía?'),
            vineta('GPS y reportes georreferenciados (PDF/CSV).'),
            vineta('Envío de alertas por SMS.'),
            vineta('Sincronización con servidor o nube.'),
            vineta('Notificaciones push e iOS.'),
            parrafo(
              'Estos módulos aparecen como "próximo sprint" y no están '
              'operativos en esta entrega.',
            ),
            titulo('Aviso académico y limitaciones'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: esquema.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: esquema.onErrorContainer),
                      const SizedBox(width: 8),
                      Text(
                        'Prototipo académico',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: esquema.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prototipo académico. No sustituye diagnóstico médico. '
                    'Tablas de referencia en modo demostración; la validación '
                    'clínica final usará las tablas OMS completas.',
                    style: TextStyle(
                      color: esquema.onErrorContainer,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            parrafo(
              'La tabla incluida (assets/who_referencia_demo.csv) es una '
              'reducción de demostración con tallas de 45 a 110 cm. La versión '
              'final debe reemplazarla por las tablas OMS completas de '
              'Peso/Talla y aplicar la Resolución 2465 de 2016 y la '
              'Resolución 115 de 2026 (Colombia).',
            ),
            titulo('Privacidad'),
            parrafo(
              'Todos los datos quedan en la base SQLite del dispositivo. La app '
              'no abre conexiones de red ni envía información a terceros. '
              'Cualquier sincronización futura requerirá consentimiento y '
              'medidas de protección de datos personales de menores.',
            ),
            titulo('Tecnologías'),
            vineta('Flutter 3.x / Dart con Material 3.'),
            vineta('SQLite local con sqflite y path.'),
            vineta('intl para el formato de fechas.'),
            titulo('Créditos'),
            parrafo(
              'Escuela de Ingeniería de Sistemas · Proyecto académico · '
              'Metodología Scrum (3 sprints). Este entregable corresponde al '
              'Sprint 1 y parte del Sprint 2.',
            ),
          ],
        ),
      ),
    );
  }
}
