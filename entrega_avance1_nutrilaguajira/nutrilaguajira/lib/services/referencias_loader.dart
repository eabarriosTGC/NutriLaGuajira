import 'package:flutter/services.dart' show rootBundle;

import '../data/models/referencia_who.dart';
import 'referencias_csv.dart';

/// Carga la tabla de referencia Peso/Talla desde el CSV de assets.
///
/// El parseo vive en [ReferenciasCsv] (Dart puro); aqui solo se resuelve el
/// acceso al asset, de modo que el mismo parser se use en la app, en los
/// tests y en la herramienta de verificación de la tabla.
class ReferenciasLoader {
  ReferenciasLoader._();

  static const String rutaAsset = 'assets/who_referencia_demo.csv';

  static Future<List<ReferenciaWho>> cargarDesdeAssets() async {
    final contenido = await rootBundle.loadString(rutaAsset);
    return ReferenciasCsv.parsear(contenido);
  }

  static List<ReferenciaWho> desdeCsv(String contenido) =>
      ReferenciasCsv.parsear(contenido);
}
