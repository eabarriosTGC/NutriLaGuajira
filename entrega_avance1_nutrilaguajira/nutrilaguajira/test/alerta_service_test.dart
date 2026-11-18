import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/db_nutrilaguajira.dart';
import 'package:nutrilaguajira/data/models/alerta_pendiente.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/data/models/nino.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/services/alerta_service.dart';
import 'package:nutrilaguajira/services/referencias_loader.dart';
import 'package:nutrilaguajira/services/sincronizacion_strategy.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Estrategia falsa que devuelve un resultado configurable.
class _EstrategiaFalsa implements SincronizacionStrategy {
  _EstrategiaFalsa(this.resultado);

  ResultadoEnvio resultado;

  @override
  Future<ResultadoEnvio> enviar(AlertaPendiente alerta) async => resultado;
}

/// Pruebas de encolado/envío de alertas sobre SQLite real (RF-10).
void main() {
  late Directory temporal;
  late Repositorio repo;
  late Nino nino;
  late int idEvaluacion;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('alerta_test_');
    final referencias = ReferenciasLoader.desdeCsv(
      File('assets/who_referencia_demo.csv').readAsStringSync(),
    );
    DbNutriLaGuajira.instance.configurarParaPruebas(
      ruta: '${temporal.path}/nutrilaguajira.db',
      referencias: referencias,
      omitirSemilla: true,
    );
    repo = Repositorio();
    await repo.contarNinos(); // crea el esquema (v3)

    nino = Nino(
      nombres: 'Andrés David',
      apellidos: 'Jusayú González',
      documento: 'TEST-1',
      fechaNacimiento: DateTime(2024, 9, 15),
      sexo: 'M',
      tutor: 'Tutor de Prueba',
      comunidad: 'Ranchería Bahía Honda',
    );
    final idNino = await repo.insertarNino(nino);
    nino = nino.copyWith(id: idNino);

    idEvaluacion = await repo.insertarEvaluacion(
      Evaluacion(
        ninoId: idNino,
        fecha: DateTime(2026, 11, 17, 19, 0),
        edadMeses: 26,
        pesoKg: 8.8,
        tallaCm: 85,
        muacCm: 12,
        edema: false,
        zPesoTalla: -2.27,
        clasificacion: 'ROJO',
        color: 'rojo',
        observacion: 'Evaluación de prueba.',
        lat: 11.24712,
        lng: -72.98765,
      ),
    );
  });

  tearDown(() async {
    await DbNutriLaGuajira.instance.cerrar();
    if (temporal.existsSync()) {
      await temporal.delete(recursive: true);
    }
  });

  AlertaService servicio(SincronizacionStrategy estrategia) => AlertaService(
    repo: repo,
    estrategia: estrategia,
    ahora: () => DateTime(2026, 11, 17, 20, 0),
  );

  Future<AlertaPendiente?> encolar(
    AlertaService service, {
    String clasificacion = 'ROJO',
    double? lat = 11.24712,
    double? lng = -72.98765,
  }) => service.encolarDesdeEvaluacion(
    idInfante: nino.id!,
    idEvaluacion: idEvaluacion,
    clasificacionNutricional: clasificacion,
    nombresCompletos: nino.nombreCompleto,
    rancheria: nino.comunidad,
    fechaEvaluacion: DateTime(2026, 11, 17, 19, 0),
    latitud: lat,
    longitud: lng,
  );

  test(
    'encola una alerta PENDIENTE al registrar una evaluación ROJA',
    () async {
      final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
      final alerta = await encolar(service);

      expect(alerta, isNotNull);
      final alertas = await repo.listarAlertas();
      expect(alertas, hasLength(1));
      expect(alertas.single.estado, EstadoAlerta.pendiente);
      expect(alertas.single.severidad, 'ROJO');
      expect(alertas.single.mensaje, contains('Andrés David Jusayú González'));
      expect(alertas.single.mensaje, contains('Ranchería Bahía Honda'));
      expect(alertas.single.mensaje, contains('11.24712, -72.98765'));
      expect(alertas.single.nombreInfante, contains('Andrés David'));
    },
  );

  test('no encola cuando la clasificación es VERDE', () async {
    final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
    final alerta = await encolar(service, clasificacion: 'VERDE');

    expect(alerta, isNull);
    expect(await repo.listarAlertas(), isEmpty);
  });

  test('no encola cuando la clasificación es AMARILLO', () async {
    final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
    final alerta = await encolar(service, clasificacion: 'AMARILLO');

    expect(alerta, isNull);
    expect(await repo.listarAlertas(), isEmpty);
  });

  test('ROJO sin GPS encola y el mensaje dice "sin GPS"', () async {
    final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
    final alerta = await encolar(service, lat: null, lng: null);

    expect(alerta, isNotNull);
    final alertas = await repo.listarAlertas();
    expect(alertas.single.mensaje, contains('sin GPS'));
    expect(alertas.single.tieneUbicacion, isFalse);
  });

  test('enviar con éxito marca ENVIADA y guarda fecha_envio', () async {
    final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
    final alerta = await encolar(service);

    final resultado = await service.enviar(alerta!);
    expect(resultado.exito, isTrue);

    final actualizada = (await repo.listarAlertas()).single;
    expect(actualizada.estado, EstadoAlerta.enviada);
    expect(actualizada.fechaEnvio, isNotNull);
  });

  test('enviar con fallo marca FALLIDA', () async {
    final service = servicio(
      _EstrategiaFalsa(const ResultadoEnvio.fallo('sin app')),
    );
    final alerta = await encolar(service);

    final resultado = await service.enviar(alerta!);
    expect(resultado.exito, isFalse);

    final actualizada = (await repo.listarAlertas()).single;
    expect(actualizada.estado, EstadoAlerta.fallida);
    expect(actualizada.fechaEnvio, isNull);
  });

  test('reintentar una FALLIDA con éxito la marca ENVIADA', () async {
    final estrategia = _EstrategiaFalsa(const ResultadoEnvio.fallo('sin app'));
    final service = servicio(estrategia);
    final alerta = await encolar(service);
    await service.enviar(alerta!);

    final fallida = (await repo.listarAlertas()).single;
    expect(fallida.estado, EstadoAlerta.fallida);

    estrategia.resultado = const ResultadoEnvio.exito();
    final resultado = await service.reintentar(fallida);
    expect(resultado?.exito, isTrue);

    final actualizada = (await repo.listarAlertas()).single;
    expect(actualizada.estado, EstadoAlerta.enviada);
  });

  test('reintentar una PENDIENTE no hace nada', () async {
    final service = servicio(_EstrategiaFalsa(const ResultadoEnvio.exito()));
    final alerta = await encolar(service);

    final resultado = await service.reintentar(alerta!);
    expect(resultado, isNull);

    final actualizada = (await repo.listarAlertas()).single;
    expect(actualizada.estado, EstadoAlerta.pendiente);
  });
}
