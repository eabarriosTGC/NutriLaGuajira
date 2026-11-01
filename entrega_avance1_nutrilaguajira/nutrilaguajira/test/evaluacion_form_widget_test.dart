import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/nino.dart';
import 'package:nutrilaguajira/screens/evaluacion_form_screen.dart';
import 'package:nutrilaguajira/theme/tema.dart';

/// Prueba de widget de las validaciones del formulario de evaluación.
///
/// No toca SQLite: los casos usados son inválidos, por lo que el guardado
/// nunca se ejecuta (el motor y la base se prueban en sus propios tests).
void main() {
  const pesoKey = Key('campo-peso');
  const tallaKey = Key('campo-talla');
  const muacKey = Key('campo-muac');
  const botonKey = Key('boton-calcular');

  Nino crearNino({required int mesesDeEdad}) => Nino(
    id: 1,
    nombres: 'Nino',
    apellidos: 'De Prueba',
    documento: 'TEST-1',
    fechaNacimiento: DateTime.now().subtract(Duration(days: mesesDeEdad * 30)),
    sexo: 'F',
    tutor: 'Tutor de Prueba',
    comunidad: 'Rancheria de Prueba',
  );

  Future<void> montar(WidgetTester tester, Nino nino) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light),
        home: EvaluacionFormScreen(nino: nino),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('campos vacíos muestran mensajes de obligatorio', (tester) async {
    await montar(tester, crearNino(mesesDeEdad: 18));

    await tester.ensureVisible(find.byKey(botonKey));
    await tester.tap(find.byKey(botonKey));
    await tester.pumpAndSettle();

    expect(find.text('El peso es obligatorio'), findsOneWidget);
    expect(find.text('La talla es obligatoria'), findsOneWidget);
    expect(find.text('El MUAC es obligatorio'), findsOneWidget);
  });

  testWidgets('rechaza peso negativo, talla imposible y MUAC fuera de rango', (
    tester,
  ) async {
    await montar(tester, crearNino(mesesDeEdad: 18));

    await tester.enterText(find.byKey(pesoKey), '-5');
    await tester.enterText(find.byKey(tallaKey), '200');
    await tester.enterText(find.byKey(muacKey), '2');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(botonKey));
    await tester.tap(find.byKey(botonKey));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('El peso debe estar entre 0.5 y 30 kg'),
      findsOneWidget,
    );
    expect(
      find.textContaining('La talla debe estar entre 30 y 130 cm'),
      findsOneWidget,
    );
    expect(
      find.textContaining('El MUAC debe estar entre 5 y 25 cm'),
      findsOneWidget,
    );
    // No debe navegar al resultado cuando hay errores.
    expect(find.text('Resultado del tamizaje'), findsNothing);
  });

  testWidgets('bloquea el cálculo si el infante tiene 60 meses o más', (
    tester,
  ) async {
    await montar(tester, crearNino(mesesDeEdad: 65));

    expect(
      find.textContaining('el tamizaje de este avance aplica solo de 0 a 59'),
      findsOneWidget,
    );
    final boton = tester.widget<FilledButton>(find.byKey(botonKey));
    expect(boton.onPressed, isNull);
  });

  testWidgets('acepta valores válidos en los campos numéricos', (tester) async {
    await montar(tester, crearNino(mesesDeEdad: 18));

    await tester.enterText(find.byKey(pesoKey), '9,5');
    await tester.enterText(find.byKey(tallaKey), '80');
    await tester.enterText(find.byKey(muacKey), '13');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(botonKey));
    await tester.tap(find.byKey(botonKey));
    await tester.pumpAndSettle();

    // Sin errores de validación visibles (el guardado no se ejecuta aquí
    // porque la prueba no inicializa la base de datos; se valida que el
    // formulario no marque los campos como inválidos).
    expect(find.textContaining('debe estar entre'), findsNothing);
    expect(find.textContaining('es obligatorio'), findsNothing);
  });
}
