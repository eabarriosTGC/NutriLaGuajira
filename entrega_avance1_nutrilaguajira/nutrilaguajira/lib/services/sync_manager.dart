import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositorio.dart';
import 'conectividad_service.dart';
import 'firestore_strategy.dart';

/// Estado observable de la sincronización, consumido por la pantalla principal.
@immutable
class EstadoSync {
  const EstadoSync({
    this.enLinea = false,
    this.sincronizando = false,
    this.pendientes = 0,
    this.ultimaSincronizacion,
    this.mensaje,
  });

  final bool enLinea;
  final bool sincronizando;

  /// Infantes + evaluaciones con `sincronizado = 0`.
  final int pendientes;
  final DateTime? ultimaSincronizacion;
  final String? mensaje;

  bool get todoSincronizado => pendientes == 0;

  EstadoSync copyWith({
    bool? enLinea,
    bool? sincronizando,
    int? pendientes,
    DateTime? ultimaSincronizacion,
    String? mensaje,
  }) => EstadoSync(
    enLinea: enLinea ?? this.enLinea,
    sincronizando: sincronizando ?? this.sincronizando,
    pendientes: pendientes ?? this.pendientes,
    ultimaSincronizacion: ultimaSincronizacion ?? this.ultimaSincronizacion,
    mensaje: mensaje ?? this.mensaje,
  );
}

/// Orquesta la sincronización offline-first:
/// - escucha los cambios de conectividad y dispara el envío al recuperar red;
/// - expone el número de registros pendientes para el indicador visual;
/// - nunca propaga errores a la UI (se registran y se reintenta después).
class SyncManager {
  SyncManager({
    required FirestoreStrategy estrategia,
    required Repositorio repo,
    Conectividad? conectividad,
  }) : _estrategia = estrategia, // ignore: prefer_initializing_formals
       _repo = repo, // ignore: prefer_initializing_formals
       _conectividad = conectividad ?? ConectividadPlus();

  final FirestoreStrategy _estrategia;
  final Repositorio _repo;
  final Conectividad _conectividad;

  final ValueNotifier<EstadoSync> estado = ValueNotifier(const EstadoSync());

  StreamSubscription<bool>? _suscripcion;
  bool _iniciado = false;
  bool _enCurso = false;

  /// Arranca la escucha de conectividad. Es idempotente y no bloquea la UI.
  Future<void> iniciar() async {
    if (_iniciado) return;
    _iniciado = true;

    await refrescar();

    _suscripcion = _conectividad.cambios().listen(
      (hayRed) {
        estado.value = estado.value.copyWith(enLinea: hayRed);
        // Transición offline -> online: se envía lo acumulado.
        if (hayRed) unawaited(solicitarSincronizacion());
      },
      onError: (Object _) {
        // Sin plugin de conectividad: se mantiene el modo offline.
      },
    );

    final hayRed = await _conectividad.hayRed();
    estado.value = estado.value.copyWith(enLinea: hayRed);
    if (hayRed) {
      unawaited(solicitarSincronizacion());
    }
  }

  Future<void> detener() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
    _iniciado = false;
  }

  /// Recalcula el contador de pendientes desde SQLite.
  Future<void> refrescar() async {
    try {
      final pendientes = await _repo.contarPendientes();
      estado.value = estado.value.copyWith(pendientes: pendientes);
    } catch (error) {
      debugPrint('[NutriLaGuajira] No se pudo contar pendientes: $error');
    }
  }

  /// Lanza una sincronización (sin esperar al llamador si se usa sin `await`).
  /// Devuelve el resultado o `null` si ya había una en curso.
  Future<ResultadoSincronizacion?> solicitarSincronizacion({
    bool forzar = false,
  }) async {
    if (_enCurso) return null;
    _enCurso = true;
    final actual = estado.value;
    estado.value = EstadoSync(
      enLinea: actual.enLinea,
      sincronizando: true,
      pendientes: actual.pendientes,
      ultimaSincronizacion: actual.ultimaSincronizacion,
    );

    try {
      final resultado = await _estrategia.sincronizar(forzar: forzar);
      await refrescar();
      estado.value = estado.value.copyWith(
        sincronizando: false,
        enLinea: resultado.omitido
            ? estado.value.enLinea
            : (resultado.exito ? true : estado.value.enLinea),
        ultimaSincronizacion: resultado.exito
            ? DateTime.now()
            : estado.value.ultimaSincronizacion,
        mensaje: resultado.detalle,
      );
      return resultado;
    } catch (error) {
      // Defensa extra: la estrategia ya captura sus errores.
      debugPrint('[NutriLaGuajira] Sincronización inesperada: $error');
      estado.value = estado.value.copyWith(
        sincronizando: false,
        mensaje: 'No se pudo sincronizar',
      );
      return null;
    } finally {
      _enCurso = false;
    }
  }
}
