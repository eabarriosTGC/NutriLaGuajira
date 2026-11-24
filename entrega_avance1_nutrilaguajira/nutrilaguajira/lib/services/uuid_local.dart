import 'dart:math';

final Random _aleatorio = Random.secure();

/// Genera un identificador local apto como id de documento de Firestore.
///
/// Formato: `prefijo-<microsegundos en hex>-<16 hex aleatorios>`. No usa el
/// paquete `uuid` para no sumar una dependencia: la combinación de reloj y
/// [Random.secure] basta para un prototipo (y evita colisiones entre
/// dispositivos distintos, a diferencia del id autoincremental de SQLite).
String generarUuidLocal([String prefijo = '']) {
  final marca = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(_aleatorio.nextInt(16).toRadixString(16));
  }
  final base = '$marca-$buffer';
  return prefijo.isEmpty ? base : '$prefijo-$base';
}
