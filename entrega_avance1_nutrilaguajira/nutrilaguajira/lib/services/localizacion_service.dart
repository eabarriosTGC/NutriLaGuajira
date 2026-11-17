import 'package:geolocator/geolocator.dart';

/// Coordenada geográfica en grados decimales (WGS84).
class Coordenada {
  const Coordenada({required this.lat, required this.lng});

  final double lat;
  final double lng;

  /// Texto legible para mostrar en pantalla y guardar en reportes.
  String get texto => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  @override
  String toString() => 'Coordenada($texto)';
}

/// Obtiene la ubicación actual del dispositivo vía GPS/red.
///
/// Es un wrapper delgado de `geolocator` para poder reemplazarlo en pruebas.
/// La captura es **de mejor esfuerzo**: si el permiso está denegado, el GPS
/// está apagado o la lectura falla, devuelve `null` y el tamizaje se guarda
/// igualmente sin coordenadas (en zonas rurales no siempre hay señal).
class LocalizacionService {
  /// Devuelve la coordenada actual o `null` si no fue posible obtenerla.
  Future<Coordenada?> obtenerCoordenada() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }

      // 1) Posición actual con alta precisión (usa el GPS del equipo).
      try {
        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          ),
        );
        return Coordenada(lat: posicion.latitude, lng: posicion.longitude);
      } catch (_) {
        // 2) Sin señal o tiempo agotado: última posición conocida del equipo.
        final ultima = await Geolocator.getLastKnownPosition();
        if (ultima != null) {
          return Coordenada(lat: ultima.latitude, lng: ultima.longitude);
        }
        return null;
      }
    } catch (_) {
      // Cualquier fallo (sin plugin en pruebas, sin señal, timeout...) se
      // traduce en "sin coordenadas" para no bloquear el guardado.
      return null;
    }
  }
}
