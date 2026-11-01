/// Fila de la tabla de referencia Peso/Talla.
///
/// En esta entrega la tabla es de DEMOSTRACION (`who_referencia_demo`).
/// La interfaz [ReferenciaWho] es la misma que usara la tabla OMS completa,
/// por lo que reemplazar la fuente de datos no obliga a tocar el calculo.
class ReferenciaWho {
  const ReferenciaWho({
    required this.sexo,
    required this.tallaCm,
    required this.mediana,
    required this.de,
  });

  /// 'M' = masculino, 'F' = femenino.
  final String sexo;

  /// Longitud/talla en centimetros. Es la clave de interpolacion.
  final double tallaCm;

  /// Mediana de peso (kg) para esa talla y sexo.
  final double mediana;

  /// Desviacion estandar de peso (kg) para esa talla y sexo.
  final double de;

  Map<String, Object?> toMap() => {
    'sexo': sexo,
    'talla_cm': tallaCm,
    'mediana': mediana,
    'de': de,
  };

  factory ReferenciaWho.fromMap(Map<String, Object?> map) => ReferenciaWho(
    sexo: (map['sexo'] as String).toUpperCase(),
    tallaCm: (map['talla_cm'] as num).toDouble(),
    mediana: (map['mediana'] as num).toDouble(),
    de: (map['de'] as num).toDouble(),
  );

  @override
  String toString() =>
      'ReferenciaWho($sexo, ${tallaCm}cm, mediana=$mediana, de=$de)';
}
