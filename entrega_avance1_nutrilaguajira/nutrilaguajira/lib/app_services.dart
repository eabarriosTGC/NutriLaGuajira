import 'data/db_nutrilaguajira.dart';
import 'data/models/nino.dart';
import 'data/repositorio.dart';
import 'services/nutricion_service.dart';

/// Localizador minimo de dependencias (sin paquetes externos).
///
/// Se inicializa una vez en `main()` y queda disponible para las pantallas.
class AppServices {
  AppServices._();

  static late final Repositorio repo;
  static late final NutricionService nutricion;

  static bool _iniciado = false;

  static Future<void> init() async {
    if (_iniciado) return;
    repo = Repositorio();
    // La tabla DEMO vive en SQLite: el motor se construye desde la base,
    // de modo que reemplazarla no requiere tocar la logica.
    final referencias = await repo.referencias();
    nutricion = NutricionService(referencias);
    _iniciado = true;
  }

  /// Cierra la base (usado por pruebas y por reinicios limpios).
  static Future<void> cerrar() async {
    await DbNutriLaGuajira.instance.cerrar();
    _iniciado = false;
  }
}

/// Sesion en memoria (login local del prototipo, sin persistencia).
class Sesion {
  Sesion._();

  static Usuario? usuario;

  static String get nombre => usuario?.nombre ?? 'Promotor(a)';

  static void cerrar() => usuario = null;
}
