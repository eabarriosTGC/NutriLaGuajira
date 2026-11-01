import 'edad.dart';

/// Validaciones de formulario del Avance 1.
///
/// Se aislaron de las pantallas para poder probarlas con tests unitarios y
/// para que el registro de infantes y el formulario de evaluacion compartan
/// exactamente las mismas reglas.
class Validadores {
  Validadores._();

  static const double pesoMinKg = 0.5;
  static const double pesoMaxKg = 30.0;
  static const double tallaMinCm = 30.0;
  static const double tallaMaxCm = 130.0;
  static const double muacMinCm = 5.0;
  static const double muacMaxCm = 25.0;
  static const int edadMinMeses = 0;
  static const int edadMaxMeses = 59;

  /// Acepta coma o punto como separador decimal ("9,5" y "9.5").
  static double? parseNumero(String? valor) {
    if (valor == null) return null;
    final limpio = valor.trim().replaceAll(',', '.');
    if (limpio.isEmpty) return null;
    return double.tryParse(limpio);
  }

  static String? obligatorio(String? valor, {String campo = 'Este campo'}) {
    if (valor == null || valor.trim().isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  static String? numeroEnRango(
    String? valor, {
    required String campo,
    required double min,
    required double max,
    required String unidad,
    bool femenino = false,
  }) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return '$campo es ${femenino ? 'obligatoria' : 'obligatorio'}';
    }
    final numero = parseNumero(texto);
    if (numero == null) return 'Ingrese un número válido';
    if (numero < min || numero > max) {
      return '$campo debe estar entre ${_corto(min)} y ${_corto(max)} $unidad';
    }
    return null;
  }

  static String? peso(String? valor) => numeroEnRango(
    valor,
    campo: 'El peso',
    min: pesoMinKg,
    max: pesoMaxKg,
    unidad: 'kg',
  );

  static String? talla(String? valor) => numeroEnRango(
    valor,
    campo: 'La talla',
    min: tallaMinCm,
    max: tallaMaxCm,
    unidad: 'cm',
    femenino: true,
  );

  static String? muac(String? valor) => numeroEnRango(
    valor,
    campo: 'El MUAC',
    min: muacMinCm,
    max: muacMaxCm,
    unidad: 'cm',
  );

  /// Edad en meses fuera del rango del tamizaje (0 a 59 meses completos).
  static String? edadMeses(int meses, {DateTime? nacimiento}) {
    if (meses < edadMinMeses || meses > edadMaxMeses) {
      final detalle = nacimiento == null
          ? ''
          : ' (registrado: ${Edad.etiqueta(meses)})';
      return 'La edad debe estar entre $edadMinMeses y $edadMaxMeses meses'
          ' para este tamizaje$detalle';
    }
    return null;
  }

  /// Fecha de nacimiento: obligatoria, no futura y menor de 5 años.
  static String? fechaNacimiento(DateTime? fecha, {DateTime? hoy}) {
    if (fecha == null) return 'La fecha de nacimiento es obligatoria';
    final referencia = hoy ?? DateTime.now();
    final diaNacimiento = DateTime(fecha.year, fecha.month, fecha.day);
    final diaHoy = DateTime(referencia.year, referencia.month, referencia.day);
    if (diaNacimiento.isAfter(diaHoy)) {
      return 'La fecha de nacimiento no puede ser futura';
    }
    final meses = Edad.enMeses(diaNacimiento, diaHoy);
    if (meses > edadMaxMeses) {
      return 'El infante debe tener menos de 60 meses '
          '(registrado: ${Edad.etiqueta(meses)})';
    }
    return null;
  }

  static String _corto(double valor) {
    return valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
  }
}
