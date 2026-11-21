import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/evaluacion_reporte.dart';
import 'package:nutrilaguajira/services/reporte_csv_service.dart';

/// Pruebas del generador CSV (RF-09).
///
/// Cubren: BOM UTF-8, columnas exactas, escape RFC 4180, filtros y validación
/// de rango. No tocan UI ni SQLite: el generador es puro.
void main() {
  final servicio = ReporteCsvService();

  EvaluacionReporte evaluacion({
    int idEvaluacion = 1,
    int idInfante = 1,
    String nombres = 'Jose',
    String apellidos = 'Epieyu',
    String sexo = 'M',
    String rancheria = 'Rancheria A',
    DateTime? fechaEvaluacion,
    double pesoKg = 9.5,
    double tallaCm = 75.0,
    double perimetro = 13.5,
    bool edema = false,
    double z = 0.32,
    String clasificacion = 'VERDE',
    String color = 'verde',
    double? lat,
    double? lng,
    double? zTallaEdad,
    double? zPesoEdad,
  }) => EvaluacionReporte(
    idEvaluacion: idEvaluacion,
    idInfante: idInfante,
    nombres: nombres,
    apellidos: apellidos,
    fechaNacimiento: DateTime(2025, 1, 1),
    sexo: sexo,
    rancheria: rancheria,
    fechaEvaluacion: fechaEvaluacion ?? DateTime(2026, 1, 15, 10, 30),
    pesoKg: pesoKg,
    tallaCm: tallaCm,
    perimetroBraquialCm: perimetro,
    edema: edema,
    zPesoTalla: z,
    clasificacionNutricional: clasificacion,
    color: color,
    latitud: lat,
    longitud: lng,
    zTallaEdad: zTallaEdad,
    zPesoEdad: zPesoEdad,
  );

  ReporteFiltros filtros({
    DateTime? inicio,
    DateTime? fin,
    String? comunidad,
    EstadoReporte? estado,
  }) => ReporteFiltros(
    fechaInicio: inicio ?? DateTime(2020, 1, 1),
    fechaFin: fin ?? DateTime(2030, 12, 31),
    comunidad: comunidad,
    estado: estado,
  );

  /// Quita el BOM y parte el texto en líneas (CRLF).
  List<String> lineas(String csv) {
    final sinBom = csv.startsWith('\uFEFF') ? csv.substring(1) : csv;
    return sinBom.split('\r\n');
  }

  test('incluye el BOM UTF-8 al inicio (texto y bytes)', () {
    final csv = servicio.generar([evaluacion()], filtros());

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(utf8.encode(csv).sublist(0, 3), <int>[0xEF, 0xBB, 0xBF]);
  });

  test('el encabezado tiene las 17 columnas exactas en orden', () {
    final csv = servicio.generar([evaluacion()], filtros());
    final encabezado = lineas(csv).first.split(',');

    expect(encabezado, ReporteCsvService.columnas);
    expect(encabezado, hasLength(17));
    expect(encabezado.first, 'id_infante');
    expect(encabezado.last, 'longitud');
  });

  test('escapa comas, comillas y saltos de línea según RFC 4180', () {
    final csv = servicio.generar([
      evaluacion(
        nombres: 'Perez, Juan',
        apellidos: 'D "El" Grande',
        rancheria: 'Ranchería\nNorte',
      ),
    ], filtros());

    expect(csv, contains('"Perez, Juan"'));
    expect(csv, contains('"D ""El"" Grande"'));
    expect(csv, contains('"Ranchería\nNorte"'));
  });

  test('filtra por rango de fechas (extremos inclusivos)', () {
    final dentro = evaluacion(
      idEvaluacion: 1,
      fechaEvaluacion: DateTime(2026, 1, 20),
    );
    final fuera = evaluacion(
      idEvaluacion: 2,
      fechaEvaluacion: DateTime(2026, 2, 5),
    );

    final csv = servicio.generar([
      dentro,
      fuera,
    ], filtros(inicio: DateTime(2026, 1, 1), fin: DateTime(2026, 1, 31)));

    // Encabezado + 1 fila.
    expect(lineas(csv), hasLength(2));
  });

  test('filtra por comunidad y por estado nutricional', () {
    final rojoA = evaluacion(
      idEvaluacion: 1,
      idInfante: 1,
      rancheria: 'A',
      clasificacion: 'ROJO',
      color: 'rojo',
    );
    final verdeA = evaluacion(
      idEvaluacion: 2,
      idInfante: 2,
      rancheria: 'A',
      clasificacion: 'VERDE',
      color: 'verde',
    );
    final rojoB = evaluacion(
      idEvaluacion: 3,
      idInfante: 3,
      rancheria: 'B',
      clasificacion: 'ROJO',
      color: 'rojo',
    );
    final datos = [rojoA, verdeA, rojoB];

    // Comunidad A => 2 filas.
    expect(
      lineas(servicio.generar(datos, filtros(comunidad: 'A'))),
      hasLength(3),
    );

    // Comunidad A + riesgo (amarillo/rojo) => solo el rojo.
    expect(
      lineas(
        servicio.generar(
          datos,
          filtros(comunidad: 'A', estado: EstadoReporte.riesgo),
        ),
      ),
      hasLength(2),
    );

    // Desnutrición aguda en todas => los dos rojos.
    expect(
      lineas(
        servicio.generar(
          datos,
          filtros(estado: EstadoReporte.desnutricionAguda),
        ),
      ),
      hasLength(3),
    );
  });

  test('z_talla_edad y z_peso_edad se exportan como celdas vacías', () {
    final csv = servicio.generar([
      evaluacion(lat: 11.24712, lng: -72.98765),
    ], filtros());
    final celdas = lineas(csv)[1].split(',');

    // Índices 12 y 13 corresponden a z_talla_edad y z_peso_edad.
    expect(celdas[12], '');
    expect(celdas[13], '');
    // Control: el resto sí trae datos.
    expect(celdas[4], 'M');
    expect(celdas[15], '11.24712');
    expect(celdas[16], '-72.98765');
  });

  test('exporta T/E y P/E cuando existen', () {
    final csv = servicio.generar([
      evaluacion(zTallaEdad: -1.50, zPesoEdad: -0.80),
    ], filtros());
    final celdas = lineas(csv)[1].split(',');

    expect(celdas[12], '-1.50');
    expect(celdas[13], '-0.80');
  });

  test('lanza ArgumentError con mensaje claro si fin < inicio', () {
    expect(
      () => servicio.generar(
        const <EvaluacionReporte>[],
        ReporteFiltros(
          fechaInicio: DateTime(2026, 2, 1),
          fechaFin: DateTime(2026, 1, 1),
        ),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message.toString(),
          'mensaje',
          contains('Rango de fechas inválido'),
        ),
      ),
    );
  });
}
