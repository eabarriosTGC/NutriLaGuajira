import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/db_nutrilaguajira.dart';
import 'package:nutrilaguajira/data/models/alerta_pendiente.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/data/models/nino.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/services/conectividad_service.dart';
import 'package:nutrilaguajira/services/firestore_almacen.dart';
import 'package:nutrilaguajira/services/firestore_strategy.dart';
import 'package:nutrilaguajira/services/referencias_edad_loader.dart';
import 'package:nutrilaguajira/services/referencias_loader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Nube falsa: captura los documentos y permite simular fallos de red.
class _AlmacenFalso implements AlmacenNube {
  _AlmacenFalso({this.haySesion = true});

  bool haySesion;
  bool fallar = false;
  final List<DocumentoNube> enviados = <DocumentoNube>[];

  @override
  bool get disponible => haySesion;

  @override
  String? get uid => haySesion ? 'uid-prueba' : null;

  @override
  Future<void> guardarLote(List<DocumentoNube> documentos) async {
    if (fallar) throw StateError('sin red');
    enviados.addAll(documentos);
  }
}

class _RedFalsa implements Conectividad {
  _RedFalsa(this.hay);

  bool hay;

  @override
  Future<bool> hayRed() async => hay;

  @override
  Stream<bool> cambios() => const Stream<bool>.empty();
}

/// Pruebas del canal SQLite -> Firestore con un almacén en memoria.
void main() {
  late Directory temporal;
  late Repositorio repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('firestore_sync_test_');
    DbNutriLaGuajira.instance.configurarParaPruebas(
      ruta: '${temporal.path}/nutrilaguajira.db',
      referencias: ReferenciasLoader.desdeCsv(
        File('assets/who_referencia_demo.csv').readAsStringSync(),
      ),
      referenciasEdad: ReferenciasEdadLoader.desdeCsv(
        File('assets/who_edad_demo.csv').readAsStringSync(),
      ),
      omitirSemilla: true,
    );
    repo = Repositorio();
    await repo.contarNinos();
  });

  tearDown(() async {
    await DbNutriLaGuajira.instance.cerrar();
    if (temporal.existsSync()) {
      await temporal.delete(recursive: true);
    }
  });

  Future<(Nino, int, int)> sembrar() async {
    final idNino = await repo.insertarNino(
      Nino(
        nombres: 'Andrés David',
        apellidos: 'Jusayú González',
        documento: 'SYNC-1',
        fechaNacimiento: DateTime(2024, 9, 15),
        sexo: 'M',
        tutor: 'Tutor de Prueba',
        comunidad: 'Ranchería Bahía Honda',
      ),
    );
    final nino = (await repo.ninoPorId(idNino))!;

    final idAmarillo = await repo.insertarEvaluacion(
      Evaluacion(
        ninoId: idNino,
        fecha: DateTime(2026, 11, 17, 10),
        edadMeses: 26,
        pesoKg: 10.5,
        tallaCm: 86,
        muacCm: 13,
        edema: false,
        zPesoTalla: -1.2,
        clasificacion: 'AMARILLO',
        color: 'amarillo',
        observacion: 'Sin criterios de gravedad.',
      ),
    );
    final idRojo = await repo.insertarEvaluacion(
      Evaluacion(
        ninoId: idNino,
        fecha: DateTime(2026, 11, 18, 9),
        edadMeses: 26,
        pesoKg: 8.8,
        tallaCm: 85,
        muacCm: 12,
        edema: true,
        zPesoTalla: -2.27,
        clasificacion: 'ROJO',
        color: 'rojo',
        observacion: 'Edema bilateral.',
        lat: 11.24712,
        lng: -72.98765,
      ),
    );
    return (nino, idAmarillo, idRojo);
  }

  FirestoreStrategy estrategia(_AlmacenFalso almacen, {bool hayRed = true}) =>
      FirestoreStrategy(
        repo: repo,
        almacen: almacen,
        conectividad: _RedFalsa(hayRed),
        ahora: () => DateTime(2026, 11, 23, 12),
      );

  test('al guardar, los registros nacen pendientes de sincronizar', () async {
    await sembrar();
    expect(await repo.contarPendientes(), 3); // 1 infante + 2 evaluaciones
    expect(await repo.ninosPendientes(), hasLength(1));
    expect(await repo.evaluacionesPendientes(), hasLength(2));
  });

  test('sin red no intenta subir y conserva los pendientes', () async {
    await sembrar();
    final almacen = _AlmacenFalso();
    final resultado = await estrategia(almacen, hayRed: false).sincronizar();

    expect(resultado.omitido, isTrue);
    expect(almacen.enviados, isEmpty);
    expect(await repo.contarPendientes(), 3);
  });

  test('sin sesión de Firebase no escribe en la nube', () async {
    await sembrar();
    final almacen = _AlmacenFalso(haySesion: false);
    final resultado = await estrategia(almacen).sincronizar();

    expect(resultado.omitido, isTrue);
    expect(almacen.enviados, isEmpty);
    expect(await repo.contarPendientes(), 3);
  });

  test('sube infantes y evaluaciones y los marca como sincronizados', () async {
    final (nino, _, _) = await sembrar();
    final pendientesAntes = await repo.evaluacionesPendientes();
    final almacen = _AlmacenFalso();

    final resultado = await estrategia(almacen).sincronizar();

    expect(resultado.exito, isTrue);
    expect(resultado.ninos, 1);
    expect(resultado.evaluaciones, 2);
    expect(resultado.alertas, 1);
    expect(await repo.contarPendientes(), 0);
    expect(await repo.ninosPendientes(), isEmpty);

    final rutas = almacen.enviados.map((doc) => doc.ruta).toList();
    expect(rutas, contains('promotores/uid-prueba/ninos/${nino.uuid}'));
    for (final evaluacion in pendientesAntes) {
      expect(
        rutas,
        contains('promotores/uid-prueba/evaluaciones/${evaluacion.uuid}'),
      );
    }

    final historial = await repo.historial();
    expect(historial.every((evaluacion) => evaluacion.sincronizado), isTrue);
    expect((await repo.ninoPorId(nino.id!))!.sincronizado, isTrue);
  });

  test('una evaluación ROJO genera una alerta crítica global', () async {
    await sembrar();
    final almacen = _AlmacenFalso();

    await estrategia(almacen).sincronizar();

    final alertas = almacen.enviados
        .where((doc) => doc.ruta.startsWith('alertas_criticas/'))
        .toList();
    expect(alertas, hasLength(1));
    expect(alertas.single.ruta, startsWith('alertas_criticas/uid-prueba_'));
    expect(alertas.single.datos['severidad'], 'ROJO');
    expect(alertas.single.datos['promotorUid'], 'uid-prueba');
    expect(alertas.single.datos['ninoNombre'], 'Andrés David Jusayú González');
    expect(alertas.single.datos['atendida'], isFalse);
    expect(alertas.single.datos['lat'], closeTo(11.24712, 1e-9));
  });

  test('si Firestore falla, los datos siguen pendientes en SQLite', () async {
    await sembrar();
    final almacen = _AlmacenFalso()..fallar = true;

    final resultado = await estrategia(almacen).sincronizar();

    expect(resultado.exito, isFalse);
    expect(await repo.contarPendientes(), 3);
    expect(
      (await repo.historial()).every((evaluacion) => !evaluacion.sincronizado),
      isTrue,
    );
  });

  test('un segundo intento sin cambios no reenvía nada', () async {
    await sembrar();
    final almacen = _AlmacenFalso();

    await estrategia(almacen).sincronizar();
    final enviadosPrimeraVez = almacen.enviados.length;
    final segundo = await estrategia(almacen).sincronizar();

    expect(segundo.exito, isTrue);
    expect(segundo.total, 0);
    expect(almacen.enviados.length, enviadosPrimeraVez);
  });

  test('enviar una AlertaPendiente publica en alertas_criticas', () async {
    await sembrar();
    final almacen = _AlmacenFalso();
    final alerta = AlertaPendiente(
      id: 7,
      idInfante: 1,
      idEvaluacion: 2,
      severidad: 'ROJO',
      fechaCreacion: DateTime(2026, 11, 20, 9),
      mensaje: 'NutriLaGuajira - ALERTA DESNUTRICION AGUDA',
      latitud: 11.24712,
      longitud: -72.98765,
    );

    final resultado = await estrategia(almacen).enviar(alerta);

    expect(resultado.exito, isTrue);
    expect(almacen.enviados, hasLength(1));
    expect(
      almacen.enviados.single.ruta,
      'alertas_criticas/uid-prueba_alerta_7',
    );
    expect(almacen.enviados.single.datos['severidad'], 'ROJO');
  });

  test(
    'el documento del infante incluye su comunidad y UID del promotor',
    () async {
      await sembrar();
      final almacen = _AlmacenFalso();
      await estrategia(almacen).sincronizar();

      final documentoNino = almacen.enviados.firstWhere(
        (doc) => doc.ruta.contains('/ninos/'),
      );
      expect(documentoNino.datos['comunidad'], 'Ranchería Bahía Honda');
      expect(documentoNino.datos['promotorUid'], 'uid-prueba');
      expect(documentoNino.datos['documento'], 'SYNC-1');
    },
  );
}
