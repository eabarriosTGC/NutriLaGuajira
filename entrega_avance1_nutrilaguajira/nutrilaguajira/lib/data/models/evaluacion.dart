/// Evaluacion antropometrica de un infante.
///
/// [clasificacion] guarda la etiqueta legible (VERDE / AMARILLO / ROJO) y
/// [color] la clave usada por la UI ('verde', 'amarillo', 'rojo').
class Evaluacion {
  const Evaluacion({
    this.id,
    required this.ninoId,
    required this.fecha,
    required this.edadMeses,
    required this.pesoKg,
    required this.tallaCm,
    required this.muacCm,
    required this.edema,
    required this.zPesoTalla,
    required this.clasificacion,
    required this.color,
    required this.observacion,
    this.sincronizado = false,
    this.ninoNombre,
    this.comunidad,
  });

  final int? id;
  final int ninoId;
  final DateTime fecha;
  final int edadMeses;
  final double pesoKg;
  final double tallaCm;
  final double muacCm;
  final bool edema;
  final double zPesoTalla;
  final String clasificacion;
  final String color;
  final String observacion;

  /// Siempre false en el Avance 1: no hay sincronizacion (proximo sprint).
  final bool sincronizado;

  /// Solo se llenan cuando la evaluacion viene de un JOIN con `ninos`.
  final String? ninoNombre;
  final String? comunidad;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'nino_id': ninoId,
    'fecha': fecha.toIso8601String(),
    'edad_meses': edadMeses,
    'peso_kg': pesoKg,
    'talla_cm': tallaCm,
    'muac_cm': muacCm,
    'edema': edema ? 1 : 0,
    'z_peso_talla': zPesoTalla,
    'clasificacion': clasificacion,
    'color': color,
    'observacion': observacion,
    'sincronizado': sincronizado ? 1 : 0,
  };

  /// Copia con el id asignado por SQLite (la insercion devuelve el rowid).
  Evaluacion copyWithId(int id) => Evaluacion(
    id: id,
    ninoId: ninoId,
    fecha: fecha,
    edadMeses: edadMeses,
    pesoKg: pesoKg,
    tallaCm: tallaCm,
    muacCm: muacCm,
    edema: edema,
    zPesoTalla: zPesoTalla,
    clasificacion: clasificacion,
    color: color,
    observacion: observacion,
    sincronizado: sincronizado,
    ninoNombre: ninoNombre,
    comunidad: comunidad,
  );

  factory Evaluacion.fromMap(Map<String, Object?> map) => Evaluacion(
    id: map['id'] as int?,
    ninoId: map['nino_id'] as int,
    fecha: DateTime.parse(map['fecha'] as String),
    edadMeses: map['edad_meses'] as int,
    pesoKg: (map['peso_kg'] as num).toDouble(),
    tallaCm: (map['talla_cm'] as num).toDouble(),
    muacCm: (map['muac_cm'] as num).toDouble(),
    edema: (map['edema'] as num).toInt() == 1,
    zPesoTalla: (map['z_peso_talla'] as num).toDouble(),
    clasificacion: map['clasificacion'] as String,
    color: map['color'] as String,
    observacion: (map['observacion'] as String?) ?? '',
    sincronizado: ((map['sincronizado'] as num?)?.toInt() ?? 0) == 1,
    ninoNombre: map['nino_nombre'] as String?,
    comunidad: map['comunidad'] as String?,
  );
}
