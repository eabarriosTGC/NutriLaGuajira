import '../data/models/alerta_pendiente.dart';

/// Resultado de intentar entregar una alerta por un canal.
class ResultadoEnvio {
  const ResultadoEnvio.exito([this.detalle]) : exito = true;
  const ResultadoEnvio.fallo(this.detalle) : exito = false;

  final bool exito;
  final String? detalle;
}

/// Canal de entrega de una alerta.
///
/// Solo se define la interfaz: hoy la implementa [SmsIntentStrategy] (intent
/// de SMS). La sincronización web real queda para Sprint 4.
abstract class SincronizacionStrategy {
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta);
}

// TODO(sprint4): ApiStrategy implements SincronizacionStrategy para enviar
// las alertas a una API cuando exista backend y conectividad.
