import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion_reporte.dart';
import 'package:nutrilaguajira/services/reporte_csv_service.dart';
import 'package:nutrilaguajira/services/reporte_pdf_service.dart';

/// Pruebas del generador PDF (RF-09).
///
/// Verifican que produce bytes válidos, que no rompe en los casos límite
/// (sin rojos, 500 registros) y que rechaza un reporte vacío.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final servicio = ReportePdfService();

  EvaluacionReporte evaluacion({
    required int id,
    String color = 'verde',
    String clasificacion = 'VERDE',
    double z = 0.32,
    double? lat,
    double? lng,
    DateTime? fecha,
    double? zTallaEdad,
    double? zPesoEdad,
    String nombres = 'Andrés',
    String apellidos = 'Jusayú',
  }) => EvaluacionReporte(
    idEvaluacion: id,
    idInfante: id,
    nombres: nombres,
    apellidos: apellidos,
    fechaNacimiento: DateTime(2024, 1, 1),
    sexo: 'M',
    rancheria: 'Ranchería Bahía Honda',
    fechaEvaluacion: fecha ?? DateTime(2026, 1, 15, 10, 30),
    pesoKg: 9.5,
    tallaCm: 75,
    perimetroBraquialCm: 13.5,
    edema: false,
    zPesoTalla: z,
    clasificacionNutricional: clasificacion,
    color: color,
    latitud: lat,
    longitud: lng,
    zTallaEdad: zTallaEdad,
    zPesoEdad: zPesoEdad,
  );

  ReporteFiltros filtros() => ReporteFiltros(
    fechaInicio: DateTime(2020, 1, 1),
    fechaFin: DateTime(2030, 12, 31),
  );

  bool esPdf(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46; // %PDF

  test('genera un PDF válido con verde, amarillo y rojo (con GPS)', () async {
    final bytes = await servicio.generar([
      evaluacion(id: 1, color: 'verde', clasificacion: 'VERDE', z: 0.32),
      evaluacion(id: 2, color: 'amarillo', clasificacion: 'AMARILLO', z: -1.2),
      evaluacion(
        id: 3,
        color: 'rojo',
        clasificacion: 'ROJO',
        z: -2.27,
        lat: 11.24712,
        lng: -72.98765,
      ),
    ], filtros());

    expect(bytes, isNotEmpty);
    expect(esPdf(bytes), isTrue);
  });

  test('no rompe cuando hay verdes pero ningún caso crítico', () async {
    final bytes = await servicio.generar([
      evaluacion(id: 1),
      evaluacion(id: 2),
    ], filtros());

    expect(bytes, isNotEmpty);
    expect(esPdf(bytes), isTrue);
  });

  test('genera 500 evaluaciones en menos de 5 s (RNF-02)', () async {
    final datos = <EvaluacionReporte>[
      for (var i = 0; i < 500; i++)
        evaluacion(
          id: i + 1,
          color: i % 5 == 0 ? 'rojo' : (i % 2 == 0 ? 'amarillo' : 'verde'),
          clasificacion: i % 5 == 0
              ? 'ROJO'
              : (i % 2 == 0 ? 'AMARILLO' : 'VERDE'),
          lat: 11.1 + (i % 90) / 1000,
          lng: -72.9 - (i % 90) / 1000,
        ),
    ];

    final cronometro = Stopwatch()..start();
    final bytes = await servicio.generar(datos, filtros());
    cronometro.stop();

    expect(bytes, isNotEmpty);
    expect(esPdf(bytes), isTrue);
    expect(cronometro.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('genera PDF con T/E y P/E no nulos', () async {
    final bytes = await servicio.generar([
      evaluacion(
        id: 1,
        color: 'rojo',
        clasificacion: 'ROJO',
        z: -2.27,
        zTallaEdad: -2.1,
        zPesoEdad: -1.4,
      ),
    ], filtros());

    expect(bytes, isNotEmpty);
    expect(esPdf(bytes), isTrue);
  });

  test('renderiza — «» ¿¡ con la TTF local (si pdftotext está disponible)', () async {
    final bytes = await servicio.generar(
      [
        evaluacion(
          id: 1,
          color: 'rojo',
          clasificacion: 'ROJO',
          z: -2.27,
          nombres: 'Andrés—«»¿¡',
          apellidos: 'Jusayú',
          zTallaEdad: -2.1,
          zPesoEdad: -1.4,
        ),
      ],
      filtros(),
      ahora: DateTime(2026, 11, 21, 12),
    );

    expect(bytes, isNotEmpty);
    expect(esPdf(bytes), isTrue);

    // El motor no debe crashear con la TTF. Si hay poppler, validamos el texto.
    final dir = await Directory.systemTemp.createTemp('pdf_ttf_');
    addTearDown(() => dir.delete(recursive: true));
    final archivo = File('${dir.path}/reporte.pdf');
    await archivo.writeAsBytes(bytes);

    final which = await () async {
      try {
        return await Process.run('which', ['pdftotext']);
      } on ProcessException {
        // `which` no existe en Windows: se omite la validación opcional.
        return null;
      }
    }();
    if (which == null || which.exitCode != 0) return;

    final salida = await Process.run('pdftotext', [
      '-layout',
      archivo.path,
      '-',
    ]);
    final texto = salida.stdout.toString();
    expect(texto, contains('Andrés'));
    expect(texto, contains('Jusayú'));
    expect(texto, contains('«»¿¡'));
  });

  test('lanza ArgumentError si no hay evaluaciones que reportar', () async {
    expect(
      () => servicio.generar(const <EvaluacionReporte>[], filtros()),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'mensaje',
          contains('No hay evaluaciones'),
        ),
      ),
    );
  });
}
