import 'package:flutter/services.dart' show rootBundle;

import '../data/models/referencia_edad.dart';
import 'referencias_edad_csv.dart';

/// Carga la tabla de referencia por edad (LMS) desde el CSV de assets.
///
/// El asset actual es **DEMO** (`who_edad_demo.csv`). Reemplazarlo por las
/// tablas OMS oficiales (mismo formato LMS) no requiere tocar el motor.
class ReferenciasEdadLoader {
  ReferenciasEdadLoader._();

  static const String rutaAsset = 'assets/who_edad_demo.csv';

  static Future<List<ReferenciaEdad>> cargarDesdeAssets() async {
    final contenido = await rootBundle.loadString(rutaAsset);
    return ReferenciasEdadCsv.parsear(contenido);
  }

  static List<ReferenciaEdad> desdeCsv(String contenido) =>
      ReferenciasEdadCsv.parsear(contenido);
}
