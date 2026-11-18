/// Estado de una alerta en la cola local (RF-10).
///
/// Se persiste con [clave] (PENDIENTE/ENVIADA/FALLIDA), en mayúsculas, igual que
/// las demás columnas de estado del esquema.
enum EstadoAlerta {
  pendiente('PENDIENTE', 'Pendiente'),
  enviada('ENVIADA', 'Enviada'),
  fallida('FALLIDA', 'Fallida');

  const EstadoAlerta(this.clave, this.etiqueta);

  final String clave;
  final String etiqueta;

  static EstadoAlerta desdeClave(String valor) => values.firstWhere(
    (estado) => estado.clave == valor.toUpperCase(),
    orElse: () => pendiente,
  );
}

/// Alerta de desnutrición aguda encolada para envío diferido por SMS.
///
/// El envío real se hace con un `intent` de SMS (sin permiso SEND_SMS); por eso
/// la alerta se guarda localmente con el mensaje ya pre-armado y su estado.
class AlertaPendiente {
  const AlertaPendiente({
    this.id,
    required this.idInfante,
    required this.idEvaluacion,
    required this.severidad,
    this.latitud,
    this.longitud,
    required this.fechaCreacion,
    this.estado = EstadoAlerta.pendiente,
    required this.mensaje,
    this.fechaEnvio,
    this.nombreInfante,
    this.rancheria,
  });

  final int? id;
  final int idInfante;
  final int idEvaluacion;

  /// Por ahora 'ROJO'.
  final String severidad;

  final double? latitud;
  final double? longitud;
  final DateTime fechaCreacion;
  final EstadoAlerta estado;

  /// Cuerpo del SMS pre-armado.
  final String mensaje;

  /// Cuándo se lanzó el intent de SMS (nullable).
  final DateTime? fechaEnvio;

  /// Solo se completan cuando la alerta viene de un JOIN con `ninos`.
  final String? nombreInfante;
  final String? rancheria;

  bool get tieneUbicacion => latitud != null && longitud != null;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'id_infante': idInfante,
    'id_evaluacion': idEvaluacion,
    'severidad': severidad,
    'latitud': latitud,
    'longitud': longitud,
    'fecha_creacion': fechaCreacion.toIso8601String(),
    'estado': estado.clave,
    'mensaje': mensaje,
    'fecha_envio': fechaEnvio?.toIso8601String(),
  };

  factory AlertaPendiente.fromMap(Map<String, Object?> map) => AlertaPendiente(
    id: map['id'] as int?,
    idInfante: map['id_infante'] as int,
    idEvaluacion: map['id_evaluacion'] as int,
    severidad: map['severidad'] as String,
    latitud: (map['latitud'] as num?)?.toDouble(),
    longitud: (map['longitud'] as num?)?.toDouble(),
    fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    estado: EstadoAlerta.desdeClave(map['estado'] as String),
    mensaje: map['mensaje'] as String,
    fechaEnvio: map['fecha_envio'] == null
        ? null
        : DateTime.parse(map['fecha_envio'] as String),
    nombreInfante: map['nombre_infante'] as String?,
    rancheria: map['rancheria'] as String?,
  );

  AlertaPendiente copyWith({
    int? id,
    EstadoAlerta? estado,
    DateTime? fechaEnvio,
    String? nombreInfante,
    String? rancheria,
  }) => AlertaPendiente(
    id: id ?? this.id,
    idInfante: idInfante,
    idEvaluacion: idEvaluacion,
    severidad: severidad,
    latitud: latitud,
    longitud: longitud,
    fechaCreacion: fechaCreacion,
    estado: estado ?? this.estado,
    mensaje: mensaje,
    fechaEnvio: fechaEnvio ?? this.fechaEnvio,
    nombreInfante: nombreInfante ?? this.nombreInfante,
    rancheria: rancheria ?? this.rancheria,
  );

  @override
  String toString() =>
      'AlertaPendiente(#$id, infante=$idInfante, estado=${estado.clave})';
}
