/// Índice antropométrico con referencia por edad.
enum IndiceAntropometrico {
  tallaEdad('T/E', 'Talla/Edad'),
  pesoEdad('P/E', 'Peso/Edad');

  const IndiceAntropometrico(this.clave, this.etiqueta);

  /// Clave estable que se persiste en SQLite ('T/E', 'P/E').
  final String clave;
  final String etiqueta;

  static IndiceAntropometrico? desdeClave(String valor) {
    final normalizado = valor.trim().toUpperCase();
    for (final indice in values) {
      if (indice.clave == normalizado) return indice;
    }
    return null;
  }
}

/// Fila de referencia por edad en formato **LMS** (L, M, S).
///
/// El motor calcula el Z con `((X/M)^L - 1) / (L*S)` (o `ln(X/M)/S` si L=0).
/// `S` es la escala **relativa** del LMS (no la DE absoluta). La tabla embarcada
/// hoy es **DEMO** (`who_edad_demo.csv`): usa `L=1` y `S = DE/M`, de modo que la
/// formula se reduce a `(X/M - 1)/S = (X - M)/DE`. Al reemplazar el CSV por las
/// tablas OMS oficiales (tambien LMS) no hay que tocar codigo.
class ReferenciaEdad {
  const ReferenciaEdad({
    required this.indice,
    required this.sexo,
    required this.edadMeses,
    required this.l,
    required this.m,
    required this.s,
  });

  final IndiceAntropometrico indice;

  /// 'M' = masculino, 'F' = femenino.
  final String sexo;

  /// Meses completos (0..59).
  final int edadMeses;

  /// Parámetros LMS.
  final double l;
  final double m;
  final double s;

  Map<String, Object?> toMap() => {
    'indice': indice.clave,
    'sexo': sexo,
    'edad_meses': edadMeses,
    'l': l,
    'm': m,
    's': s,
  };

  factory ReferenciaEdad.fromMap(Map<String, Object?> map) {
    final indice = IndiceAntropometrico.desdeClave(map['indice'] as String);
    if (indice == null) {
      throw FormatException('Índice antropométrico inválido: ${map['indice']}');
    }
    return ReferenciaEdad(
      indice: indice,
      sexo: (map['sexo'] as String).toUpperCase(),
      edadMeses: (map['edad_meses'] as num).toInt(),
      l: (map['l'] as num).toDouble(),
      m: (map['m'] as num).toDouble(),
      s: (map['s'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'ReferenciaEdad(${indice.clave}, $sexo, ${edadMeses}m, '
      'L=$l, M=$m, S=$s)';
}
