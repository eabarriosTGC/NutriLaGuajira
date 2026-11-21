import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/db_nutrilaguajira.dart';
import 'package:nutrilaguajira/data/models/alerta_pendiente.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/data/models/referencia_edad.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/services/referencias_edad_loader.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Verifica las migraciones: v2 -> actual (crea alertas y columnas nuevas) y
/// v3 -> v4 (añade z_talla_edad/z_peso_edad y la tabla por edad).
void main() {
  late Directory temporal;
  late List<ReferenciaEdad> referenciasEdad;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final csv = File('assets/who_edad_demo.csv').readAsStringSync();
    referenciasEdad = ReferenciasEdadLoader.desdeCsv(csv);
  });

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('migracion_test_');
  });

  tearDown(() async {
    await DbNutriLaGuajira.instance.cerrar();
    if (temporal.existsSync()) {
      await temporal.delete(recursive: true);
    }
  });

  test(
    'migra v2 -> v3 conservando datos y creando alertas_pendientes',
    () async {
      final ruta = '${temporal.path}/nutrilaguajira.db';

      // 1) Base v2 con un infante y una evaluación.
      final dbV2 = await databaseFactory.openDatabase(
        ruta,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE ninos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombres TEXT NOT NULL,
              apellidos TEXT NOT NULL,
              documento TEXT NOT NULL UNIQUE,
              fecha_nacimiento TEXT NOT NULL,
              sexo TEXT NOT NULL,
              tutor TEXT NOT NULL,
              comunidad TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
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
              sincronizado INTEGER NOT NULL DEFAULT 0,
              lat REAL,
              lng REAL,
              FOREIGN KEY (nino_id) REFERENCES ninos (id) ON DELETE CASCADE
            )
          ''');

            final idNino = await db.insert('ninos', {
              'nombres': 'Andrés David',
              'apellidos': 'Jusayú González',
              'documento': 'MIG-1',
              'fecha_nacimiento': DateTime(2024, 9, 15).toIso8601String(),
              'sexo': 'M',
              'tutor': 'Tutor de Prueba',
              'comunidad': 'Ranchería Bahía Honda',
              'created_at': DateTime(2026, 1, 1).toIso8601String(),
            });
            await db.insert('evaluaciones', {
              'nino_id': idNino,
              'fecha': DateTime(2026, 11, 17, 19).toIso8601String(),
              'edad_meses': 26,
              'peso_kg': 8.8,
              'talla_cm': 85.0,
              'muac_cm': 12.0,
              'edema': 0,
              'z_peso_talla': -2.27,
              'clasificacion': 'ROJO',
              'color': 'rojo',
              'observacion': 'pre-migración',
              'sincronizado': 0,
              'lat': 11.24712,
              'lng': -72.98765,
            });
          },
        ),
      );
      await dbV2.close();

      // 2) Abrir con la versión actual: dispara onUpgrade (v2 -> v4).
      DbNutriLaGuajira.instance.configurarParaPruebas(
        ruta: ruta,
        referenciasEdad: referenciasEdad,
        omitirSemilla: true,
      );
      final repo = Repositorio();

      // Datos existentes intactos.
      expect(await repo.contarNinos(), 1);
      final historial = await repo.historial();
      expect(historial, hasLength(1));
      expect(historial.single.observacion, 'pre-migración');
      expect(historial.single.lat, closeTo(11.24712, 1e-9));

      // Tabla nueva vacía.
      expect(await repo.listarAlertas(), isEmpty);

      // Insertar alerta post-migración funciona.
      final id = await repo.insertarAlerta(
        AlertaPendiente(
          idInfante: 1,
          idEvaluacion: 1,
          severidad: 'ROJO',
          fechaCreacion: DateTime(2026, 11, 17, 20),
          mensaje: 'alerta de prueba',
        ),
      );
      expect(id, greaterThan(0));
      expect(await repo.listarAlertas(), hasLength(1));
    },
  );

  test(
    'migra v3 -> v4 añadiendo z_talla_edad/z_peso_edad y la tabla por edad',
    () async {
      final ruta = '${temporal.path}/nutrilaguajira_v3.db';

      // 1) Base v3: solo ninos + evaluaciones (sin las columnas nuevas).
      final dbV3 = await databaseFactory.openDatabase(
        ruta,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE ninos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombres TEXT NOT NULL,
              apellidos TEXT NOT NULL,
              documento TEXT NOT NULL UNIQUE,
              fecha_nacimiento TEXT NOT NULL,
              sexo TEXT NOT NULL,
              tutor TEXT NOT NULL,
              comunidad TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
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
              sincronizado INTEGER NOT NULL DEFAULT 0,
              lat REAL,
              lng REAL,
              FOREIGN KEY (nino_id) REFERENCES ninos (id) ON DELETE CASCADE
            )
          ''');

            final idNino = await db.insert('ninos', {
              'nombres': 'Andrés David',
              'apellidos': 'Jusayú González',
              'documento': 'MIG-V3',
              'fecha_nacimiento': DateTime(2024, 9, 15).toIso8601String(),
              'sexo': 'M',
              'tutor': 'Tutor de Prueba',
              'comunidad': 'Ranchería Bahía Honda',
              'created_at': DateTime(2026, 1, 1).toIso8601String(),
            });
            await db.insert('evaluaciones', {
              'nino_id': idNino,
              'fecha': DateTime(2026, 11, 17, 19).toIso8601String(),
              'edad_meses': 26,
              'peso_kg': 8.8,
              'talla_cm': 85.0,
              'muac_cm': 12.0,
              'edema': 0,
              'z_peso_talla': -2.27,
              'clasificacion': 'ROJO',
              'color': 'rojo',
              'observacion': 'pre-v4',
              'sincronizado': 0,
              'lat': 11.24712,
              'lng': -72.98765,
            });
          },
        ),
      );
      await dbV3.close();

      // 2) Abrir con v4: añade columnas y crea/puebla la tabla por edad.
      DbNutriLaGuajira.instance.configurarParaPruebas(
        ruta: ruta,
        referenciasEdad: referenciasEdad,
        omitirSemilla: true,
      );
      final repo = Repositorio();

      expect(await repo.contarNinos(), 1);
      final historial = await repo.historial();
      expect(historial, hasLength(1));
      expect(historial.single.observacion, 'pre-v4');
      // Las filas viejas no se recalculan: quedan en NULL ("N/D").
      expect(historial.single.zTallaEdad, isNull);
      expect(historial.single.zPesoEdad, isNull);
      expect(historial.single.lat, closeTo(11.24712, 1e-9));

      // La tabla por edad existe y se pobló desde el CSV.
      expect(await repo.referenciasEdad(), hasLength(240));

      // Insertar una evaluación nueva con los índices funciona.
      final nuevoId = await repo.insertarEvaluacion(
        Evaluacion(
          ninoId: 1,
          fecha: DateTime(2026, 11, 21),
          edadMeses: 26,
          pesoKg: 12.0,
          tallaCm: 86.0,
          muacCm: 12.4,
          edema: false,
          zPesoTalla: 0.43,
          zTallaEdad: -1.2,
          zPesoEdad: -0.8,
          clasificacion: 'VERDE',
          color: 'verde',
          observacion: 'post-v4',
        ),
      );
      final nueva = await repo.evaluacionPorId(nuevoId);
      expect(nueva, isNotNull);
      expect(nueva!.zTallaEdad, closeTo(-1.2, 1e-9));
      expect(nueva.zPesoEdad, closeTo(-0.8, 1e-9));
    },
  );
}
