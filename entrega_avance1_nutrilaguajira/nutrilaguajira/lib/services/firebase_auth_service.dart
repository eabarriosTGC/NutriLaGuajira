import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/nino.dart';
import '../data/repositorio.dart';
import '../firebase_options.dart';

/// Resultado de un intento de inicio de sesión.
class ResultadoAutenticacion {
  const ResultadoAutenticacion({
    required this.exito,
    this.mensaje,
    this.enLinea = false,
    this.usuario,
    this.uid,
  });

  const ResultadoAutenticacion.fallo(this.mensaje)
    : exito = false,
      enLinea = false,
      usuario = null,
      uid = null;

  final bool exito;

  /// Texto para mostrar en la pantalla de login cuando algo falla.
  final String? mensaje;

  /// `true` si el login se validó contra Firebase con red disponible.
  final bool enLinea;

  final Usuario? usuario;
  final String? uid;
}

/// Autenticación con Firebase Auth con respaldo **offline-first**.
///
/// Estrategia:
/// 1. Si el identificador parece un correo, se intenta `signInWithEmailAndPassword`.
/// 2. Si no hay red (o Firebase no está configurado), se valida contra una
///    sesión guardada en `SharedPreferences` (correo + hash salado de la
///    contraseña). Así el promotor puede entrar en una ranchería sin señal.
/// 3. Si el identificador es un usuario local (por ejemplo la cuenta demo
///    `promotor`), se valida contra la tabla `usuarios` de SQLite.
///
/// El UID de Firebase se guarda localmente porque es la "carpeta" que usan
/// las reglas de seguridad: `promotores/{uid}/...`.
class FirebaseAuthService {
  FirebaseAuthService({Repositorio? repo}) : _repo = repo ?? Repositorio();

  /// Instancia compartida por la app (y por [FirestoreStrategy]).
  static final FirebaseAuthService instance = FirebaseAuthService();

  static const String _prefEmail = 'nl_firebase_email';
  static const String _prefUid = 'nl_firebase_uid';
  static const String _prefNombre = 'nl_firebase_nombre';
  static const String _prefSalt = 'nl_firebase_salt';
  static const String _prefHash = 'nl_firebase_hash';

  /// Sufijo de los usuarios locales (cuenta demo) que no existen en Firebase.
  static const String prefijoUidLocal = 'local:';

  final Repositorio _repo;

  bool _intentoInicializar = false;
  bool _disponible = false;
  String? _uid;
  String? _email;
  String? _nombre;

  /// `true` si `Firebase.initializeApp` terminó correctamente en este equipo.
  bool get disponible => _disponible;

  /// `true` si hay un UID utilizable (Firebase o local).
  bool get autenticado => _uid != null;

  /// `true` si la sesión activa es de Firebase Auth (requisito de las reglas).
  bool get autenticadoEnFirebase =>
      _uid != null && !_uid!.startsWith(prefijoUidLocal);

  String? get uid => _uid;
  String? get email => _email;
  String? get nombre => _nombre;

  /// Normaliza el identificador a correo. Los usuarios sin `@` (cuenta demo)
  /// se validan localmente y **no** se envían a Firebase.
  static String normalizarEmail(String identificador) =>
      identificador.trim().toLowerCase();

  /// Inicializa Firebase una sola vez. **Nunca lanza**: si falta
  /// `google-services.json`, la app sigue funcionando 100 % offline.
  Future<void> inicializar() async {
    if (_intentoInicializar) return;
    _intentoInicializar = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _disponible = true;

      // Persistencia offline de Firestore. En Android viene activa por
      // defecto; la fijamos explícitamente y sin bloquear el arranque.
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (_) {
        // Algunas plataformas (web) no permiten estos ajustes.
      }

      // Firebase Auth restaura la sesión desde disco aunque no haya red.
      final actual = FirebaseAuth.instance.currentUser;
      if (actual != null) {
        _uid = actual.uid;
        _email = actual.email;
        _nombre = actual.displayName?.trim().isNotEmpty == true
            ? actual.displayName
            : _nombreDesdeEmail(actual.email);
        await _guardarIdentidad(_uid!, _email, _nombre);
      }
    } catch (error) {
      _disponible = false;
      // Permite reintentar la inicialización en el próximo login.
      _intentoInicializar = false;
      _uid = null;
      _email = null;
      _nombre = null;
      debugPrint(
        '[NutriLaGuajira] Firebase no está disponible: $error\n'
        'Verifica que exista android/app/google-services.json y que el '
        'plugin com.google.gms.google-services esté aplicado. '
        'La app seguirá funcionando offline con SQLite.',
      );
    }
  }

  /// Intenta iniciar sesión. Nunca lanza: devuelve un [ResultadoAutenticacion].
  Future<ResultadoAutenticacion> iniciarSesion(
    String identificador,
    String clave,
  ) async {
    await inicializar();

    final limpio = identificador.trim();
    final pareceCorreo = limpio.contains('@');

    // La cuenta demo no existe en Firebase: se valida contra SQLite y se
    // identifica con un UID local. Sus datos no se sincronizan (las reglas
    // exigen un usuario autenticado de Firebase).
    if (!pareceCorreo) {
      final local = await _intentarLoginLocal(limpio, clave);
      if (local != null) return local;
      final guardada = await _conSesionGuardada(limpio, clave);
      if (guardada != null) return guardada;
      return const ResultadoAutenticacion.fallo(
        'Usuario o contraseña incorrectos',
      );
    }

    if (!_disponible) {
      final guardada = await _conSesionGuardada(limpio, clave);
      if (guardada != null) return guardada;
      return const ResultadoAutenticacion.fallo(
        'Sin conexión y no hay una sesión guardada en este dispositivo. '
        'Conéctate a Internet para iniciar sesión por primera vez.',
      );
    }

    try {
      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalizarEmail(limpio),
        password: clave,
      );
      final usuarioFirebase = credencial.user;
      if (usuarioFirebase == null) {
        return const ResultadoAutenticacion.fallo(
          'Firebase no devolvió un usuario. Intenta de nuevo.',
        );
      }

      _uid = usuarioFirebase.uid;
      _email = normalizarEmail(limpio);
      _nombre = usuarioFirebase.displayName?.trim().isNotEmpty == true
          ? usuarioFirebase.displayName
          : _nombreDesdeEmail(_email);

      await _guardarIdentidad(_uid!, _email, _nombre);
      await _guardarCredencialOffline(_email!, clave);

      return ResultadoAutenticacion(
        exito: true,
        enLinea: true,
        uid: _uid,
        usuario: Usuario(
          usuario: _email!,
          clave: '',
          nombre: _nombre ?? _email!,
        ),
      );
    } on FirebaseAuthException catch (error) {
      // Sin red o token caducado: se permite el acceso con la sesión guardada.
      if (_esErrorDeRed(error)) {
        final guardada = await _conSesionGuardada(limpio, clave);
        if (guardada != null) return guardada;
        return const ResultadoAutenticacion.fallo(
          'Sin conexión y no se pudo validar la sesión guardada. '
          'Verifica tu contraseña o conéctate a Internet.',
        );
      }
      return ResultadoAutenticacion.fallo(_mensajeError(error));
    } catch (error) {
      // Cualquier fallo inesperado (plugin, configuración…) no debe dejar al
      // promotor fuera de la app si ya había iniciado sesión antes.
      final guardada = await _conSesionGuardada(limpio, clave);
      if (guardada != null) return guardada;
      return ResultadoAutenticacion.fallo('No se pudo iniciar sesión: $error');
    }
  }

  /// Cierra la sesión de Firebase y borra la sesión local guardada.
  Future<void> cerrarSesion() async {
    try {
      if (_disponible && FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Best-effort: aunque falle la red, la sesión local se limpia igual.
    }

    _uid = null;
    _email = null;
    _nombre = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefUid);
      await prefs.remove(_prefNombre);
      await prefs.remove(_prefSalt);
      await prefs.remove(_prefHash);
    } catch (_) {
      // SharedPreferences puede no estar disponible en pruebas de escritorio.
    }
  }

  // ------------------------------------------------------------------ interno

  Future<ResultadoAutenticacion?> _intentarLoginLocal(
    String usuario,
    String clave,
  ) async {
    try {
      final local = await _repo.autenticar(usuario, clave);
      if (local == null) return null;
      _uid = '$prefijoUidLocal${local.usuario}';
      _email = null;
      _nombre = local.nombre;
      return ResultadoAutenticacion(
        exito: true,
        enLinea: false,
        uid: _uid,
        usuario: local,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ResultadoAutenticacion?> _conSesionGuardada(
    String identificador,
    String clave,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_prefEmail);
      final uid = prefs.getString(_prefUid);
      final salt = prefs.getString(_prefSalt);
      final hash = prefs.getString(_prefHash);
      final nombre = prefs.getString(_prefNombre);

      if (email == null || uid == null || salt == null || hash == null) {
        return null;
      }
      if (email.toLowerCase() != identificador.trim().toLowerCase()) {
        return null;
      }
      if (_hash(clave, salt) != hash) return null;

      _uid = uid;
      _email = email;
      _nombre = nombre;
      return ResultadoAutenticacion(
        exito: true,
        enLinea: false,
        uid: uid,
        usuario: Usuario(
          usuario: email,
          clave: '',
          nombre: nombre ?? _nombreDesdeEmail(email) ?? email,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _guardarIdentidad(
    String uid,
    String? email,
    String? nombre,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUid, uid);
      if (email != null) await prefs.setString(_prefEmail, email);
      if (nombre != null) await prefs.setString(_prefNombre, nombre);
    } catch (_) {
      // No es crítico: Firebase Auth ya persistió la sesión.
    }
  }

  Future<void> _guardarCredencialOffline(String email, String clave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salt = _generarSalt();
      await prefs.setString(_prefEmail, email);
      await prefs.setString(_prefSalt, salt);
      await prefs.setString(_prefHash, _hash(clave, salt));
    } catch (_) {
      // Sin SharedPreferences no hay login offline, pero el online funciona.
    }
  }

  static String _generarSalt() {
    final aleatorio = Random.secure();
    final bytes = List<int>.generate(16, (_) => aleatorio.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// SHA-256 salado. No se guarda la contraseña en claro en ningún momento.
  static String _hash(String clave, String salt) =>
      sha256.convert(utf8.encode('$salt|$clave')).toString();

  static String? _nombreDesdeEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final parte = email.split('@').first;
    return parte.isEmpty ? email : parte;
  }

  static bool _esErrorDeRed(FirebaseAuthException error) {
    const codigos = <String>{
      'network-request-failed',
      'timeout',
      'web-context-canceled',
      'internal-error',
    };
    return codigos.contains(error.code);
  }

  static String _mensajeError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada. Contacta al administrador.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo no está habilitado en Firebase.';
      default:
        return 'No se pudo iniciar sesión (${error.code}).';
    }
  }
}
