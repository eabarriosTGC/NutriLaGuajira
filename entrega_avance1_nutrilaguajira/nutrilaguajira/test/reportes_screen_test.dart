import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion_reporte.dart';
import 'package:nutrilaguajira/data/repositorio.dart';
import 'package:nutrilaguajira/screens/reportes_screen.dart';
import 'package:nutrilaguajira/services/reporte_csv_service.dart';
import 'package:nutrilaguajira/theme/tema.dart';

/// Repositorio falso: no toca SQLite, solo devuelve los datos de prueba.
class _RepoFalso extends Repositorio {
  _RepoFalso({
    this.listaComunidades = const <String>[],
    this.listaEvaluaciones = const <EvaluacionReporte>[],
  });

  final List<String> listaComunidades;
  final List<EvaluacionReporte> listaEvaluaciones;

  @override
  Future<List<String>> comunidades() async => listaComunidades;

  @override
  Future<List<EvaluacionReporte>> evaluacionesParaReporte() async =>
      listaEvaluaciones;
}

/// Servicio CSV falso: registra la llamada y devuelve una ruta ficticia sin
/// tocar el disco (el fake async de `testWidgets` no completa I/O real).
class _CsvFalso extends ReporteCsvService {
  int vecesGuardado = 0;
  String? ultimoNombre;
  String? ultimoCsv;

  @override
  Future<File> guardar(String csv, String nombreArchivo) async {
    vecesGuardado++;
    ultimoNombre = nombreArchivo;
    ultimoCsv = csv;
    return File('/fake/exports/$nombreArchivo');
  }
}

void main() {
  EvaluacionReporte evaluacion({DateTime? fecha}) => EvaluacionReporte(
    idEvaluacion: 1,
    idInfante: 1,
    nombres: 'Jose',
    apellidos: 'Epieyu',
    fechaNacimiento: DateTime(2025, 1, 1),
    sexo: 'M',
    rancheria: 'Rancheria A',
    fechaEvaluacion: fecha ?? DateTime(2026, 1, 15, 10, 30),
    pesoKg: 9.5,
    tallaCm: 75,
    perimetroBraquialCm: 13.5,
    edema: false,
    zPesoTalla: 0.32,
    clasificacionNutricional: 'VERDE',
    color: 'verde',
    latitud: 11.24712,
    longitud: -72.98765,
  );

  Future<void> montar(
    WidgetTester tester, {
    required Repositorio repo,
    required ReporteCsvService csv,
    DateTime? inicio,
    DateTime? fin,
    Future<void> Function(File)? alCompartir,
    Future<void> Function(File)? alAbrir,
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
        home: ReportesScreen(
          repo: repo,
          csvService: csv,
          fechaInicioInicial: inicio,
          fechaFinInicial: fin,
          alCompartir: alCompartir,
          alAbrir: alAbrir,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los 4 filtros y el botón Generar CSV', (tester) async {
    await montar(
      tester,
      repo: _RepoFalso(listaComunidades: ['Rancheria A', 'Rancheria B']),
      csv: _CsvFalso(),
    );

    expect(find.text('Fecha inicial'), findsOneWidget);
    expect(find.text('Fecha final'), findsOneWidget);
    expect(find.text('Comunidad / ranchería'), findsOneWidget);
    expect(find.text('Estado nutricional'), findsOneWidget);
    expect(find.text('Generar CSV'), findsOneWidget);
  });

  testWidgets('genera CSV con datos y muestra el diálogo con la ruta', (
    tester,
  ) async {
    final csv = _CsvFalso();
    await montar(
      tester,
      repo: _RepoFalso(
        listaComunidades: ['Rancheria A'],
        listaEvaluaciones: [evaluacion()],
      ),
      csv: csv,
    );

    await tester.tap(find.byKey(const Key('boton-generar-csv')));
    await tester.pumpAndSettle();

    expect(find.text('Reporte CSV generado'), findsOneWidget);
    expect(find.textContaining('exports/'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
    expect(csv.vecesGuardado, 1);
  });

  testWidgets('no genera si la fecha final es anterior a la inicial', (
    tester,
  ) async {
    final csv = _CsvFalso();
    await montar(
      tester,
      repo: _RepoFalso(listaEvaluaciones: [evaluacion()]),
      csv: csv,
      inicio: DateTime(2026, 2, 1),
      fin: DateTime(2026, 1, 1),
    );

    await tester.tap(find.byKey(const Key('boton-generar-csv')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rango de fechas inválido'), findsOneWidget);
    expect(find.text('Reporte CSV generado'), findsNothing);
    expect(csv.vecesGuardado, 0);
  });

  testWidgets('avisa cuando no hay evaluaciones con esos filtros', (
    tester,
  ) async {
    final csv = _CsvFalso();
    await montar(
      tester,
      repo: _RepoFalso(listaEvaluaciones: const []),
      csv: csv,
    );

    await tester.tap(find.byKey(const Key('boton-generar-csv')));
    await tester.pumpAndSettle();

    expect(
      find.text('No hay evaluaciones para los filtros seleccionados'),
      findsOneWidget,
    );
    expect(find.text('Reporte CSV generado'), findsNothing);
    expect(csv.vecesGuardado, 0);
  });

  testWidgets('Compartir y Abrir invocan sus callbacks', (tester) async {
    var compartido = false;
    var abierto = false;

    await montar(
      tester,
      repo: _RepoFalso(listaEvaluaciones: [evaluacion()]),
      csv: _CsvFalso(),
      alCompartir: (_) async => compartido = true,
      alAbrir: (_) async => abierto = true,
    );

    await tester.tap(find.byKey(const Key('boton-generar-csv')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();
    expect(compartido, isTrue);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(abierto, isTrue);
  });
}
