import '../data/models/referencia_who.dart';

/// Parser del CSV de referencia Peso/Talla.
///
/// Es Dart puro (sin Flutter ni SQLite) para que el mismo código se use en la
/// app, en los tests y en la herramienta `tool/calcular_demo.dart`.
class ReferenciasCsv {
  ReferenciasCsv._();

  /// Formato esperado: `sexo,talla_cm,mediana,de`.
  /// Ignora lineas vacias y comentarios que empiezan con '#'.
  static List<ReferenciaWho> parsear(String contenido) {
    final filas = <ReferenciaWho>[];
    for (final linea in contenido.split('\n')) {
      final limpia = linea.trim();
      if (limpia.isEmpty || limpia.startsWith('#')) continue;
      final partes = limpia.split(',');
      if (partes.length < 4) continue;
      final sexo = partes[0].trim().toUpperCase();
      if (sexo != 'M' && sexo != 'F') continue; // salta el encabezado
      final talla = double.tryParse(partes[1].trim());
      final mediana = double.tryParse(partes[2].trim());
      final de = double.tryParse(partes[3].trim());
      if (talla == null || mediana == null || de == null || de <= 0) continue;
      filas.add(
        ReferenciaWho(sexo: sexo, tallaCm: talla, mediana: mediana, de: de),
      );
    }
    filas.sort((a, b) {
      final porSexo = a.sexo.compareTo(b.sexo);
      return porSexo != 0 ? porSexo : a.tallaCm.compareTo(b.tallaCm);
    });
    return filas;
  }
}
