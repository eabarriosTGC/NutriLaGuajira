import '../data/models/referencia_who.dart';

/// Clasificacion del semaforo nutricional.
///
/// La severidad se usa para combinar criterios: cuando el Z-score y el MUAC
/// no coinciden se conserva el criterio MAS GRAVE (criterio de seguridad).
enum ClasificacionNutricional {
  verde('VERDE', 'Estado nutricional adecuado', 0),
  amarillo('AMARILLO', 'Riesgo de desnutrición', 1),
  rojo('ROJO', 'Desnutrición aguda', 2);

  const ClasificacionNutricional(
    this.etiqueta,
    this.descripcion,
    this.severidad,
  );

  final String etiqueta;
  final String descripcion;
  final int severidad;

  /// Clave estable que se persiste en SQLite ('verde', 'amarillo', 'rojo').
  String get clave => name;

  static ClasificacionNutricional desdeClave(String valor) => values
      .firstWhere((c) => c.name == valor.toLowerCase(), orElse: () => verde);
}

/// Referencia ya interpolada a la talla exacta del infante.
class ReferenciaInterpolada {
  const ReferenciaInterpolada({
    required this.tallaCm,
    required this.mediana,
    required this.de,
    required this.interpolada,
  });

  final double tallaCm;
  final double mediana;
  final double de;

  /// false si la talla coincidio exactamente con una fila de la tabla.
  final bool interpolada;

  @override
  String toString() =>
      'talla=${tallaCm.toStringAsFixed(1)} mediana=${mediana.toStringAsFixed(2)} '
      'de=${de.toStringAsFixed(2)} interpolada=$interpolada';
}

/// Resultado completo del tamizaje. Es un objeto puro (sin Flutter ni SQLite)
/// para que pueda testearse de forma aislada.
class ResultadoNutricional {
  const ResultadoNutricional({
    required this.zPesoTalla,
    required this.clasificacion,
    required this.recomendacion,
    required this.criterios,
    required this.referencia,
    required this.muacEvaluado,
    required this.edema,
  });

  final double zPesoTalla;
  final ClasificacionNutricional clasificacion;
  final String recomendacion;

  /// Explicacion de cada criterio aplicado (se muestra y se guarda).
  final List<String> criterios;

  final ReferenciaInterpolada referencia;

  /// false cuando el infante tiene menos de 6 meses (MUAC no aplica).
  final bool muacEvaluado;

  final bool edema;

  String get zTexto => zPesoTalla.toStringAsFixed(2);

  /// Texto compacto que se guarda en `evaluaciones.observacion`.
  String get observacion => criterios.join(' | ');
}

/// Motor de calculo del Z-score Peso/Talla y del semaforo nutricional.
///
/// No depende de Flutter ni de SQLite: recibe la tabla de referencia por
/// inyeccion, de modo que la tabla DEMO de este avance pueda reemplazarse por
/// la tabla OMS completa sin tocar la logica ni las pruebas.
class NutricionService {
  NutricionService(List<ReferenciaWho> referencias)
    : _referencias = List<ReferenciaWho>.unmodifiable(referencias) {
    if (_referencias.isEmpty) {
      throw ArgumentError('La tabla de referencia no puede estar vacia');
    }
  }

  final List<ReferenciaWho> _referencias;

  // Umbrales clinicos del tamizaje (ver especificacion del Avance 1).
  static const double zRojoSevero = -3.0;
  static const double zRojoModerado = -2.0;
  static const double zAmarillo = -1.0;

  static const double muacRojoCm = 11.5;
  static const double muacAmarilloCm = 12.5;
  static const int muacEdadMinimaMeses = 6;

  // Rangos aceptados de entrada (los mismos del formulario).
  static const double pesoMinKg = 0.5;
  static const double pesoMaxKg = 30.0;
  static const double tallaMinCm = 30.0;
  static const double tallaMaxCm = 130.0;
  static const double muacMinCm = 5.0;
  static const double muacMaxCm = 25.0;
  static const int edadMinMeses = 0;
  static const int edadMaxMeses = 59;

  /// Interpola linealmente mediana y DE segun sexo y talla.
  ///
  /// Si la talla cae fuera del rango tabulado se usa el extremo mas cercano
  /// (y se informa con [ReferenciaInterpolada.interpolada] = true), de modo
  /// que el calculo nunca falla por falta de una fila exacta.
  ReferenciaInterpolada referenciaPara({
    required String sexo,
    required double tallaCm,
  }) {
    final sexoNormalizado = sexo.toUpperCase();
    final filas =
        _referencias.where((r) => r.sexo == sexoNormalizado).toList()
          ..sort((a, b) => a.tallaCm.compareTo(b.tallaCm));

    if (filas.isEmpty) {
      throw StateError(
        'La tabla de referencia no contiene filas para el sexo "$sexoNormalizado"',
      );
    }

    if (filas.length == 1) {
      return ReferenciaInterpolada(
        tallaCm: tallaCm,
        mediana: filas.first.mediana,
        de: filas.first.de,
        interpolada: false,
      );
    }

    if (tallaCm <= filas.first.tallaCm) {
      return ReferenciaInterpolada(
        tallaCm: tallaCm,
        mediana: filas.first.mediana,
        de: filas.first.de,
        interpolada: tallaCm != filas.first.tallaCm,
      );
    }
    if (tallaCm >= filas.last.tallaCm) {
      return ReferenciaInterpolada(
        tallaCm: tallaCm,
        mediana: filas.last.mediana,
        de: filas.last.de,
        interpolada: tallaCm != filas.last.tallaCm,
      );
    }

    for (var i = 0; i < filas.length - 1; i++) {
      final inferior = filas[i];
      final superior = filas[i + 1];
      if (tallaCm < inferior.tallaCm || tallaCm > superior.tallaCm) continue;

      // Coincidencia exacta con un extremo: se devuelve la fila tal cual,
      // sin interpolar. Evita que un factor 1.0 introduzca error de coma
      // flotante justo en los bordes de clasificacion (Z = -2, Z = -1...).
      if (tallaCm == inferior.tallaCm) {
        return ReferenciaInterpolada(
          tallaCm: tallaCm,
          mediana: inferior.mediana,
          de: inferior.de,
          interpolada: false,
        );
      }
      if (tallaCm == superior.tallaCm) {
        return ReferenciaInterpolada(
          tallaCm: tallaCm,
          mediana: superior.mediana,
          de: superior.de,
          interpolada: false,
        );
      }

      final rango = superior.tallaCm - inferior.tallaCm;
      final factor = rango == 0 ? 0.0 : (tallaCm - inferior.tallaCm) / rango;
      return ReferenciaInterpolada(
        tallaCm: tallaCm,
        mediana:
            inferior.mediana + (superior.mediana - inferior.mediana) * factor,
        de: inferior.de + (superior.de - inferior.de) * factor,
        interpolada: true,
      );
    }

    // Inalcanzable por los guardas anteriores; se deja por seguridad.
    return ReferenciaInterpolada(
      tallaCm: tallaCm,
      mediana: filas.last.mediana,
      de: filas.last.de,
      interpolada: true,
    );
  }

  /// Calcula el Z-score Peso/Talla y clasifica el semaforo.
  ///
  /// Reglas (Avance 1):
  ///  - Edema bilateral presente => ROJO, sin importar el Z.
  ///  - Z < -3 => ROJO (desnutricion aguda severa).
  ///  - -3 <= Z < -2 => ROJO (desnutricion aguda moderada).
  ///  - -2 <= Z < -1 => AMARILLO (riesgo).
  ///  - Z >= -1 => VERDE (adecuado).
  ///  - MUAC solo si edad >= 6 meses: < 11.5 => ROJO, 11.5..12.5 => AMARILLO.
  ///    Se conserva el criterio mas grave entre Z y MUAC.
  ResultadoNutricional evaluar({
    required String sexo,
    required int edadMeses,
    required double pesoKg,
    required double tallaCm,
    required double muacCm,
    required bool edema,
    bool validarRangos = true,
  }) {
    if (validarRangos) _validarRangos(pesoKg, tallaCm, muacCm, edadMeses);

    final referencia = referenciaPara(sexo: sexo, tallaCm: tallaCm);
    if (referencia.de <= 0) {
      throw StateError('Desviacion estandar invalida (<= 0) en la tabla DEMO');
    }

    final z = (pesoKg - referencia.mediana) / referencia.de;

    final criterios = <String>[];
    // Se clasifica con el Z redondeado a 2 decimales (los mismos que se
    // muestran y se guardan). Sin esto, el error de coma flotante empuja
    // casos limite como -2.0000000000000009 a la categoria siguiente aunque
    // en pantalla se lea "-2.00".
    final porZ = _clasificarPorZ(_redondearZ(z));

    criterios.add(
      'P/T: ${pesoKg.toStringAsFixed(2)} kg con mediana '
      '${referencia.mediana.toStringAsFixed(2)} kg y DE '
      '${referencia.de.toStringAsFixed(2)} kg para '
      '${referencia.tallaCm.toStringAsFixed(1)} cm '
      '(${referencia.interpolada ? 'valor interpolado' : 'valor exacto de tabla'}).',
    );
    criterios.add('Z Peso/Talla = ${z.toStringAsFixed(2)} -> ${porZ.etiqueta}.');

    var clasificacion = porZ;
    var muacEvaluado = false;

    if (edadMeses >= muacEdadMinimaMeses) {
      muacEvaluado = true;
      final porMuac = _clasificarPorMuac(muacCm);
      criterios.add(
        'MUAC ${muacCm.toStringAsFixed(1)} cm -> ${porMuac.etiqueta} '
        '(aplica desde los $muacEdadMinimaMeses meses).',
      );
      if (porMuac.severidad > clasificacion.severidad) {
        clasificacion = porMuac;
      }
    } else {
      criterios.add(
        'MUAC no evaluado: el infante tiene $edadMeses meses '
        '(< $muacEdadMinimaMeses meses).',
      );
    }

    if (edema) {
      criterios.add('Edema bilateral presente -> ROJO (criterio independiente).');
      clasificacion = ClasificacionNutricional.rojo;
    }

    return ResultadoNutricional(
      zPesoTalla: z,
      clasificacion: clasificacion,
      recomendacion: recomendacionPara(clasificacion, edema: edema),
      criterios: criterios,
      referencia: referencia,
      muacEvaluado: muacEvaluado,
      edema: edema,
    );
  }

  /// Redondeo a 2 decimales para clasificar (misma precision que la UI).
  static double _redondearZ(double z) => (z * 100).roundToDouble() / 100;

  ClasificacionNutricional _clasificarPorZ(double z) {
    if (z < zRojoSevero) return ClasificacionNutricional.rojo;
    if (z < zRojoModerado) return ClasificacionNutricional.rojo;
    if (z < zAmarillo) return ClasificacionNutricional.amarillo;
    return ClasificacionNutricional.verde;
  }

  ClasificacionNutricional _clasificarPorMuac(double muacCm) {
    if (muacCm < muacRojoCm) return ClasificacionNutricional.rojo;
    if (muacCm <= muacAmarilloCm) return ClasificacionNutricional.amarillo;
    return ClasificacionNutricional.verde;
  }

  /// Recomendacion textual segun la clasificacion.
  ///
  /// Es estatica y publica porque las pantallas de historial y detalle solo
  /// tienen la evaluacion guardada (no el objeto de resultado completo).
  static String recomendacionPara(
    ClasificacionNutricional clasificacion, {
    required bool edema,
  }) {
    switch (clasificacion) {
      case ClasificacionNutricional.rojo:
        if (edema) {
          return 'Remisión inmediata al centro de salud: el edema bilateral es '
              'un signo de gravedad. Registrar el caso y acompañar a la familia '
              'hasta la valoración médica.';
        }
        return 'Remisión inmediata al centro de salud para valoración médica y '
            'nutricional. No iniciar tratamiento sin indicación profesional.';
      case ClasificacionNutricional.amarillo:
        return 'Agendar control nutricional en los próximos 7 días, reforzar '
            'consejería alimentaria con la familia y verificar acceso a agua '
            'segura y alimentos.';
      case ClasificacionNutricional.verde:
        return 'Mantener alimentación y controles de crecimiento habituales. '
            'Reforzar lactancia materna y alimentación complementaria.';
    }
  }

  void _validarRangos(
    double pesoKg,
    double tallaCm,
    double muacCm,
    int edadMeses,
  ) {
    if (pesoKg < pesoMinKg || pesoKg > pesoMaxKg) {
      throw ArgumentError.value(pesoKg, 'pesoKg', 'Fuera de rango (0.5 - 30 kg)');
    }
    if (tallaCm < tallaMinCm || tallaCm > tallaMaxCm) {
      throw ArgumentError.value(
        tallaCm,
        'tallaCm',
        'Fuera de rango (30 - 130 cm)',
      );
    }
    if (muacCm < muacMinCm || muacCm > muacMaxCm) {
      throw ArgumentError.value(muacCm, 'muacCm', 'Fuera de rango (5 - 25 cm)');
    }
    if (edadMeses < edadMinMeses || edadMeses > edadMaxMeses) {
      throw ArgumentError.value(
        edadMeses,
        'edadMeses',
        'Fuera de rango (0 - 59 meses)',
      );
    }
  }
}
