import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/nino.dart';
import 'models/referencia_who.dart';
import '../services/edad.dart';
import '../services/nutricion_service.dart';
import '../services/referencias_loader.dart';

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
  static const int versionEsquema = 1;

  static const String tablaUsuarios = 'usuarios';
  static const String tablaNinos = 'ninos';
  static const String tablaEvaluaciones = 'evaluaciones';
  static const String tablaReferencias = 'who_referencia_demo';

  Database? _db;
  String? _rutaOverride;
  List<ReferenciaWho>? _referenciasOverride;
  bool _omitirSemilla = false;

  /// Permite a los tests apuntar a una base temporal y usar referencias en
  /// memoria (los assets no estan disponibles en tests unitarios).
  void configurarParaPruebas({
    String? ruta,
    List<ReferenciaWho>? referencias,
    bool omitirSemilla = false,
  }) {
    _rutaOverride = ruta;
    _referenciasOverride = referencias;
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
      ),
    );
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
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
        created_at TEXT NOT NULL
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
    ];

    for (final sentencia in batch) {
      await db.execute(sentencia);
    }

    final referencias =
        _referenciasOverride ?? await ReferenciasLoader.cargarDesdeAssets();
    await _cargarReferencias(db, referencias);

    if (!_omitirSemilla) {
      await _sembrarDemo(db, referencias);
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

  Future<void> _sembrarDemo(
    Database db,
    List<ReferenciaWho> referencias,
  ) async {
    final servicio = NutricionService(referencias);
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
      ids.add(await db.insert(tablaNinos, nino.toMap()));
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
      'clasificacion': resultado.clasificacion.etiqueta,
      'color': resultado.clasificacion.clave,
      'observacion': resultado.observacion,
      'sincronizado': 0,
    });
  }
}
