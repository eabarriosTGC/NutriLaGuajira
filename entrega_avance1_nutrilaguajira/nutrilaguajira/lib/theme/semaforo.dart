import 'package:flutter/material.dart';

import '../services/nutricion_service.dart';

/// Colores y textos del semaforo nutricional.
///
/// Se eligieron tonos de alto contraste sobre texto blanco (rojo/verde) y
/// texto negro sobre amarillo, para que el resultado se lea a plena luz del
/// dia en campo.
class Semaforo {
  Semaforo._();

  static const Color rojo = Color(0xFFB3261E);
  static const Color amarillo = Color(0xFFF2A104);
  static const Color verde = Color(0xFF1B6B32);

  static Color fondo(ClasificacionNutricional clasificacion) {
    switch (clasificacion) {
      case ClasificacionNutricional.rojo:
        return rojo;
      case ClasificacionNutricional.amarillo:
        return amarillo;
      case ClasificacionNutricional.verde:
        return verde;
    }
  }

  /// Igual que [fondo] pero desde la clave persistida ('rojo'...).
  static Color fondoDesdeClave(String clave) =>
      fondo(ClasificacionNutricional.desdeClave(clave));

  static Color texto(ClasificacionNutricional clasificacion) =>
      clasificacion == ClasificacionNutricional.amarillo
      ? const Color(0xFF1A1A1A)
      : Colors.white;

  static Color textoDesdeClave(String clave) =>
      texto(ClasificacionNutricional.desdeClave(clave));

  static IconData icono(ClasificacionNutricional clasificacion) {
    switch (clasificacion) {
      case ClasificacionNutricional.rojo:
        return Icons.warning_rounded;
      case ClasificacionNutricional.amarillo:
        return Icons.error_outline_rounded;
      case ClasificacionNutricional.verde:
        return Icons.check_circle_outline_rounded;
    }
  }

  static IconData iconoDesdeClave(String clave) =>
      icono(ClasificacionNutricional.desdeClave(clave));
}
