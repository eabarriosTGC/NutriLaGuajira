import 'package:flutter/foundation.dart';

import '../data/models/alerta_pendiente.dart';
import '../data/models/evaluacion.dart';
import '../data/models/nino.dart';
import '../data/repositorio.dart';
import 'conectividad_service.dart';
import 'firestore_almacen.dart';
import 'sincronizacion_strategy.dart';

/// Resultado de un intento de sincronización con Firestore.
class ResultadoSincronizacion {
  const ResultadoSincronizacion({
    required this.exito,
    this.omitido = false,
    this.ninos = 0,
    this.evaluaciones = 0,
    this.alertas = 0,
    this.detalle,
  });

  /// No se intentó nada (sin sesión, sin red o ya había un envío en curso).
  const ResultadoSincronizacion.omitido(this.detalle)
    : exito = false,
      omitido = true,
      ninos = 0,
      evaluaciones = 0,
      alertas = 0;

  final bool exito;
  final bool omitido;
  final int ninos;
  final int evaluaciones;
  final int alertas;
  final String? detalle;

  int get total => ninos + evaluaciones;

  @override
  String toString() =>
      'ResultadoSincronizacion(exito=$exito, omitido=$omitido, '
      'ninos=$ninos, evaluaciones=$evaluaciones, alertas=$alertas, '
      'detalle=$detalle)';
}

/// Canal de sincronización con Cloud Firestore.
///
/// Cumple dos papeles:
/// 1. Implementa [SincronizacionStrategy] para poder usarse como alternativa a
///    [SmsIntentStrategy] en [AlertaService] (envía la alerta a la colección
///    global `alertas_criticas`).
/// 2. Ofrece [sincronizar], el envío en lote de los registros locales marcados
///    con `sincronizado = 0` (infantes y evaluaciones).
///
/// **SQLite sigue siendo la fuente de verdad local.** Esta clase nunca calcula
/// Z-scores ni alimenta la UI: solo copia a la nube lo que ya está persistido.
class FirestoreStrategy implements SincronizacionStrategy {
  FirestoreStrategy({
    required Repositorio repo,
    AlmacenNube? almacen,
    Conectividad? conectividad,
    DateTime Function()? ahora,
  }) : _repo = repo, // ignore: prefer_initializing_formals
       _almacen = almacen ?? FirestoreAlmacen(),
       _conectividad = conectividad ?? ConectividadPlus(),
       _ahora = ahora ?? DateTime.now;

  final Repositorio _repo;
  final AlmacenNube _almacen;
  final Conectividad _conectividad;
  final DateTime Function() _ahora;

  bool _enCurso = false;

  bool get _haySesionFirebase => _almacen.disponible && _almacen.uid != null;

  /// Sube los registros pendientes en lotes. Nunca lanza: cualquier error de
  /// red, permisos o configuración se devuelve como resultado fallido y los
  /// datos permanecen en SQLite para el siguiente intento.
  Future<ResultadoSincronizacion> sincronizar({bool forzar = false}) async {
    if (_enCurso) {
      return const ResultadoSincronizacion.omitido(
        'Ya hay una sincronización en curso',
      );
    }
    if (!_haySesionFirebase) {
      return const ResultadoSincronizacion.omitido(
        'Sin sesión de Firebase: los datos quedan en el dispositivo',
      );
    }

    if (!forzar) {
      final hayRed = await _conectividad.hayRed();
      if (!hayRed) {
        return const ResultadoSincronizacion.omitido(
          'Sin conexión: los datos quedan en el dispositivo',
        );
      }
    }

    _enCurso = true;
    try {
      final ninos = await _repo.ninosPendientes();
      final evaluaciones = await _repo.evaluacionesPendientes();

      if (ninos.isEmpty && evaluaciones.isEmpty) {
        return const ResultadoSincronizacion(
          exito: true,
          detalle: 'No hay registros pendientes',
        );
      }

      final uid = _almacen.uid!;
      final documentos = <DocumentoNube>[];
      final alertas = <DocumentoNube>[];

      for (final nino in ninos) {
        documentos.add(documentoNino(uid, nino));
      }
      for (final evaluacion in evaluaciones) {
        documentos.add(documentoEvaluacion(uid, evaluacion));
        // Caso ROJO: copia adicional a la colección global que vigila la
        // brigada central. Se envía en un segundo lote: si falla, los
        // registros quedan pendientes y la alerta se reintenta en el siguiente
        // ciclo (la escritura es idempotente).
        if (esCritica(evaluacion)) {
          alertas.add(documentoAlertaCritica(uid, evaluacion));
        }
      }

      await _almacen.guardarLote(documentos);
      if (alertas.isNotEmpty) {
        await _almacen.guardarLote(alertas);
      }

      // Solo se marca como sincronizado lo que Firestore confirmó.
      await _repo.marcarSincronizados(
        ninos: ninos.map((nino) => nino.id).whereType<int>(),
        evaluaciones: evaluaciones
            .map((evaluacion) => evaluacion.id)
            .whereType<int>(),
        momento: _ahora(),
      );

      return ResultadoSincronizacion(
        exito: true,
        ninos: ninos.length,
        evaluaciones: evaluaciones.length,
        alertas: alertas.length,
        detalle:
            'Sincronizado: ${ninos.length} infantes y '
            '${evaluaciones.length} evaluaciones',
      );
    } catch (error) {
      // Manejo silencioso: la app sigue operando offline y se reintenta al
      // recuperar la conexión o al pulsar el indicador de la nube.
      debugPrint(
        '[NutriLaGuajira] No se pudo sincronizar con Firestore '
        '(los datos siguen en SQLite): $error',
      );
      return ResultadoSincronizacion(
        exito: false,
        detalle: 'No se pudo sincronizar: $error',
      );
    } finally {
      _enCurso = false;
    }
  }

  /// Implementación de [SincronizacionStrategy]: publica una alerta crítica.
  ///
  /// Se conserva [SmsIntentStrategy] como canal principal de la cola de
  /// alertas; esta estrategia puede seleccionarse explícitamente en el futuro.
  @override
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async {
    if (!_haySesionFirebase) {
      return const ResultadoEnvio.fallo(
        'Sin sesión de Firebase: alerta guardada solo en el dispositivo',
      );
    }
    try {
      final uid = _almacen.uid!;
      await _almacen.guardarLote([documentoAlertaDesdePendiente(uid, alerta)]);
      return const ResultadoEnvio.exito('Alerta enviada a Firestore');
    } catch (error) {
      return ResultadoEnvio.fallo('No se pudo enviar la alerta: $error');
    }
  }

  // -------------------------------------------------------- mapeo de datos

  static bool esCritica(Evaluacion evaluacion) =>
      evaluacion.color.toLowerCase() == 'rojo';

  static String idDocumento(String? uuid, int? idLocal, String prefijo) {
    final base = (uuid == null || uuid.trim().isEmpty)
        ? '$prefijo-$idLocal'
        : uuid.trim();
    return base
        .replaceAll(RegExp(r'[/\\]'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '_');
  }

  static DocumentoNube documentoNino(String uid, Nino nino) {
    final id = idDocumento(nino.uuid, nino.id, 'nino');
    return DocumentoNube('promotores/$uid/ninos/$id', {
      'idLocal': nino.id,
      'uuid': id,
      'nombres': nino.nombres,
      'apellidos': nino.apellidos,
      'documento': nino.documento,
      'fechaNacimiento': nino.fechaNacimiento,
      'sexo': nino.sexo,
      'tutor': nino.tutor,
      'comunidad': nino.comunidad,
      'createdAt': nino.createdAt ?? nino.fechaNacimiento,
      'actualizadoEnLocal': (nino.updatedAt ?? DateTime.now())
          .toIso8601String(),
      'promotorUid': uid,
      'origen': 'nutrilaguajira-movil',
    });
  }

  static DocumentoNube documentoEvaluacion(String uid, Evaluacion evaluacion) {
    final id = idDocumento(evaluacion.uuid, evaluacion.id, 'eval');
    final ninoUuid = idDocumento(
      evaluacion.ninoUuid,
      evaluacion.ninoId,
      'nino',
    );
    return DocumentoNube('promotores/$uid/evaluaciones/$id', {
      'idLocal': evaluacion.id,
      'uuid': id,
      'ninoUuid': ninoUuid,
      if (evaluacion.ninoNombre != null) 'ninoNombre': evaluacion.ninoNombre,
      if (evaluacion.comunidad != null) 'comunidad': evaluacion.comunidad,
      'fecha': evaluacion.fecha,
      'edadMeses': evaluacion.edadMeses,
      'pesoKg': evaluacion.pesoKg,
      'tallaCm': evaluacion.tallaCm,
      'muacCm': evaluacion.muacCm,
      'edema': evaluacion.edema,
      'zPesoTalla': evaluacion.zPesoTalla,
      if (evaluacion.zTallaEdad != null) 'zTallaEdad': evaluacion.zTallaEdad,
      if (evaluacion.zPesoEdad != null) 'zPesoEdad': evaluacion.zPesoEdad,
      'clasificacion': evaluacion.clasificacion,
      'color': evaluacion.color,
      'observacion': evaluacion.observacion,
      if (evaluacion.lat != null) 'lat': evaluacion.lat,
      if (evaluacion.lng != null) 'lng': evaluacion.lng,
      'alertaCritica': esCritica(evaluacion),
      'actualizadoEnLocal': (evaluacion.updatedAt ?? DateTime.now())
          .toIso8601String(),
      'promotorUid': uid,
      'origen': 'nutrilaguajira-movil',
    });
  }

  static DocumentoNube documentoAlertaCritica(
    String uid,
    Evaluacion evaluacion,
  ) {
    final idEvaluacion = idDocumento(evaluacion.uuid, evaluacion.id, 'eval');
    final ninoUuid = idDocumento(
      evaluacion.ninoUuid,
      evaluacion.ninoId,
      'nino',
    );
    return DocumentoNube('alertas_criticas/${uid}_$idEvaluacion', {
      'promotorUid': uid,
      'ninoUuid': ninoUuid,
      if (evaluacion.ninoNombre != null) 'ninoNombre': evaluacion.ninoNombre,
      if (evaluacion.comunidad != null) 'comunidad': evaluacion.comunidad,
      'evaluacionUuid': idEvaluacion,
      'severidad': 'ROJO',
      'clasificacion': evaluacion.clasificacion,
      'color': evaluacion.color,
      'fecha': evaluacion.fecha,
      'edadMeses': evaluacion.edadMeses,
      'pesoKg': evaluacion.pesoKg,
      'tallaCm': evaluacion.tallaCm,
      'muacCm': evaluacion.muacCm,
      'edema': evaluacion.edema,
      if (evaluacion.lat != null) 'lat': evaluacion.lat,
      if (evaluacion.lng != null) 'lng': evaluacion.lng,
      'atendida': false,
      'origen': 'nutrilaguajira-movil',
    });
  }

  static DocumentoNube documentoAlertaDesdePendiente(
    String uid,
    AlertaPendiente alerta,
  ) {
    final id = '${uid}_alerta_${alerta.id ?? alerta.idEvaluacion}';
    return DocumentoNube('alertas_criticas/$id', {
      'promotorUid': uid,
      'evaluacionIdLocal': alerta.idEvaluacion,
      'infanteIdLocal': alerta.idInfante,
      'severidad': alerta.severidad,
      'mensaje': alerta.mensaje,
      'fecha': alerta.fechaCreacion,
      if (alerta.latitud != null) 'lat': alerta.latitud,
      if (alerta.longitud != null) 'lng': alerta.longitud,
      'atendida': false,
      'origen': 'alerta_sms',
    });
  }
}
