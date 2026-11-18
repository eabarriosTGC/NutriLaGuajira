import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/db_nutrilaguajira.dart';
import 'package:nutrilaguajira/data/models/alerta_pendiente.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Verifica la migración v2 -> v3: conserva infantes/evaluaciones y crea la
/// tabla `alertas_pendientes` vacía y utilizable.
void main() {
  late Directory temporal;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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

      // 2) Abrir con la versión actual (v3): dispara onUpgrade.
      DbNutriLaGuajira.instance.configurarParaPruebas(
        ruta: ruta,
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
}
