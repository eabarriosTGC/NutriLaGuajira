import 'package:sqflite/sqflite.dart';

import 'db_nutrilaguajira.dart';
import 'models/evaluacion.dart';
import 'models/evaluacion_reporte.dart';
import 'models/nino.dart';
import 'models/referencia_who.dart';

/// Consultas de la app sobre SQLite. Toda la persistencia pasa por aqui.
class Repositorio {
  Repositorio({DbNutriLaGuajira? db}) : _db = db ?? DbNutriLaGuajira.instance;

  final DbNutriLaGuajira _db;

  Future<Database> get _base async => _db.bd;

  // ---------------------------------------------------------------- usuarios
  Future<Usuario?> autenticar(String usuario, String clave) async {
    final base = await _base;
    final filas = await base.query(
      DbNutriLaGuajira.tablaUsuarios,
      where: 'usuario = ? AND clave = ?',
      whereArgs: [usuario.trim().toLowerCase(), clave],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return Usuario.fromMap(filas.first);
  }

  // ------------------------------------------------------------------- ninos
  Future<List<Nino>> listarNinos() async {
    final base = await _base;
    final filas = await base.query(
      DbNutriLaGuajira.tablaNinos,
      orderBy: 'apellidos COLLATE NOCASE ASC, nombres COLLATE NOCASE ASC',
    );
    return filas.map(Nino.fromMap).toList();
  }

  Future<Nino?> ninoPorId(int id) async {
    final base = await _base;
    final filas = await base.query(
      DbNutriLaGuajira.tablaNinos,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return Nino.fromMap(filas.first);
  }

  Future<int> insertarNino(Nino nino) async {
    final base = await _base;
    return base.insert(DbNutriLaGuajira.tablaNinos, nino.toMap());
  }

  Future<int> actualizarNino(Nino nino) async {
    final base = await _base;
    return base.update(
      DbNutriLaGuajira.tablaNinos,
      nino.toMap(),
      where: 'id = ?',
      whereArgs: [nino.id],
    );
  }

  /// true si ya existe un infante con ese documento (documento es UNIQUE).
  Future<bool> documentoRegistrado(String documento, {int? excluirId}) async {
    final base = await _base;
    final filas = await base.query(
      DbNutriLaGuajira.tablaNinos,
      columns: ['id'],
      where: excluirId == null ? 'documento = ?' : 'documento = ? AND id <> ?',
      whereArgs: excluirId == null
          ? [documento.trim()]
          : [documento.trim(), excluirId],
      limit: 1,
    );
    return filas.isNotEmpty;
  }

  // ------------------------------------------------------------ evaluaciones
  /// Historial completo, mas reciente primero. Incluye nombre y comunidad.
  Future<List<Evaluacion>> historial({int? ninoId}) async {
    final base = await _base;
    final filas = await base.rawQuery('''
      SELECT e.*,
             n.nombres || ' ' || n.apellidos AS nino_nombre,
             n.comunidad AS comunidad
      FROM ${DbNutriLaGuajira.tablaEvaluaciones} e
      INNER JOIN ${DbNutriLaGuajira.tablaNinos} n ON n.id = e.nino_id
      ${ninoId == null ? '' : 'WHERE e.nino_id = ?'}
      ORDER BY e.fecha DESC
    ''', ninoId == null ? null : [ninoId]);
    return filas.map(Evaluacion.fromMap).toList();
  }

  Future<Evaluacion?> evaluacionPorId(int id) async {
    final base = await _base;
    final filas = await base.rawQuery(
      '''
      SELECT e.*,
             n.nombres || ' ' || n.apellidos AS nino_nombre,
             n.comunidad AS comunidad
      FROM ${DbNutriLaGuajira.tablaEvaluaciones} e
      INNER JOIN ${DbNutriLaGuajira.tablaNinos} n ON n.id = e.nino_id
      WHERE e.id = ?
      LIMIT 1
    ''',
      [id],
    );
    if (filas.isEmpty) return null;
    return Evaluacion.fromMap(filas.first);
  }

  Future<int> insertarEvaluacion(Evaluacion evaluacion) async {
    final base = await _base;
    return base.insert(DbNutriLaGuajira.tablaEvaluaciones, evaluacion.toMap());
  }

  // ---------------------------------------------------------------- reportes
  /// Comunidades/rancherías distintas registradas (para el filtro del reporte).
  Future<List<String>> comunidades() async {
    final base = await _base;
    final filas = await base.rawQuery(
      'SELECT DISTINCT comunidad FROM ${DbNutriLaGuajira.tablaNinos} '
      'ORDER BY comunidad COLLATE NOCASE ASC',
    );
    return filas
        .map((fila) => fila['comunidad'] as String)
        .where((comunidad) => comunidad.trim().isNotEmpty)
        .toList();
  }

  /// Evaluaciones aplanadas con los datos del infante (join), para CSV/PDF y
  /// la vista consolidada. Orden: más recientes primero.
  Future<List<EvaluacionReporte>> evaluacionesParaReporte() async {
    final base = await _base;
    final filas = await base.rawQuery('''
      SELECT e.id              AS id_evaluacion,
             e.nino_id         AS id_infante,
             e.fecha           AS fecha_evaluacion,
             e.peso_kg         AS peso_kg,
             e.talla_cm        AS talla_cm,
             e.muac_cm         AS muac_cm,
             e.edema           AS edema,
             e.z_peso_talla    AS z_peso_talla,
             e.clasificacion   AS clasificacion,
             e.color           AS color,
             e.lat             AS lat,
             e.lng             AS lng,
             n.nombres         AS nombres,
             n.apellidos       AS apellidos,
             n.fecha_nacimiento AS fecha_nacimiento,
             n.sexo            AS sexo,
             n.comunidad       AS rancheria
      FROM ${DbNutriLaGuajira.tablaEvaluaciones} e
      INNER JOIN ${DbNutriLaGuajira.tablaNinos} n ON n.id = e.nino_id
      ORDER BY e.fecha DESC, e.id DESC
    ''');
    return filas.map(EvaluacionReporte.fromMap).toList();
  }

  Future<int> contarNinos() async {
    final base = await _base;
    return Sqflite.firstIntValue(
          await base.rawQuery(
            'SELECT COUNT(*) FROM ${DbNutriLaGuajira.tablaNinos}',
          ),
        ) ??
        0;
  }

  // ------------------------------------------------------------- referencias
  Future<List<ReferenciaWho>> referencias() async {
    final base = await _base;
    final filas = await base.query(
      DbNutriLaGuajira.tablaReferencias,
      orderBy: 'sexo ASC, talla_cm ASC',
    );
    return filas.map(ReferenciaWho.fromMap).toList();
  }
}
