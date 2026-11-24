import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstracción mínima sobre el estado de red, inyectable en pruebas.
///
/// Importante: `connectivity_plus` informa el estado de la radio (Wi-Fi, datos
/// móviles…), no si Internet es realmente alcanzable. Por eso la sincronización
/// trata cualquier fallo de Firestore como "sin red" y deja los datos
/// pendientes para el siguiente intento.
abstract class Conectividad {
  Future<bool> hayRed();

  Stream<bool> cambios();
}

/// Implementación real con `connectivity_plus`.
class ConectividadPlus implements Conectividad {
  ConectividadPlus({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _tieneRed(List<ConnectivityResult> resultados) =>
      resultados.any((resultado) => resultado != ConnectivityResult.none);

  @override
  Future<bool> hayRed() async {
    try {
      return _tieneRed(await _connectivity.checkConnectivity());
    } catch (_) {
      // Si el plugin falla (por ejemplo, en escritorio) asumimos offline: la
      // app sigue operando con SQLite y no se pierde ningún dato.
      return false;
    }
  }

  @override
  Stream<bool> cambios() => _connectivity.onConnectivityChanged
      .map(_tieneRed)
      .handleError((Object _) {});
}
