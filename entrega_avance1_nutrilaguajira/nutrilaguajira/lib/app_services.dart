import 'data/db_nutrilaguajira.dart';
import 'data/models/nino.dart';
import 'data/repositorio.dart';
import 'services/alerta_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_strategy.dart';
import 'services/localizacion_service.dart';
import 'services/nutricion_service.dart';
import 'services/sms_intent_strategy.dart';
import 'services/sync_manager.dart';

/// Localizador minimo de dependencias (sin paquetes externos).
///
/// Se inicializa una vez en `main()` y queda disponible para las pantallas.
class AppServices {
  AppServices._();

  static late final Repositorio repo;
  static late final NutricionService nutricion;

  /// Servicio de GPS. Es mutable para que las pruebas puedan inyectar un stub.
  static LocalizacionService localizacion = LocalizacionService();

  /// Cola y envío de alertas (RF-10). Sigue usando SMS como canal principal;
  /// Firestore es una alternativa secundaria.
  static late final AlertaService alertas;

  /// Autenticación Firebase con respaldo offline.
  static late final FirebaseAuthService auth;

  /// Canal de sincronización SQLite -> Firestore.
  static late final FirestoreStrategy firestore;

  /// Sincronización automática (conectividad + contador de pendientes).
  static late final SyncManager sync;

  static bool _iniciado = false;

  static bool get listo => _iniciado;

  static Future<void> init() async {
    if (_iniciado) return;
    repo = Repositorio();
    // La tabla DEMO vive en SQLite: el motor se construye desde la base,
    // de modo que reemplazarla no requiere tocar la logica.
    final referencias = await repo.referencias();
    final referenciasEdad = await repo.referenciasEdad();
    nutricion = NutricionService(referencias, referenciasEdad: referenciasEdad);

    // Firebase es opcional: si falta google-services.json o no hay red, la
    // inicialización se registra en consola y la app sigue 100 % offline.
    auth = FirebaseAuthService.instance;
    await auth.inicializar();

    // El SMS sigue siendo el canal por defecto de la cola de alertas.
    alertas = AlertaService(repo: repo, estrategia: SmsIntentStrategy());
    firestore = FirestoreStrategy(repo: repo);
    sync = SyncManager(estrategia: firestore, repo: repo);

    _iniciado = true;
  }

  /// Cierra la base (usado por pruebas y por reinicios limpios).
  static Future<void> cerrar() async {
    if (_iniciado) {
      await sync.detener();
    }
    await DbNutriLaGuajira.instance.cerrar();
    _iniciado = false;
  }
}

/// Sesion en memoria. El UID permite construir la ruta `promotores/{uid}`.
class Sesion {
  Sesion._();

  static Usuario? usuario;

  /// UID de Firebase (`abc123...`) o `local:<usuario>` para la cuenta demo.
  static String? uid;

  /// `true` si el login de esta sesión se validó contra Firebase con red.
  static bool enLinea = false;

  static String get nombre => usuario?.nombre ?? 'Promotor(a)';

  /// `true` si las reglas de Firestore aceptarán las escrituras de esta sesión.
  static bool get esFirebase =>
      uid != null && !uid!.startsWith(FirebaseAuthService.prefijoUidLocal);

  static void aplicar(ResultadoAutenticacion resultado) {
    usuario = resultado.usuario;
    uid = resultado.uid;
    enLinea = resultado.enLinea;
  }

  static void cerrar() {
    usuario = null;
    uid = null;
    enLinea = false;
  }
}
