/// Utilidades de edad. Se mantienen fuera de las pantallas para poder
/// testearlas y para que el registro y la evaluacion usen la misma regla.
class Edad {
  Edad._();

  /// Meses completos cumplidos entre [nacimiento] y [referencia].
  ///
  /// Regla: se cuentan meses calendario y se descuenta uno si el dia de
  /// referencia es anterior al dia de nacimiento (mes no cumplido).
  static int enMeses(DateTime nacimiento, DateTime referencia) {
    var meses =
        (referencia.year - nacimiento.year) * 12 +
        (referencia.month - nacimiento.month);
    if (referencia.day < nacimiento.day) meses -= 1;
    return meses < 0 ? 0 : meses;
  }

  /// Texto legible: "18 meses", "1 año 6 meses".
  static String etiqueta(int meses) {
    if (meses < 12) return '$meses ${meses == 1 ? 'mes' : 'meses'}';
    final anios = meses ~/ 12;
    final resto = meses % 12;
    final textoAnios = '$anios ${anios == 1 ? 'año' : 'años'}';
    if (resto == 0) return textoAnios;
    return '$textoAnios $resto ${resto == 1 ? 'mes' : 'meses'}';
  }
}
