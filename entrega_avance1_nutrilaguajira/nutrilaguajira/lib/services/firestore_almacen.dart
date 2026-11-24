import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_auth_service.dart';

/// Un documento remoto listo para escribir en Firestore.
///
/// [ruta] es la ruta completa del documento, por ejemplo
/// `promotores/<uid>/evaluaciones/<uuid>`. Se usa una ruta completa (y no una
/// colección + id) para poder escribir en un mismo lote documentos de
/// colecciones distintas.
class DocumentoNube {
  const DocumentoNube(this.ruta, this.datos);

  final String ruta;
  final Map<String, Object?> datos;

  @override
  String toString() => 'DocumentoNube($ruta)';
}

/// Contrato mínimo de escritura en la nube.
///
/// Abstraerlo permite probar la lógica de sincronización (lotes, marcado de
/// pendientes, errores) sin emulador ni credenciales de Firebase.
abstract class AlmacenNube {
  /// `true` si hay Firebase inicializado y sesión de Firebase Auth.
  bool get disponible;

  /// UID de Firebase que define la "carpeta" del promotor.
  String? get uid;

  /// Escribe los documentos en lotes atómicos (máx. 500 operaciones por lote).
  /// Debe lanzar una excepción si la escritura no se confirma.
  Future<void> guardarLote(List<DocumentoNube> documentos);
}

/// Implementación real sobre Cloud Firestore.
///
/// Usa `WriteBatch` y `set(..., merge: true)`, de modo que:
/// - cada lote se confirma completo o no se confirma;
/// - reintentar el mismo envío no duplica documentos (idempotente);
/// - si el SDK no puede alcanzar el servidor, la escritura queda en su cola
///   local y el error no tumba la app (la estrategia lo captura).
class FirestoreAlmacen implements AlmacenNube {
  FirestoreAlmacen({FirebaseFirestore? firestore, FirebaseAuthService? auth})
    : _firestoreInyectado = firestore,
      _auth = auth ?? FirebaseAuthService.instance;

  /// Firestore permite 500 escrituras por lote; dejamos margen.
  static const int tamanoLote = 400;

  /// Tiempo máximo por lote. Si la red es inestable (o un portal cautivo
  /// simula conectividad), se aborta el intento y los datos quedan pendientes
  /// para el siguiente ciclo en lugar de dejar la sincronización bloqueada.
  static const Duration tiempoMaximoLote = Duration(seconds: 30);

  final FirebaseFirestore? _firestoreInyectado;
  final FirebaseAuthService _auth;

  FirebaseFirestore get _firestore =>
      _firestoreInyectado ?? FirebaseFirestore.instance;

  @override
  bool get disponible => _auth.disponible && _auth.autenticadoEnFirebase;

  @override
  String? get uid => _auth.autenticadoEnFirebase ? _auth.uid : null;

  @override
  Future<void> guardarLote(List<DocumentoNube> documentos) async {
    if (documentos.isEmpty) return;

    for (var inicio = 0; inicio < documentos.length; inicio += tamanoLote) {
      final fin = math.min(inicio + tamanoLote, documentos.length);
      final bloque = documentos.sublist(inicio, fin);
      final batch = _firestore.batch();
      for (final documento in bloque) {
        batch.set(
          _firestore.doc(documento.ruta),
          _conSellos(documento.datos),
          SetOptions(merge: true),
        );
      }
      await batch.commit().timeout(tiempoMaximoLote);
    }
  }

  /// Agrega la marca de tiempo del servidor para resolver conflictos con
  /// "última escritura gana" y saber cuándo llegó el dato a la nube.
  Map<String, dynamic> _conSellos(Map<String, Object?> datos) => {
    ...Map<String, dynamic>.from(datos),
    'sincronizadoEn': FieldValue.serverTimestamp(),
  };
}
