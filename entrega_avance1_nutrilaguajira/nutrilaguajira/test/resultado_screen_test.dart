import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion.dart';
import 'package:nutrilaguajira/screens/resultado_screen.dart';
import 'package:nutrilaguajira/services/nutricion_service.dart';
import 'package:nutrilaguajira/theme/tema.dart';

/// Verifica que el resultado muestre T/E y P/E además del P/T.
void main() {
  testWidgets('el resultado muestra Z Talla/Edad y Z Peso/Edad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final evaluacion = Evaluacion(
      ninoId: 1,
      fecha: DateTime(2026, 11, 21, 10),
      edadMeses: 12,
      pesoKg: 9.6,
      tallaCm: 75.7,
      muacCm: 13.5,
      edema: false,
      zPesoTalla: 0.32,
      zTallaEdad: -1.25,
      zPesoEdad: -0.80,
      clasificacion: 'VERDE',
      color: 'verde',
      observacion: 'ok',
      ninoNombre: 'Andrés David Jusayú González',
      comunidad: 'Ranchería Bahía Honda',
    );
    const resultado = ResultadoNutricional(
      zPesoTalla: 0.32,
      clasificacion: ClasificacionNutricional.verde,
      recomendacion: 'Mantener controles.',
      criterios: ['P/T: ...', 'T/E: ...', 'P/E: ...'],
      referencia: ReferenciaInterpolada(
        tallaCm: 75.7,
        mediana: 9.34,
        de: 0.96,
        interpolada: true,
      ),
      muacEvaluado: true,
      edema: false,
      zTallaEdad: -1.25,
      zPesoEdad: -0.80,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light),
        home: ResultadoScreen(evaluacion: evaluacion, resultado: resultado),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Z Talla/Edad'), findsOneWidget);
    expect(find.text('Z Peso/Edad'), findsOneWidget);
    expect(find.text('-1.25'), findsOneWidget);
    expect(find.text('-0.80'), findsOneWidget);
  });
}
