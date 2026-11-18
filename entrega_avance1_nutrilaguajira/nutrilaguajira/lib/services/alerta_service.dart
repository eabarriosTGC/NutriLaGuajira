import '../data/models/alerta_pendiente.dart';
import '../data/repositorio.dart';
import 'fechas.dart';
import 'sincronizacion_strategy.dart';

/// Orquesta el ciclo de vida de las alertas de desnutrición aguda (RF-10):
/// encolado local al registrar una evaluación ROJA, envío por un
/// [SincronizacionStrategy] y actualización del estado.
class AlertaService {
  AlertaService({
    required Repositorio repo,
    required SincronizacionStrategy estrategia,
    DateTime Function()? ahora,
  }) : _repo = repo, // ignore: prefer_initializing_formals
       _estrategia = estrategia, // ignore: prefer_initializing_formals
       _ahora = ahora ?? DateTime.now;

  final Repositorio _repo;
  final SincronizacionStrategy _estrategia;
  final DateTime Function() _ahora;

  /// Crea y guarda una alerta **solo si** la clasificación es ROJO.
  ///
  /// Para VERDE/AMARILLO devuelve `null` sin insertar nada (no es un error).
  Future<AlertaPendiente?> encolarDesdeEvaluacion({
    required int idInfante,
    required int idEvaluacion,
    required String clasificacionNutricional,
    required String nombresCompletos,
    required String rancheria,
    required DateTime fechaEvaluacion,
    double? latitud,
    double? longitud,
  }) async {
    if (!esRojo(clasificacionNutricional)) return null;

    final alerta = AlertaPendiente(
      idInfante: idInfante,
      idEvaluacion: idEvaluacion,
      severidad: clasificacionNutricional.trim().toUpperCase(),
      latitud: latitud,
      longitud: longitud,
      fechaCreacion: _ahora(),
      estado: EstadoAlerta.pendiente,
      mensaje: construirMensaje(
        nombresCompletos: nombresCompletos,
        rancheria: rancheria,
        fechaEvaluacion: fechaEvaluacion,
        clasificacionNutricional: clasificacionNutricional,
        latitud: latitud,
        longitud: longitud,
      ),
    );

    final id = await _repo.insertarAlerta(alerta);
    return alerta.copyWith(id: id);
  }

  /// Intenta enviar la alerta y actualiza su estado en la base.
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async {
    final resultado = await _estrategia.enviar(alerta);
    final id = alerta.id;
    if (id != null) {
      if (resultado.exito) {
        await _repo.actualizarEstadoAlerta(
          id,
          EstadoAlerta.enviada,
          fechaEnvio: _ahora().toIso8601String(),
        );
      } else {
        await _repo.actualizarEstadoAlerta(id, EstadoAlerta.fallida);
      }
    }
    return resultado;
  }

  /// Reintenta únicamente alertas FALLIDAS. Para otro estado no hace nada
  /// (devuelve `null`), porque la UI solo ofrece "Reintentar" en FALLIDA.
  Future<ResultadoEnvio?> reintentar(AlertaPendiente alerta) async {
    final id = alerta.id;
    if (alerta.estado != EstadoAlerta.fallida || id == null) return null;
    await _repo.actualizarEstadoAlerta(id, EstadoAlerta.pendiente);
    return enviar(alerta);
  }

  /// Mismo criterio que usa la app: ROJO es la etiqueta persistida 'ROJO'
  /// (clave 'rojo'), la única clasificación de desnutrición aguda.
  static bool esRojo(String clasificacionNutricional) =>
      clasificacionNutricional.trim().toUpperCase() == 'ROJO';

  /// Cuerpo del SMS pre-armado. Se mantiene en ASCII para evitar problemas de
  /// codificación en algunas apps de mensajería.
  static String construirMensaje({
    required String nombresCompletos,
    required String rancheria,
    required DateTime fechaEvaluacion,
    required String clasificacionNutricional,
    double? latitud,
    double? longitud,
  }) {
    final coordenadas = (latitud != null && longitud != null)
        ? '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}'
        : 'sin GPS';
    return [
      'NutriLaGuajira - ALERTA DESNUTRICION AGUDA',
      'Infante: $nombresCompletos',
      'Rancheria: $rancheria',
      'Fecha: ${Fechas.corta(fechaEvaluacion)}',
      'Clasificacion: $clasificacionNutricional',
      'Coordenadas: $coordenadas',
      'Accion: enviar brigada nutricional.',
    ].join('\n');
  }
}
