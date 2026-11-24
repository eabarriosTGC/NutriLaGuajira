import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/nino.dart';
import 'models/referencia_edad.dart';
import 'models/referencia_who.dart';
import '../services/edad.dart';
import '../services/nutricion_service.dart';
import '../services/referencias_edad_loader.dart';
import '../services/referencias_loader.dart';
import '../services/uuid_local.dart';

/// Acceso a la base de datos local SQLite (sqflite).
///
/// - Crea el esquema en `onCreate`.
/// - Carga la tabla de referencia DEMO desde el CSV de assets.
/// - Siembra datos de demostracion (3 infantes y 4 evaluaciones) calculando
///   los resultados con el mismo [NutricionService] que usa la app, para que
///   la semilla nunca quede inconsistente con el motor.
///
/// Para pruebas se puede fijar una ruta temporal y un paquete de referencias
/// propio (ver [configurarParaPruebas]).
class DbNutriLaGuajira {
  DbNutriLaGuajira._();

  static final DbNutriLaGuajira instance = DbNutriLaGuajira._();

  static const String nombreArchivo = 'nutrilaguajira.db';
  static const int versionEsquema = 5;

  static const String tablaUsuarios = 'usuarios';
  static const String tablaNinos = 'ninos';
  static const String tablaEvaluaciones = 'evaluaciones';
  static const String tablaReferencias = 'who_referencia_demo';
  static const String tablaReferenciasEdad = 'who_referencia_edad_demo';
  static const String tablaAlertas = 'alertas_pendientes';

  Database? _db;
  final List<Database> _conexionesAnteriores = [];
  String? _rutaOverride;
  List<ReferenciaWho>? _referenciasOverride;
  List<ReferenciaEdad>? _referenciasEdadOverride;
  bool _omitirSemilla = false;

  /// Permite a los tests apuntar a una base temporal y usar referencias en
  /// memoria (los assets no estan disponibles en tests unitarios).
  void configurarParaPruebas({
    String? ruta,
    List<ReferenciaWho>? referencias,
    List<ReferenciaEdad>? referenciasEdad,
    bool omitirSemilla = false,
  }) {
    // No se puede cerrar de forma asíncrona aquí: se conserva la conexión
    // anterior para cerrarla en [cerrar] y evitar archivos bloqueados en
    // Windows cuando una prueba reapunta la base a otra ruta.
    final actual = _db;
    if (actual != null) _conexionesAnteriores.add(actual);
    _rutaOverride = ruta;
    _referenciasOverride = referencias;
    _referenciasEdadOverride = referenciasEdad;
    _omitirSemilla = omitirSemilla;
    _db = null;
  }

  Future<Database> get bd async => _db ??= await _abrir();

  Future<String> _ruta() async {
    if (_rutaOverride != null) return _rutaOverride!;
    return p.join(await getDatabasesPath(), nombreArchivo);
  }

  Future<Database> _abrir() async {
    final ruta = await _ruta();
    return databaseFactory.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: versionEsquema,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Migraciones incrementales de esquema. Cada cambio de `versionEsquema`
  /// agrega aqui un bloque `if (oldVersion < N)`.
  ///
  /// v1 -> v2: columnas `lat`/`lng` en `evaluaciones` (coordenadas de la
  /// ranchería, opcionales). SQLite no permite DROP COLUMN antiguo ni ADD con
  /// NOT NULL sin valor por defecto, por eso se agregan como REAL nullable.
  ///
  /// v2 -> v3: tabla `alertas_pendientes` (RF-10). No toca datos existentes.
  ///
  /// v3 -> v4: columnas `z_talla_edad`/`z_peso_edad` en `evaluaciones` y tabla
  /// `who_referencia_edad_demo` (LMS por edad). Las filas viejas quedan en
  /// `NULL` (se muestran como "N/D"); no se recalculan.
  ///
  /// v4 -> v5: soporte de sincronización con Firestore. Se agrega `uuid` (id
  /// estable para el documento remoto), `sincronizado`/`updated_at` en `ninos`
  /// y `updated_at` en `evaluaciones`. Las filas existentes se marcan como
  /// pendientes (`sincronizado = 0`) y reciben un `uuid` determinista basado en
  /// su id local, de modo que la primera sincronización no duplique datos.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tablaEvaluaciones ADD COLUMN lat REAL');
      await db.execute('ALTER TABLE $tablaEvaluaciones ADD COLUMN lng REAL');
    }
    if (oldVersion < 3) {
      await db.execute(_crearTablaAlertas);
      await db.execute(
        'CREATE INDEX idx_alerta_estado ON $tablaAlertas (estado)',
      );
      await db.execute(
        'CREATE INDEX idx_alerta_fecha ON $tablaAlertas (fecha_creacion DESC)',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE $tablaEvaluaciones ADD COLUMN z_talla_edad REAL',
      );
      await db.execute(
        'ALTER TABLE $tablaEvaluaciones ADD COLUMN z_peso_edad REAL',
      );
      await db.execute(_crearTablaReferenciasEdad);
      final referenciasEdad =
          _referenciasEdadOverride ??
          await ReferenciasEdadLoader.cargarDesdeAssets();
      await _cargarReferenciasEdad(db, referenciasEdad);
    }
    if (oldVersion < 5) {
      final tablas = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      )).map((fila) => fila['name'] as String).toSet();
      final tieneNinos = tablas.contains(tablaNinos);
      final tieneEvaluaciones = tablas.contains(tablaEvaluaciones);

      if (tieneNinos) {
        await db.execute('ALTER TABLE $tablaNinos ADD COLUMN uuid TEXT');
        await db.execute(
          'ALTER TABLE $tablaNinos ADD COLUMN sincronizado INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await db.execute('ALTER TABLE $tablaNinos ADD COLUMN updated_at TEXT');

        // Relleno determinista para no reenviar dos veces los mismos registros.
        await db.execute(
          "UPDATE $tablaNinos SET uuid = 'nino-' || id, "
          'updated_at = created_at WHERE uuid IS NULL',
        );
        await db.execute(
          'CREATE UNIQUE INDEX idx_nino_uuid ON $tablaNinos (uuid)',
        );
        await db.execute(
          'CREATE INDEX idx_nino_sync ON $tablaNinos (sincronizado)',
        );
      }

      if (tieneEvaluaciones) {
        await db.execute('ALTER TABLE $tablaEvaluaciones ADD COLUMN uuid TEXT');
        await db.execute(
          'ALTER TABLE $tablaEvaluaciones ADD COLUMN updated_at TEXT',
        );
        await db.execute(
          "UPDATE $tablaEvaluaciones SET uuid = 'eval-' || id, "
          'updated_at = fecha WHERE uuid IS NULL',
        );
        await db.execute(
          'CREATE INDEX idx_eval_sync ON $tablaEvaluaciones (sincronizado)',
        );
        await db.execute(
          'CREATE UNIQUE INDEX idx_eval_uuid ON $tablaEvaluaciones (uuid)',
        );
      }
    }
  }

  /// DDL de `alertas_pendientes`, compartido por `onCreate` y `onUpgrade`.
  static const String _crearTablaAlertas =
      '''
    CREATE TABLE $tablaAlertas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      id_infante INTEGER NOT NULL,
      id_evaluacion INTEGER NOT NULL,
      severidad TEXT NOT NULL,
      latitud REAL,
      longitud REAL,
      fecha_creacion TEXT NOT NULL,
      estado TEXT NOT NULL DEFAULT 'PENDIENTE',
      mensaje TEXT NOT NULL,
      fecha_envio TEXT,
      FOREIGN KEY (id_infante) REFERENCES $tablaNinos (id) ON DELETE CASCADE,
      FOREIGN KEY (id_evaluacion) REFERENCES $tablaEvaluaciones (id)
        ON DELETE CASCADE
    )
  ''';

  /// DDL de la referencia por edad (LMS), compartido por `onCreate` y v4.
  static const String _crearTablaReferenciasEdad =
      '''
    CREATE TABLE $tablaReferenciasEdad (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      indice TEXT NOT NULL,
      sexo TEXT NOT NULL,
      edad_meses INTEGER NOT NULL,
      l REAL NOT NULL,
      m REAL NOT NULL,
      s REAL NOT NULL,
      UNIQUE (indice, sexo, edad_meses)
    )
  ''';

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
    for (final conexion in _conexionesAnteriores) {
      try {
        await conexion.close();
      } catch (_) {
        // Ya estaba cerrada.
      }
    }
    _conexionesAnteriores.clear();
  }

  Future<void> _onCreate(Database db, int version) async {
    const batch = <String>[
      '''
      CREATE TABLE $tablaUsuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL UNIQUE,
        clave TEXT NOT NULL,
        nombre TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE $tablaNinos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        documento TEXT NOT NULL UNIQUE,
        fecha_nacimiento TEXT NOT NULL,
        sexo TEXT NOT NULL,
        tutor TEXT NOT NULL,
        comunidad TEXT NOT NULL,
        created_at TEXT NOT NULL,
        uuid TEXT,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
      ''',
      '''
      CREATE TABLE $tablaEvaluaciones (
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
        z_talla_edad REAL,
        z_peso_edad REAL,
        uuid TEXT,
        updated_at TEXT,
        FOREIGN KEY (nino_id) REFERENCES $tablaNinos (id) ON DELETE CASCADE
      )
      ''',
      '''
      CREATE TABLE $tablaReferencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sexo TEXT NOT NULL,
        talla_cm REAL NOT NULL,
        mediana REAL NOT NULL,
        de REAL NOT NULL,
        UNIQUE (sexo, talla_cm)
      )
      ''',
      'CREATE INDEX idx_eval_nino ON $tablaEvaluaciones (nino_id)',
      'CREATE INDEX idx_eval_fecha ON $tablaEvaluaciones (fecha DESC)',
      'CREATE INDEX idx_nino_sync ON $tablaNinos (sincronizado)',
      'CREATE INDEX idx_eval_sync ON $tablaEvaluaciones (sincronizado)',
      'CREATE UNIQUE INDEX idx_nino_uuid ON $tablaNinos (uuid)',
      'CREATE UNIQUE INDEX idx_eval_uuid ON $tablaEvaluaciones (uuid)',
      _crearTablaAlertas,
      'CREATE INDEX idx_alerta_estado ON $tablaAlertas (estado)',
      'CREATE INDEX idx_alerta_fecha ON $tablaAlertas (fecha_creacion DESC)',
      _crearTablaReferenciasEdad,
    ];

    for (final sentencia in batch) {
      await db.execute(sentencia);
    }

    final referencias =
        _referenciasOverride ?? await ReferenciasLoader.cargarDesdeAssets();
    final referenciasEdad =
        _referenciasEdadOverride ??
        await ReferenciasEdadLoader.cargarDesdeAssets();
    await _cargarReferencias(db, referencias);
    await _cargarReferenciasEdad(db, referenciasEdad);

    if (!_omitirSemilla) {
      await _sembrarDemo(db, referencias, referenciasEdad);
    }
  }

  Future<void> _cargarReferencias(
    Database db,
    List<ReferenciaWho> referencias,
  ) async {
    final lote = db.batch();
    for (final referencia in referencias) {
      lote.insert(tablaReferencias, referencia.toMap());
    }
    await lote.commit(noResult: true);
  }

  Future<void> _cargarReferenciasEdad(
    Database db,
    List<ReferenciaEdad> referencias,
  ) async {
    final lote = db.batch();
    for (final referencia in referencias) {
      lote.insert(tablaReferenciasEdad, referencia.toMap());
    }
    await lote.commit(noResult: true);
  }

  Future<void> _sembrarDemo(
    Database db,
    List<ReferenciaWho> referencias,
    List<ReferenciaEdad> referenciasEdad,
  ) async {
    final servicio = NutricionService(
      referencias,
      referenciasEdad: referenciasEdad,
    );
    final hoy = DateTime.now();

    DateTime nacimientoHaceMeses(int meses) =>
        DateTime(hoy.year, hoy.month - meses, 15, 9);
    DateTime haceDias(int dias) => hoy.subtract(Duration(days: dias));

    await db.insert(tablaUsuarios, {
      'usuario': 'promotor',
      'clave': 'demo123',
      'nombre': 'Promotor(a) de Salud',
    });

    final nino1 = Nino(
      nombres: 'José Ángel',
      apellidos: 'Epieyú Uriana',
      documento: 'TI-1001',
      fechaNacimiento: nacimientoHaceMeses(12),
      sexo: 'M',
      tutor: 'María Uriana',
      comunidad: 'Ranchería El Cardón',
    );
    final nino2 = Nino(
      nombres: 'Yuliana Andrea',
      apellidos: 'Ipuana Pushaina',
      documento: 'TI-1002',
      fechaNacimiento: nacimientoHaceMeses(19),
      sexo: 'F',
      tutor: 'Carmen Pushaina',
      comunidad: 'Ranchería Siapana',
    );
    final nino3 = Nino(
      nombres: 'Andrés David',
      apellidos: 'Jusayú González',
      documento: 'TI-1003',
      fechaNacimiento: nacimientoHaceMeses(26),
      sexo: 'M',
      tutor: 'Luis Jusayú',
      comunidad: 'Ranchería Bahía Honda',
    );

    final semillas = <Nino>[nino1, nino2, nino3];
    final ids = <int>[];
    for (final nino in semillas) {
      // La semilla es solo demostrativa: se marca como sincronizada para no
      // subir datos ficticios a Firestore al iniciar sesión por primera vez.
      ids.add(
        await db.insert(tablaNinos, {
          ...nino.toMap(),
          'uuid': generarUuidLocal('nino'),
          'sincronizado': 1,
          'updated_at': hoy.toIso8601String(),
        }),
      );
    }

    // Caso VERDE: nino de ~11 meses, 75 cm y 9.5 kg (Z ≈ +0.32).
    await _sembrarEvaluacion(
      db: db,
      servicio: servicio,
      nino: nino1.copyWith(id: ids[0]),
      fecha: haceDias(15),
      pesoKg: 9.5,
      tallaCm: 75,
      muacCm: 13.5,
      edema: false,
    );

    // Caso AMARILLO: nina de ~18 meses, 80 cm y 8.7 kg (Z ≈ -1.20).
    await _sembrarEvaluacion(
      db: db,
      servicio: servicio,
      nino: nino2.copyWith(id: ids[1]),
      fecha: haceDias(10),
      pesoKg: 8.7,
      tallaCm: 80,
      muacCm: 12.2,
      edema: false,
    );

    // Caso ROJO por Z: nino de ~24 meses, 85 cm y 8.8 kg (Z ≈ -2.27).
    await _sembrarEvaluacion(
      db: db,
      servicio: servicio,
      nino: nino3.copyWith(id: ids[2]),
      fecha: haceDias(40),
      pesoKg: 8.8,
      tallaCm: 85,
      muacCm: 12.0,
      edema: false,
    );

    // Caso ROJO por edema con Z normal: 86 cm y 12.0 kg (Z ≈ +0.43) + edema.
    await _sembrarEvaluacion(
      db: db,
      servicio: servicio,
      nino: nino3.copyWith(id: ids[2]),
      fecha: haceDias(3),
      pesoKg: 12.0,
      tallaCm: 86,
      muacCm: 12.4,
      edema: true,
    );
  }

  Future<void> _sembrarEvaluacion({
    required Database db,
    required NutricionService servicio,
    required Nino nino,
    required DateTime fecha,
    required double pesoKg,
    required double tallaCm,
    required double muacCm,
    required bool edema,
  }) async {
    final edadMeses = Edad.enMeses(nino.fechaNacimiento, fecha);
    final resultado = servicio.evaluar(
      sexo: nino.sexo,
      edadMeses: edadMeses,
      pesoKg: pesoKg,
      tallaCm: tallaCm,
      muacCm: muacCm,
      edema: edema,
      validarRangos: false,
    );

    await db.insert(tablaEvaluaciones, {
      'nino_id': nino.id,
      'fecha': fecha.toIso8601String(),
      'edad_meses': edadMeses,
      'peso_kg': pesoKg,
      'talla_cm': tallaCm,
      'muac_cm': muacCm,
      'edema': edema ? 1 : 0,
      'z_peso_talla': resultado.zPesoTalla,
      'z_talla_edad': resultado.zTallaEdad,
      'z_peso_edad': resultado.zPesoEdad,
      'clasificacion': resultado.clasificacion.etiqueta,
      'color': resultado.clasificacion.clave,
      'observacion': resultado.observacion,
      'sincronizado': 1,
      'uuid': generarUuidLocal('eval'),
      'updated_at': fecha.toIso8601String(),
    });
  }
}
