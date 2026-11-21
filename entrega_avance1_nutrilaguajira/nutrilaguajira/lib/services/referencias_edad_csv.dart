import '../data/models/referencia_edad.dart';

/// Parser del CSV de referencia por edad (LMS).
///
/// Formato esperado: `indice,sexo,edad_meses,l,m,s`
/// (`indice` = T/E | P/E). Ignora líneas vacías, comentarios con `#` y el
/// encabezado. Es Dart puro para usarse en la app, los tests y herramientas.
class ReferenciasEdadCsv {
  ReferenciasEdadCsv._();

  static List<ReferenciaEdad> parsear(String contenido) {
    final filas = <ReferenciaEdad>[];
    for (final linea in contenido.split('\n')) {
      final limpia = linea.trim();
      if (limpia.isEmpty || limpia.startsWith('#')) continue;

      final partes = limpia.split(',');
      if (partes.length < 6) continue;

      final indice = IndiceAntropometrico.desdeClave(partes[0]);
      if (indice == null) continue; // salta el encabezado

      final sexo = partes[1].trim().toUpperCase();
      if (sexo != 'M' && sexo != 'F') continue;

      final edad = int.tryParse(partes[2].trim());
      final l = double.tryParse(partes[3].trim());
      final m = double.tryParse(partes[4].trim());
      final s = double.tryParse(partes[5].trim());

      if (edad == null ||
          edad < 0 ||
          edad > 59 ||
          l == null ||
          m == null ||
          s == null ||
          m <= 0 ||
          s <= 0) {
        continue;
      }

      filas.add(
        ReferenciaEdad(
          indice: indice,
          sexo: sexo,
          edadMeses: edad,
          l: l,
          m: m,
          s: s,
        ),
      );
    }

    filas.sort((a, b) {
      final porIndice = a.indice.clave.compareTo(b.indice.clave);
      if (porIndice != 0) return porIndice;
      final porSexo = a.sexo.compareTo(b.sexo);
      return porSexo != 0 ? porSexo : a.edadMeses.compareTo(b.edadMeses);
    });
    return filas;
  }
}
