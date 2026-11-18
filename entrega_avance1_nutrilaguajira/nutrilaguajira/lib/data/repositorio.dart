import 'package:sqflite/sqflite.dart';

import 'db_nutrilaguajira.dart';
import 'models/alerta_pendiente.dart';
import 'models/evaluacion.dart';
import 'models/evaluacion_reporte.dart';
import 'models/nino.dart';
import 'models/referencia_who.dart';
import 'models/resumen_zona.dart';

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

  // -------------------------------------------------------- zonas en riesgo
  /// Consolidado por ranchería, ordenado por criticidad (rojos DESC).
  ///
  /// [desde] es opcional; si se indica, solo cuenta evaluaciones desde esa
  /// fecha. Para el último caso ROJO se devuelven sus coordenadas exactas (no
  /// un promedio), que pueden ser null si ese tamizaje no capturó GPS.
  Future<List<ResumenZona>> resumenPorRancheria({DateTime? desde}) async {
    final base = await _base;
    final filas = await base.rawQuery('''
      SELECT n.comunidad AS rancheria,
             SUM(CASE WHEN e.clasificacion = 'ROJO' THEN 1 ELSE 0 END) AS rojos,
             SUM(CASE WHEN e.clasificacion = 'AMARILLO' THEN 1 ELSE 0 END)
               AS amarillos,
             SUM(CASE WHEN e.clasificacion = 'VERDE' THEN 1 ELSE 0 END)
               AS verdes,
             COUNT(*) AS total,
             MAX(e.fecha) AS ultima,
             (SELECT e2.lat
                FROM ${DbNutriLaGuajira.tablaEvaluaciones} e2
                JOIN ${DbNutriLaGuajira.tablaNinos} n2 ON n2.id = e2.nino_id
               WHERE n2.comunidad = n.comunidad
                 AND e2.clasificacion = 'ROJO'
               ORDER BY e2.fecha DESC, e2.id DESC
               LIMIT 1) AS lat_critico,
             (SELECT e2.lng
                FROM ${DbNutriLaGuajira.tablaEvaluaciones} e2
                JOIN ${DbNutriLaGuajira.tablaNinos} n2 ON n2.id = e2.nino_id
               WHERE n2.comunidad = n.comunidad
                 AND e2.clasificacion = 'ROJO'
               ORDER BY e2.fecha DESC, e2.id DESC
               LIMIT 1) AS lng_critico
      FROM ${DbNutriLaGuajira.tablaEvaluaciones} e
      JOIN ${DbNutriLaGuajira.tablaNinos} n ON n.id = e.nino_id
      ${desde == null ? '' : 'WHERE e.fecha >= ?'}
      GROUP BY n.comunidad
      ORDER BY rojos DESC, amarillos DESC, total DESC
    ''', desde == null ? null : [desde.toIso8601String()]);
    return filas.map(ResumenZona.fromMap).toList();
  }

  // ----------------------------------------------------------------- alertas
  Future<int> insertarAlerta(AlertaPendiente alerta) async {
    final base = await _base;
    return base.insert(DbNutriLaGuajira.tablaAlertas, alerta.toMap());
  }

  /// Alertas ordenadas por fecha de creación descendente, con el nombre del
  /// infante y su ranchería (JOIN), igual que hace `historial()` con las
  /// evaluaciones.
  Future<List<AlertaPendiente>> listarAlertas({EstadoAlerta? estado}) async {
    final base = await _base;
    final filas = await base.rawQuery('''
      SELECT a.*,
             n.nombres || ' ' || n.apellidos AS nombre_infante,
             n.comunidad AS rancheria
      FROM ${DbNutriLaGuajira.tablaAlertas} a
      LEFT JOIN ${DbNutriLaGuajira.tablaNinos} n ON n.id = a.id_infante
      ${estado == null ? '' : 'WHERE a.estado = ?'}
      ORDER BY a.fecha_creacion DESC, a.id DESC
    ''', estado == null ? null : [estado.clave]);
    return filas.map(AlertaPendiente.fromMap).toList();
  }

  Future<int> actualizarEstadoAlerta(
    int id,
    EstadoAlerta estado, {
    String? fechaEnvio,
  }) async {
    final base = await _base;
    return base.update(
      DbNutriLaGuajira.tablaAlertas,
      <String, Object?>{'estado': estado.clave, 'fecha_envio': ?fechaEnvio},
      where: 'id = ?',
      whereArgs: [id],
    );
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
