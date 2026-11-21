import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/evaluacion_reporte.dart';

/// Estado nutricional por el que se puede filtrar un reporte.
///
/// `null` en [ReporteFiltros.estado] significa "todos".
enum EstadoReporte {
  /// Amarillo o rojo.
  riesgo,

  /// Solo rojo (desnutrición aguda).
  desnutricionAguda,
}

/// Filtros aplicables a la generación de reportes (RF-09).
class ReporteFiltros {
  const ReporteFiltros({
    required this.fechaInicio,
    required this.fechaFin,
    this.comunidad,
    this.estado,
  });

  final DateTime fechaInicio;
  final DateTime fechaFin;

  /// `null` o vacío = todas las rancherías.
  final String? comunidad;

  /// `null` = todos los estados.
  final EstadoReporte? estado;

  /// Rango válido: la fecha final no puede ser anterior a la inicial.
  bool get esValido => !_soloFecha(fechaFin).isBefore(_soloFecha(fechaInicio));

  /// Lanza un error claro si el rango es inválido (RNF-05).
  void validar() {
    if (!esValido) {
      throw ArgumentError(
        'Rango de fechas inválido: la fecha final no puede ser anterior a la '
        'inicial (${_soloFecha(fechaInicio)} > ${_soloFecha(fechaFin)}).',
      );
    }
  }

  /// true si la evaluación cumple todos los filtros activos.
  bool cumple(EvaluacionReporte evaluacion) {
    final fecha = _soloFecha(evaluacion.fechaEvaluacion);
    if (fecha.isBefore(_soloFecha(fechaInicio))) return false;
    if (fecha.isAfter(_soloFecha(fechaFin))) return false;

    final comunidadBuscada = comunidad?.trim();
    if (comunidadBuscada != null &&
        comunidadBuscada.isNotEmpty &&
        evaluacion.rancheria != comunidadBuscada) {
      return false;
    }

    switch (estado) {
      case null:
        return true;
      case EstadoReporte.riesgo:
        return evaluacion.esRiesgo;
      case EstadoReporte.desnutricionAguda:
        return evaluacion.esDesnutricionAguda;
    }
  }

  /// Descripción legible de los filtros (para el PDF y la UI).
  String get descripcion {
    final desde = _textoFecha(fechaInicio);
    final hasta = _textoFecha(fechaFin);
    final zona = (comunidad == null || comunidad!.trim().isEmpty)
        ? 'Todas las rancherías'
        : comunidad!.trim();
    final estadoTexto = switch (estado) {
      null => 'Todos los estados',
      EstadoReporte.riesgo => 'Riesgo (amarillo/rojo)',
      EstadoReporte.desnutricionAguda => 'Desnutrición aguda (rojo)',
    };
    return 'Del $desde al $hasta · $zona · $estadoTexto';
  }

  static DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  static String _textoFecha(DateTime fecha) {
    final d = _soloFecha(fecha);
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

/// Generador de reportes CSV (RF-09).
///
/// - 100 % local (RNF-01): no usa red.
/// - UTF-8 con BOM para que Excel en Windows muestre tildes y ñ.
/// - Escape de comas, comillas y saltos de línea según RFC 4180.
class ReporteCsvService {
  static const String bom = '\uFEFF';
  static const String separador = '\r\n';

  /// Columnas exactas y en orden (ASCII, sin tildes, para no romper parsers).
  static const List<String> columnas = <String>[
    'id_infante',
    'nombres',
    'apellidos',
    'fecha_nacimiento',
    'sexo',
    'rancheria',
    'fecha_evaluacion',
    'peso_kg',
    'talla_cm',
    'perimetro_braquial_cm',
    'edema',
    'z_peso_talla',
    'z_talla_edad',
    'z_peso_edad',
    'clasificacion_nutricional',
    'latitud',
    'longitud',
  ];

  /// Construye el contenido CSV (texto) aplicando los filtros.
  ///
  /// Lanza [ArgumentError] si el rango de fechas es inválido.
  String generar(List<EvaluacionReporte> evaluaciones, ReporteFiltros filtros) {
    filtros.validar();

    final filas = evaluaciones.where(filtros.cumple).toList()
      ..sort((a, b) => b.fechaEvaluacion.compareTo(a.fechaEvaluacion));

    final lineas = <String>[
      columnas.map(_escapar).join(','),
      for (final evaluacion in filas)
        _valores(evaluacion).map(_escapar).join(','),
    ];

    return bom + lineas.join(separador);
  }

  /// Bytes UTF-8 del CSV (el BOM ya viene incluido en el texto).
  List<int> generarBytes(
    List<EvaluacionReporte> evaluaciones,
    ReporteFiltros filtros,
  ) => utf8.encode(generar(evaluaciones, filtros));

  /// Guarda el CSV en `<documentos>/exports/` (sandbox de la app, RNF-06).
  Future<File> guardar(String csv, String nombreArchivo) async {
    final documentos = await getApplicationDocumentsDirectory();
    final exports = Directory(p.join(documentos.path, 'exports'));
    if (!await exports.exists()) {
      await exports.create(recursive: true);
    }
    final archivo = File(p.join(exports.path, nombreArchivo));
    await archivo.writeAsBytes(utf8.encode(csv), flush: true);
    return archivo;
  }

  /// Nombre de archivo sugerido, p. ej. `nutrilaguajira_reporte_20261117_181500.csv`.
  static String nombreSugerido(DateTime ahora) {
    String dos(int v) => v.toString().padLeft(2, '0');
    final fecha =
        '${ahora.year}${dos(ahora.month)}${dos(ahora.day)}_'
        '${dos(ahora.hour)}${dos(ahora.minute)}${dos(ahora.second)}';
    return 'nutrilaguajira_reporte_$fecha.csv';
  }

  /// Un renglón de datos, en el mismo orden que [columnas].
  List<String> _valores(EvaluacionReporte e) => <String>[
    '${e.idInfante}',
    e.nombres,
    e.apellidos,
    e.fechaNacimientoTexto,
    e.sexo,
    e.rancheria,
    e.fechaEvaluacionTexto,
    e.pesoKg.toStringAsFixed(2),
    e.tallaCm.toStringAsFixed(1),
    e.perimetroBraquialCm.toStringAsFixed(1),
    e.edema ? 'Sí' : 'No',
    e.zPesoTalla.toStringAsFixed(2),
    e.zTallaEdad?.toStringAsFixed(2) ?? '',
    e.zPesoEdad?.toStringAsFixed(2) ?? '',
    e.clasificacionNutricional,
    e.latitud?.toStringAsFixed(5) ?? '',
    e.longitud?.toStringAsFixed(5) ?? '',
  ];

  /// Escapa un campo según RFC 4180: si contiene coma, comilla o salto de
  /// línea, se encierra entre comillas y las comillas internas se duplican.
  static String _escapar(String valor) {
    final requiere =
        valor.contains(',') ||
        valor.contains('"') ||
        valor.contains('\n') ||
        valor.contains('\r');
    if (!requiere) return valor;
    return '"${valor.replaceAll('"', '""')}"';
  }
}
