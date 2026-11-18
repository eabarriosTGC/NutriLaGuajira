import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/alerta_pendiente.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/screens/alertas_screen.dart';
import 'package:nutrilaguajira/services/alerta_service.dart';
import 'package:nutrilaguajira/services/sincronizacion_strategy.dart';
import 'package:nutrilaguajira/theme/tema.dart';

/// Repositorio falso en memoria (sin SQLite).
class _RepoAlertasFalso extends Repositorio {
  _RepoAlertasFalso(List<AlertaPendiente> alertas) : alertas = List.of(alertas);

  final List<AlertaPendiente> alertas;

  @override
  Future<List<AlertaPendiente>> listarAlertas({EstadoAlerta? estado}) async {
    final filtradas = estado == null
        ? alertas
        : alertas.where((a) => a.estado == estado).toList();
    return List.of(filtradas);
  }

  void marcarEstado(int id, EstadoAlerta estado, {DateTime? fechaEnvio}) {
    final indice = alertas.indexWhere((a) => a.id == id);
    if (indice >= 0) {
      alertas[indice] = alertas[indice].copyWith(
        estado: estado,
        fechaEnvio: fechaEnvio,
      );
    }
  }
}

class _EstrategiaNula implements SincronizacionStrategy {
  @override
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async =>
      const ResultadoEnvio.exito();
}

/// Servicio falso: actualiza el repo en memoria y devuelve exito/fallo.
class _AlertaServiceFalso extends AlertaService {
  _AlertaServiceFalso(this.repoFalso, {this.falla = false})
    : super(repo: repoFalso, estrategia: _EstrategiaNula());

  final _RepoAlertasFalso repoFalso;
  bool falla;

  @override
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async {
    final resultado = falla
        ? const ResultadoEnvio.fallo('simulado')
        : const ResultadoEnvio.exito('simulado');
    repoFalso.marcarEstado(
      alerta.id!,
      resultado.exito ? EstadoAlerta.enviada : EstadoAlerta.fallida,
      fechaEnvio: resultado.exito ? DateTime(2026, 11, 17, 20) : null,
    );
    return resultado;
  }

  @override
  Future<ResultadoEnvio?> reintentar(AlertaPendiente alerta) async {
    if (alerta.estado != EstadoAlerta.fallida) return null;
    return enviar(alerta);
  }
}

void main() {
  AlertaPendiente alerta({
    required int id,
    required EstadoAlerta estado,
    String? nombre = 'Andrés David Jusayú González',
    String? rancheria = 'Ranchería Bahía Honda',
  }) => AlertaPendiente(
    id: id,
    idInfante: id,
    idEvaluacion: id,
    severidad: 'ROJO',
    latitud: 11.24712,
    longitud: -72.98765,
    fechaCreacion: DateTime(2026, 11, 17, 19, id),
    estado: estado,
    mensaje: 'mensaje $id',
    fechaEnvio: estado == EstadoAlerta.enviada
        ? DateTime(2026, 11, 17, 20)
        : null,
    nombreInfante: nombre,
    rancheria: rancheria,
  );

  Future<void> montar(
    WidgetTester tester, {
    required _RepoAlertasFalso repo,
    required AlertaService servicio,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light),
        home: AlertasScreen(repo: repo, alertaService: servicio),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el estado vacío', (tester) async {
    final repo = _RepoAlertasFalso(const []);
    await montar(tester, repo: repo, servicio: _AlertaServiceFalso(repo));

    expect(find.text('No hay alertas pendientes'), findsOneWidget);
  });

  testWidgets('una PENDIENTE muestra chip Pendiente y botón Enviar', (
    tester,
  ) async {
    final repo = _RepoAlertasFalso([
      alerta(id: 1, estado: EstadoAlerta.pendiente),
    ]);
    await montar(tester, repo: repo, servicio: _AlertaServiceFalso(repo));

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });

  testWidgets('una ENVIADA muestra chip Enviada y no ofrece Enviar', (
    tester,
  ) async {
    final repo = _RepoAlertasFalso([
      alerta(id: 1, estado: EstadoAlerta.enviada),
    ]);
    await montar(tester, repo: repo, servicio: _AlertaServiceFalso(repo));

    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Enviar'), findsNothing);
  });

  testWidgets('enviar una PENDIENTE con éxito la pasa a Enviada', (
    tester,
  ) async {
    final repo = _RepoAlertasFalso([
      alerta(id: 1, estado: EstadoAlerta.pendiente),
    ]);
    await montar(tester, repo: repo, servicio: _AlertaServiceFalso(repo));

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alerta enviada'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Enviar'), findsNothing);
  });

  testWidgets('enviar una PENDIENTE con fallo la deja Fallida', (tester) async {
    final repo = _RepoAlertasFalso([
      alerta(id: 1, estado: EstadoAlerta.pendiente),
    ]);
    await montar(
      tester,
      repo: repo,
      servicio: _AlertaServiceFalso(repo, falla: true),
    );

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo enviar'), findsOneWidget);
    expect(find.text('Fallida'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('reintentar una FALLIDA con éxito la pasa a Enviada', (
    tester,
  ) async {
    final repo = _RepoAlertasFalso([
      alerta(id: 1, estado: EstadoAlerta.fallida),
    ]);
    await montar(tester, repo: repo, servicio: _AlertaServiceFalso(repo));

    expect(find.text('Fallida'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alerta enviada'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);
  });
}
