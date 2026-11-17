import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/db_nutrilaguajira.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/services/referencias_loader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pruebas de persistencia real sobre SQLite (motor FFI en escritorio).
///
/// Cubren la semilla, el login local y el requisito de aceptación
/// "los datos persisten tras cerrar y abrir la app".
void main() {
  late Directory temporal;
  late Repositorio repo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> abrirBase({bool omitirSemilla = false}) async {
    final referencias = ReferenciasLoader.desdeCsv(
      File('assets/who_referencia_demo.csv').readAsStringSync(),
    );
    DbNutriLaGuajira.instance.configurarParaPruebas(
      ruta: '${temporal.path}/nutrilaguajira.db',
      referencias: referencias,
      omitirSemilla: omitirSemilla,
    );
    repo = Repositorio();
    await repo.contarNinos(); // fuerza la creación del esquema
  }

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('nutri_db_test_');
    await abrirBase();
  });

  tearDown(() async {
    await DbNutriLaGuajira.instance.cerrar();
    if (temporal.existsSync()) {
      await temporal.delete(recursive: true);
    }
  });

  test(
    'la semilla crea 3 infantes y 4 evaluaciones con verde/amarillo/rojo',
    () async {
      expect(await repo.contarNinos(), 3);

      final historial = await repo.historial();
      expect(historial.length, 4);

      final colores = historial.map((e) => e.color).toSet();
      expect(colores, containsAll(<String>['verde', 'amarillo', 'rojo']));

      // El caso de edema debe quedar ROJO aunque su Z sea normal.
      final conEdema = historial.where((e) => e.edema).toList();
      expect(conEdema, hasLength(1));
      expect(conEdema.single.color, 'rojo');
      expect(conEdema.single.zPesoTalla, greaterThan(-1));
    },
  );

  test('la tabla de referencia se carga desde el CSV a SQLite', () async {
    final referencias = await repo.referencias();
    expect(referencias.length, 28);
    expect(referencias.where((r) => r.sexo == 'M').length, 14);
    expect(referencias.where((r) => r.sexo == 'F').length, 14);
  });

  test('el login demo acepta promotor/demo123 y rechaza otra clave', () async {
    expect(await repo.autenticar('promotor', 'demo123'), isNotNull);
    expect(await repo.autenticar('PROMOTOR', 'demo123'), isNotNull);
    expect(await repo.autenticar('promotor', 'otra'), isNull);
    expect(await repo.autenticar('nadie', 'demo123'), isNull);
  });

  test(
    'el historial se ordena de la evaluación más reciente a la más antigua',
    () async {
      final historial = await repo.historial();
      for (var i = 0; i < historial.length - 1; i++) {
        expect(
          historial[i].fecha.isAfter(historial[i + 1].fecha) ||
              historial[i].fecha.isAtSameMomentAs(historial[i + 1].fecha),
          isTrue,
        );
      }
    },
  );

  test('los datos persisten después de cerrar y reabrir la base', () async {
    final ninos = await repo.listarNinos();
    final nino = ninos.first;

    final nueva = Evaluacion(
      ninoId: nino.id!,
      fecha: DateTime.now(),
      edadMeses: 18,
      pesoKg: 9.0,
      tallaCm: 80,
      muacCm: 12.2,
      edema: false,
      zPesoTalla: -1.2,
      clasificacion: 'AMARILLO',
      color: 'amarillo',
      observacion: 'Evaluación creada por la prueba de persistencia.',
    );
    await repo.insertarEvaluacion(nueva);
    expect((await repo.historial()).length, 5);

    // Simula cerrar la app y volver a abrirla.
    await DbNutriLaGuajira.instance.cerrar();
    await abrirBase();

    final historial = await repo.historial();
    expect(historial.length, 5);
    expect(
      historial.any((e) => e.observacion.contains('prueba de persistencia')),
      isTrue,
    );
    expect(await repo.contarNinos(), 3);
  });

  test('un infante nuevo se recupera por id', () async {
    final ninos = await repo.listarNinos();
    final recuperado = await repo.ninoPorId(ninos.first.id!);
    expect(recuperado, isNotNull);
    expect(recuperado!.nombreCompleto, ninos.first.nombreCompleto);
  });

  test(
    'el detalle de una evaluación incluye nombre y comunidad del infante',
    () async {
      final historial = await repo.historial();
      final detalle = await repo.evaluacionPorId(historial.first.id!);
      expect(detalle, isNotNull);
      expect(detalle!.ninoNombre, isNotEmpty);
      expect(detalle.comunidad, isNotEmpty);
    },
  );

  test('una evaluación guarda y recupera coordenadas lat/lng', () async {
    final nino = (await repo.listarNinos()).first;

    final conCoordenadas = Evaluacion(
      ninoId: nino.id!,
      fecha: DateTime.now(),
      edadMeses: 12,
      pesoKg: 9.5,
      tallaCm: 75.0,
      muacCm: 13.5,
      edema: false,
      zPesoTalla: 0.32,
      clasificacion: 'VERDE',
      color: 'verde',
      observacion: 'Evaluación con ubicación.',
      lat: 11.24712,
      lng: -72.98765,
    );
    final id = await repo.insertarEvaluacion(conCoordenadas);
    final recuperada = await repo.evaluacionPorId(id);

    expect(recuperada, isNotNull);
    expect(recuperada!.tieneUbicacion, isTrue);
    expect(recuperada.lat, closeTo(11.24712, 1e-9));
    expect(recuperada.lng, closeTo(-72.98765, 1e-9));
    expect(recuperada.ubicacionTexto, '11.24712, -72.98765');

    // Sin coordenadas sigue siendo un tamizaje válido (GPS opcional).
    final sinCoordenadas = Evaluacion(
      ninoId: nino.id!,
      fecha: DateTime.now(),
      edadMeses: 12,
      pesoKg: 9.5,
      tallaCm: 75.0,
      muacCm: 13.5,
      edema: false,
      zPesoTalla: 0.32,
      clasificacion: 'VERDE',
      color: 'verde',
      observacion: 'Evaluación sin ubicación.',
    );
    final id2 = await repo.insertarEvaluacion(sinCoordenadas);
    final recuperada2 = await repo.evaluacionPorId(id2);

    expect(recuperada2!.tieneUbicacion, isFalse);
    expect(recuperada2.lat, isNull);
    expect(recuperada2.lng, isNull);
    expect(recuperada2.ubicacionTexto, isNull);
  });

  test('la migración de v1 a v2 agrega lat/lng sin perder datos', () async {
    final ruta = '${temporal.path}/migracion.db';

    // Crea una base en versión 1 con el esquema ANTIGUO (sin lat/lng).
    final dbV1 = await databaseFactory.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE evaluaciones (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nino_id INTEGER NOT NULL,
              fecha TEXT NOT NULL,
              edad_meses INTEGER NOT NULL,
              peso_kg REAL NOT NULL,
              talla_cm REAL NOT NULL,
              muac_cm REAL NOT NULL,
              edema INTEGER NOT NULL DEFAULT 0,
              z_peso_talla REAL NOT NULL,
              clasificacion TEXT NOT NULL,
              color TEXT NOT NULL,
              observacion TEXT NOT NULL DEFAULT '',
              sincronizado INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            INSERT INTO evaluaciones
              (nino_id, fecha, edad_meses, peso_kg, talla_cm, muac_cm, edema,
               z_peso_talla, clasificacion, color, observacion, sincronizado)
            VALUES (1, '2026-01-01T00:00:00.000', 12, 9.5, 75.0, 13.5, 0,
              0.32, 'VERDE', 'verde', '', 0)
          ''');
        },
      ),
    );
    await dbV1.close();

    // Abre con el esquema actual (v2): dispara onUpgrade.
    DbNutriLaGuajira.instance.configurarParaPruebas(
      ruta: ruta,
      omitirSemilla: true,
    );
    final db = await DbNutriLaGuajira.instance.bd;

    final columnas = await db.rawQuery('PRAGMA table_info(evaluaciones)');
    final nombres = columnas.map((fila) => fila['name']).toSet();
    expect(nombres, containsAll(<String>['lat', 'lng']));

    // La fila previa sobrevivió y las columnas nuevas quedan en NULL.
    final fila = (await db.query('evaluaciones')).first;
    expect(fila['clasificacion'], 'VERDE');
    expect(fila['lat'], isNull);
    expect(fila['lng'], isNull);
  });
}
