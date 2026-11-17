import '../../services/fechas.dart';

/// Fila "aplanada" de un reporte: mezcla los datos del infante con los de una
/// evaluación suya (resultado del JOIN `evaluaciones` ↔ `ninos`).
///
/// Es un DTO de solo lectura pensado para CSV/PDF y para la vista consolidada
/// de zonas en riesgo. No se persiste.
class EvaluacionReporte {
  const EvaluacionReporte({
    required this.idEvaluacion,
    required this.idInfante,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.sexo,
    required this.rancheria,
    required this.fechaEvaluacion,
    required this.pesoKg,
    required this.tallaCm,
    required this.perimetroBraquialCm,
    required this.edema,
    required this.zPesoTalla,
    required this.clasificacionNutricional,
    required this.color,
    this.zTallaEdad,
    this.zPesoEdad,
    this.latitud,
    this.longitud,
  });

  final int idEvaluacion;
  final int idInfante;
  final String nombres;
  final String apellidos;
  final DateTime fechaNacimiento;

  /// 'M' = masculino, 'F' = femenino.
  final String sexo;

  /// Comunidad / ranchería del infante.
  final String rancheria;

  final DateTime fechaEvaluacion;
  final double pesoKg;
  final double tallaCm;
  final double perimetroBraquialCm;
  final bool edema;
  final double zPesoTalla;

  /// Etiqueta legible: VERDE / AMARILLO / ROJO.
  final String clasificacionNutricional;

  /// Clave persistida: 'verde' / 'amarillo' / 'rojo' (para filtros).
  final String color;

  /// TODO(sprint4): Talla/Edad no se calcula todavía (requiere tablas OMS por
  /// edad). Se deja nulo y el CSV lo exporta como celda vacía.
  final double? zTallaEdad;

  /// TODO(sprint4): Peso/Edad no se calcula todavía (requiere tablas OMS por
  /// edad). Se deja nulo y el CSV lo exporta como celda vacía.
  final double? zPesoEdad;

  final double? latitud;
  final double? longitud;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  /// Riesgo = amarillo o rojo.
  bool get esRiesgo => color == 'amarillo' || color == 'rojo';

  /// Desnutrición aguda = rojo.
  bool get esDesnutricionAguda => color == 'rojo';

  bool get tieneUbicacion => latitud != null && longitud != null;

  /// Fecha de nacimiento en formato dd/MM/yyyy (para el CSV).
  String get fechaNacimientoTexto => Fechas.corta(fechaNacimiento);

  /// Fecha de la evaluación en formato dd/MM/yyyy HH:mm (para el CSV).
  String get fechaEvaluacionTexto => Fechas.conHora(fechaEvaluacion);

  /// Mapea una fila del JOIN. Las claves son los alias usados en la consulta
  /// de `Repositorio.evaluacionesParaReporte()`.
  factory EvaluacionReporte.fromMap(Map<String, Object?> map) =>
      EvaluacionReporte(
        idEvaluacion: map['id_evaluacion'] as int,
        idInfante: map['id_infante'] as int,
        nombres: map['nombres'] as String,
        apellidos: map['apellidos'] as String,
        fechaNacimiento: DateTime.parse(map['fecha_nacimiento'] as String),
        sexo: (map['sexo'] as String).toUpperCase(),
        rancheria: map['rancheria'] as String,
        fechaEvaluacion: DateTime.parse(map['fecha_evaluacion'] as String),
        pesoKg: (map['peso_kg'] as num).toDouble(),
        tallaCm: (map['talla_cm'] as num).toDouble(),
        perimetroBraquialCm: (map['muac_cm'] as num).toDouble(),
        edema: (map['edema'] as num).toInt() == 1,
        zPesoTalla: (map['z_peso_talla'] as num).toDouble(),
        clasificacionNutricional: map['clasificacion'] as String,
        color: map['color'] as String,
        latitud: (map['lat'] as num?)?.toDouble(),
        longitud: (map['lng'] as num?)?.toDouble(),
      );

  @override
  String toString() =>
      'EvaluacionReporte(#$idEvaluacion, infante=$idInfante, '
      'rancheria=$rancheria, color=$color)';
}
