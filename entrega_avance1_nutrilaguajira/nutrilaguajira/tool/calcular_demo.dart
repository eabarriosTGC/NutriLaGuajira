// Herramienta de apoyo (no forma parte de la app).
//
// Recalcula los casos semilla con el MISMO motor que usa la aplicación, para
// que la documentación del avance muestre valores que coinciden exactamente
// con lo que se ve en pantalla.
//
// Uso:
//   dart run tool/calcular_demo.dart
import 'dart:io';

import 'package:nutrilaguajira/services/nutricion_service.dart';
import 'package:nutrilaguajira/services/referencias_csv.dart';

void main() {
  final csv = File('assets/who_referencia_demo.csv').readAsStringSync();
  final servicio = NutricionService(ReferenciasCsv.parsear(csv));

  final casos = <List<Object>>[
    ['VERDE', 'Jose Angel (M, 11 meses)', 'M', 11, 9.5, 75.0, 13.5, false],
    ['AMARILLO', 'Yuliana Andrea (F, 18 meses)', 'F', 18, 8.7, 80.0, 12.2, false],
    ['ROJO por Z', 'Andres David (M, 24 meses)', 'M', 24, 8.8, 85.0, 12.0, false],
    ['ROJO por edema', 'Andres David (M, 25 meses)', 'M', 25, 12.0, 86.0, 12.4, true],
  ];

  stdout.writeln('=' * 96);
  stdout.writeln(
    'Casos semilla de NutriLaGuajira (tabla DEMO, no validación clínica)',
  );
  stdout.writeln('=' * 96);
  for (final caso in casos) {
    final resultado = servicio.evaluar(
      sexo: caso[2] as String,
      edadMeses: caso[3] as int,
      pesoKg: caso[4] as double,
      tallaCm: caso[5] as double,
      muacCm: caso[6] as double,
      edema: caso[7] as bool,
    );
    stdout.writeln('');
    stdout.writeln('[${caso[0]}] ${caso[1]}');
    stdout.writeln(
      '  peso=${(caso[4] as double).toStringAsFixed(2)} kg  '
      'talla=${(caso[5] as double).toStringAsFixed(1)} cm  '
      'MUAC=${(caso[6] as double).toStringAsFixed(1)} cm  '
      'edema=${caso[7]}',
    );
    stdout.writeln('  ${resultado.referencia}');
    stdout.writeln(
      '  Z Peso/Talla = ${resultado.zTexto}  =>  '
      '${resultado.clasificacion.etiqueta}',
    );
    for (final criterio in resultado.criterios) {
      stdout.writeln('   · $criterio');
    }
  }
  stdout.writeln('');
  stdout.writeln('=' * 96);
}
