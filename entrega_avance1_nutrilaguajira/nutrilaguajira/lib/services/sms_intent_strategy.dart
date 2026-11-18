import 'package:url_launcher/url_launcher.dart';

import '../data/models/alerta_pendiente.dart';
import 'sincronizacion_strategy.dart';

/// Firma del lanzador de intents, inyectable para pruebas.
typedef LanzadorSms = Future<bool> Function(Uri uri);

/// Envía una alerta abriendo la app de SMS del sistema con el mensaje
/// pre-armado, **sin destinatario** (opción A: `sms:?body=...`).
///
/// No usa el permiso `SEND_SMS` (restringido por Google Play): el brigadista
/// elige el destinatario en su app de mensajes. Se fuerza
/// [LaunchMode.externalApplication] para no quedarse dentro de la app.
class SmsIntentStrategy implements SincronizacionStrategy {
  SmsIntentStrategy({LanzadorSms? lanzador}) : _lanzador = lanzador ?? _lanzar;

  final LanzadorSms _lanzador;

  static Future<bool> _lanzar(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async {
    final uri = Uri(scheme: 'sms', queryParameters: {'body': alerta.mensaje});
    try {
      final abierto = await _lanzador(uri);
      return abierto
          ? const ResultadoEnvio.exito('Se abrió la app de SMS')
          : const ResultadoEnvio.fallo('No se pudo abrir la app de SMS');
    } catch (error) {
      return ResultadoEnvio.fallo('$error');
    }
  }
}
