import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/referencia_edad.dart';
import 'package:nutrilaguajira/services/referencias_edad_loader.dart';

/// Pruebas del parser/loader de la tabla por edad (LMS, DEMO).
void main() {
  late List<ReferenciaEdad> referencias;

  setUpAll(() {
    final csv = File('assets/who_edad_demo.csv').readAsStringSync();
    referencias = ReferenciasEdadLoader.desdeCsv(csv);
  });

  test('carga 240 filas (2 índices x 2 sexos x 60 meses)', () {
    expect(referencias.length, 240);
    expect(
      referencias
          .where((r) => r.indice == IndiceAntropometrico.tallaEdad)
          .length,
      120,
    );
    expect(
      referencias
          .where((r) => r.indice == IndiceAntropometrico.pesoEdad)
          .length,
      120,
    );
    expect(referencias.where((r) => r.sexo == 'M').length, 120);
    expect(referencias.where((r) => r.sexo == 'F').length, 120);
    expect(referencias.every((r) => r.m > 0 && r.s > 0), isTrue);
    expect(
      referencias.every((r) => r.edadMeses >= 0 && r.edadMeses <= 59),
      isTrue,
    );
  });

  test('los valores clave de 12 meses coinciden con la DEMO', () {
    final te = referencias.firstWhere(
      (r) =>
          r.indice == IndiceAntropometrico.tallaEdad &&
          r.sexo == 'M' &&
          r.edadMeses == 12,
    );
    final pe = referencias.firstWhere(
      (r) =>
          r.indice == IndiceAntropometrico.pesoEdad &&
          r.sexo == 'M' &&
          r.edadMeses == 12,
    );

    expect(te.l, 1.0);
    expect(te.m, closeTo(75.70, 0.001));
    expect(te.s, closeTo(0.03170, 1e-5));
    expect(te.s * te.m, closeTo(2.40, 1e-3));
    expect(pe.l, 1.0);
    expect(pe.m, closeTo(9.60, 0.001));
    expect(pe.s, closeTo(0.11458, 1e-5));
    expect(pe.s * pe.m, closeTo(1.10, 1e-3));
  });

  test('ignora comentarios, encabezado y filas inválidas', () {
    const csv = '''
# comentario
indice,sexo,edad_meses,l,m,s
T/E,M,12,1,75.7,2.4
P/E,F,0,1,3.2,0.4
X,M,10,1,1,1
T/E,Z,10,1,1,1
T/E,M,60,1,1,1
T/E,M,10,1,0,1
''';
    final filas = ReferenciasEdadLoader.desdeCsv(csv);

    expect(filas, hasLength(2));
    expect(filas.map((f) => f.indice).toSet(), {
      IndiceAntropometrico.tallaEdad,
      IndiceAntropometrico.pesoEdad,
    });
  });
}
