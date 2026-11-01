import '../../services/edad.dart';

/// Infante menor de 5 años registrado por el promotor de salud.
class Nino {
  const Nino({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.documento,
    required this.fechaNacimiento,
    required this.sexo,
    required this.tutor,
    required this.comunidad,
    this.createdAt,
  });

  final int? id;
  final String nombres;
  final String apellidos;
  final String documento;
  final DateTime fechaNacimiento;

  /// 'M' = masculino, 'F' = femenino.
  final String sexo;
  final String tutor;
  final String comunidad;
  final DateTime? createdAt;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  String get sexoEtiqueta => sexo == 'F' ? 'Femenino' : 'Masculino';

  int get edadMeses => Edad.enMeses(fechaNacimiento, DateTime.now());

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'nombres': nombres,
    'apellidos': apellidos,
    'documento': documento,
    'fecha_nacimiento': fechaNacimiento.toIso8601String(),
    'sexo': sexo,
    'tutor': tutor,
    'comunidad': comunidad,
    'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory Nino.fromMap(Map<String, Object?> map) => Nino(
    id: map['id'] as int?,
    nombres: map['nombres'] as String,
    apellidos: map['apellidos'] as String,
    documento: map['documento'] as String,
    fechaNacimiento: DateTime.parse(map['fecha_nacimiento'] as String),
    sexo: (map['sexo'] as String).toUpperCase(),
    tutor: map['tutor'] as String,
    comunidad: map['comunidad'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Nino copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? documento,
    DateTime? fechaNacimiento,
    String? sexo,
    String? tutor,
    String? comunidad,
  }) => Nino(
    id: id ?? this.id,
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    documento: documento ?? this.documento,
    fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
    sexo: sexo ?? this.sexo,
    tutor: tutor ?? this.tutor,
    comunidad: comunidad ?? this.comunidad,
    createdAt: createdAt,
  );
}

/// Usuario local (login simple, sin seguridad real, solo para el prototipo).
class Usuario {
  const Usuario({
    this.id,
    required this.usuario,
    required this.clave,
    required this.nombre,
  });

  final int? id;
  final String usuario;
  final String clave;
  final String nombre;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'usuario': usuario,
    'clave': clave,
    'nombre': nombre,
  };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
    id: map['id'] as int?,
    usuario: map['usuario'] as String,
    clave: map['clave'] as String,
    nombre: map['nombre'] as String,
  );
}
