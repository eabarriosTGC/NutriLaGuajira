import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/screens/historial_screen.dart';
import 'package:nutrilaguajira/theme/tema.dart';

/// Repositorio falso: en la 2.ª llamada devuelve un registro más.
class _RepoHistorialFalso extends Repositorio {
  int llamadas = 0;

  @override
  Future<List<Evaluacion>> historial({int? ninoId}) async {
    llamadas++;
    if (llamadas == 1) return [_evaluacion(1)];
    return [_evaluacion(1), _evaluacion(2)];
  }
}

Evaluacion _evaluacion(int id) => Evaluacion(
  id: id,
  ninoId: id,
  fecha: DateTime(2026, 11, 21, 10, id),
  edadMeses: 12,
  pesoKg: 9.5,
  tallaCm: 75,
  muacCm: 13.5,
  edema: false,
  zPesoTalla: 0.32,
  zTallaEdad: -1.2,
  zPesoEdad: -0.8,
  clasificacion: 'VERDE',
  color: 'verde',
  observacion: 'ok',
  ninoNombre: 'Infante $id',
  comunidad: 'Ranchería A',
);

void main() {
  testWidgets('Actualizar no lanza error de setState y refresca la lista', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _RepoHistorialFalso();
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light),
        home: HistorialScreen(repo: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Infante 1'), findsOneWidget);
    expect(find.text('Infante 2'), findsNothing);

    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Infante 1'), findsOneWidget);
    expect(find.text('Infante 2'), findsOneWidget);
  });
}
