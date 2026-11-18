import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion_reporte.dart';
import 'package:nutrilaguajira/data/models/resumen_zona.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/screens/zonas_riesgo_screen.dart';
import 'package:nutrilaguajira/theme/tema.dart';

class _RepoZonasFalso extends Repositorio {
  _RepoZonasFalso({required this.resumenes, required this.evaluaciones});

  final List<ResumenZona> resumenes;
  final List<EvaluacionReporte> evaluaciones;

  @override
  Future<List<ResumenZona>> resumenPorRancheria({DateTime? desde}) async {
    if (desde == null) return List.of(resumenes);
    return resumenes.where((z) => !z.ultimaFecha.isBefore(desde)).toList();
  }

  @override
  Future<List<EvaluacionReporte>> evaluacionesParaReporte() async =>
      List.of(evaluaciones);
}

void main() {
  ResumenZona zona(
    String nombre, {
    int rojos = 0,
    int amarillos = 0,
    int verdes = 0,
    DateTime? ultima,
    double? lat,
    double? lng,
  }) => ResumenZona(
    rancheria: nombre,
    rojos: rojos,
    amarillos: amarillos,
    verdes: verdes,
    total: rojos + amarillos + verdes,
    ultimaFecha: ultima ?? DateTime(2026, 11, 17),
    latitudCritico: lat,
    longitudCritico: lng,
  );

  EvaluacionReporte evaluacion({
    required int id,
    required String rancheria,
    String color = 'rojo',
    String clasificacion = 'ROJO',
    double? lat,
    double? lng,
    String nombres = 'Andrés David',
    String apellidos = 'Jusayú González',
  }) => EvaluacionReporte(
    idEvaluacion: id,
    idInfante: id,
    nombres: nombres,
    apellidos: apellidos,
    fechaNacimiento: DateTime(2024, 9, 15),
    sexo: 'M',
    rancheria: rancheria,
    fechaEvaluacion: DateTime(2026, 11, 17, 19, id),
    pesoKg: 8.8,
    tallaCm: 85,
    perimetroBraquialCm: 12,
    edema: false,
    zPesoTalla: -2.27,
    clasificacionNutricional: clasificacion,
    color: color,
    latitud: lat,
    longitud: lng,
  );

  Future<void> montar(
    WidgetTester tester, {
    required _RepoZonasFalso repo,
    DateTime? desdeInicial,
    Future<void> Function(String texto)? alCopiar,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: construirTema(Brightness.light),
        home: ZonasRiesgoScreen(
          repo: repo,
          desdeInicial: desdeInicial,
          alCopiar: alCopiar,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el estado vacío sin evaluaciones', (tester) async {
    final repo = _RepoZonasFalso(resumenes: const [], evaluaciones: const []);
    await montar(tester, repo: repo);

    expect(
      find.textContaining('No hay evaluaciones registradas'),
      findsOneWidget,
    );
  });

  testWidgets('ordena las rancherías por criticidad (rojos DESC)', (
    tester,
  ) async {
    final repo = _RepoZonasFalso(
      resumenes: [
        zona('Ranchería C', verdes: 1),
        zona('Ranchería A', rojos: 2, verdes: 1),
        zona('Ranchería B', rojos: 1, amarillos: 1),
      ],
      evaluaciones: const [],
    );
    await montar(tester, repo: repo);

    final yA = tester.getTopLeft(find.text('Ranchería A')).dy;
    final yB = tester.getTopLeft(find.text('Ranchería B')).dy;
    final yC = tester.getTopLeft(find.text('Ranchería C')).dy;

    expect(yA, lessThan(yB));
    expect(yB, lessThan(yC));
  });

  testWidgets('al tocar una ranchería muestra sus infantes ROJOS', (
    tester,
  ) async {
    final repo = _RepoZonasFalso(
      resumenes: [zona('Ranchería A', rojos: 2)],
      evaluaciones: [
        evaluacion(id: 1, rancheria: 'Ranchería A'),
        evaluacion(id: 2, rancheria: 'Ranchería A'),
      ],
    );
    await montar(tester, repo: repo);

    await tester.tap(find.text('Ranchería A'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Andrés David'), findsNWidgets(2));
  });

  testWidgets('al tocar las coordenadas las copia y muestra SnackBar', (
    tester,
  ) async {
    String? copiado;
    final repo = _RepoZonasFalso(
      resumenes: [zona('Ranchería A', rojos: 1, lat: 11.24712, lng: -72.98765)],
      evaluaciones: [
        evaluacion(
          id: 1,
          rancheria: 'Ranchería A',
          lat: 11.24712,
          lng: -72.98765,
        ),
      ],
    );
    await montar(
      tester,
      repo: repo,
      alCopiar: (texto) async => copiado = texto,
    );

    await tester.tap(find.text('Ranchería A'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('11.24712, -72.98765'));
    await tester.pumpAndSettle();

    expect(copiado, '11.24712, -72.98765');
    expect(find.text('Coordenadas copiadas'), findsOneWidget);
  });

  testWidgets('el filtro desde posterior a la última evaluación deja vacío', (
    tester,
  ) async {
    final repo = _RepoZonasFalso(
      resumenes: [zona('Ranchería A', rojos: 1, ultima: DateTime(2026, 1, 1))],
      evaluaciones: const [],
    );
    await montar(tester, repo: repo, desdeInicial: DateTime(2030, 1, 1));

    expect(
      find.textContaining('No hay evaluaciones registradas'),
      findsOneWidget,
    );
  });
}
