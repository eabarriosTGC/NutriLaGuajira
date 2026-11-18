/// Consolidado de una ranchería para la vista "Zonas en riesgo" (RF-09).
class ResumenZona {
  const ResumenZona({
    required this.rancheria,
    required this.rojos,
    required this.amarillos,
    required this.verdes,
    required this.total,
    required this.ultimaFecha,
    this.latitudCritico,
    this.longitudCritico,
  });

  final String rancheria;
  final int rojos;
  final int amarillos;
  final int verdes;
  final int total;

  /// Fecha del tamizaje más reciente de la ranchería.
  final DateTime ultimaFecha;

  /// Coordenadas del último caso ROJO de la ranchería (puede ser null si ese
  /// último rojo no capturó GPS). No es un promedio: es el punto exacto del
  /// caso más reciente para orientar la brigada.
  final double? latitudCritico;
  final double? longitudCritico;

  bool get tieneCritico => rojos > 0;

  bool get tieneUbicacionCritico =>
      latitudCritico != null && longitudCritico != null;

  factory ResumenZona.fromMap(Map<String, Object?> map) => ResumenZona(
    rancheria: map['rancheria'] as String,
    rojos: (map['rojos'] as num).toInt(),
    amarillos: (map['amarillos'] as num).toInt(),
    verdes: (map['verdes'] as num).toInt(),
    total: (map['total'] as num).toInt(),
    ultimaFecha: DateTime.parse(map['ultima'] as String),
    latitudCritico: (map['lat_critico'] as num?)?.toDouble(),
    longitudCritico: (map['lng_critico'] as num?)?.toDouble(),
  );

  @override
  String toString() =>
      'ResumenZona($rancheria, rojos=$rojos, amarillos=$amarillos, '
      'verdes=$verdes)';
}
