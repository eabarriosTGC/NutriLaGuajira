import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/evaluacion_reporte.dart';
import '../theme/semaforo.dart';
import 'fechas.dart';
import 'reporte_csv_service.dart';

/// Generador de reportes PDF (RF-09).
///
/// - 100 % local (RNF-01): no usa red.
/// - Usa una TTF local (Roboto, Apache 2.0) con soporte Unicode: tildes, ñ,
///   ¿, ¡, «», guion largo (—), etc. No depende de servicios externos.
/// - Incluye encabezado, resumen por semáforo y casos críticos (rojo) con
///   Z P/T, Z T/E, Z P/E y coordenadas. El pie marca la fuente DEMO.
class ReportePdfService {
  /// Construye el PDF de las evaluaciones que cumplen [filtros].
  ///
  /// Lanza [ArgumentError] si el rango es inválido o si no queda ninguna
  /// evaluación tras filtrar (consistente con la pantalla, que muestra un
  /// mensaje en ese caso).
  Future<Uint8List> generar(
    List<EvaluacionReporte> evaluaciones,
    ReporteFiltros filtros, {
    DateTime? ahora,
  }) async {
    filtros.validar();

    final filas = evaluaciones.where(filtros.cumple).toList()
      ..sort((a, b) => b.fechaEvaluacion.compareTo(a.fechaEvaluacion));

    if (filas.isEmpty) {
      throw ArgumentError('No hay evaluaciones para los filtros seleccionados');
    }

    final generadoEn = ahora ?? DateTime.now();
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final negrita = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

    final total = filas.length;
    final amarillos = filas.where((e) => e.color == 'amarillo').length;
    final rojos = filas.where((e) => e.esDesnutricionAguda).toList();

    final rojo = PdfColor.fromInt(Semaforo.rojo.toARGB32());
    final amarillo = PdfColor.fromInt(Semaforo.amarillo.toARGB32());

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(thickness: 0.6, color: PdfColors.grey400),
            pw.Text(
              'Generado offline — sincronizar cuando haya red · '
              '${Fechas.conHora(generadoEn)}',
              style: pw.TextStyle(
                font: regular,
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Fuente: tabla DEMO sin validez clínica — ver README del repo.',
              style: pw.TextStyle(
                font: regular,
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        build: (context) => [
          // -------------------------------------------------------- encabezado
          pw.Text(
            'NutriLaGuajira',
            style: pw.TextStyle(
              font: negrita,
              fontSize: 22,
              color: PdfColors.teal800,
            ),
          ),
          pw.Text(
            'Reporte de control nutricional',
            style: pw.TextStyle(
              font: negrita,
              fontSize: 12,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fecha de generación: ${Fechas.conHora(generadoEn)}',
            style: pw.TextStyle(font: regular, fontSize: 9),
          ),
          pw.Text(
            'Filtros aplicados: ${filtros.descripcion}',
            style: pw.TextStyle(font: regular, fontSize: 9),
          ),
          pw.Divider(thickness: 0.8, color: PdfColors.grey500),
          pw.SizedBox(height: 10),

          // ----------------------------------------------------------- resumen
          pw.Text('Resumen', style: pw.TextStyle(font: negrita, fontSize: 14)),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _contador(
                'Total evaluados',
                '$total',
                PdfColors.grey800,
                PdfColors.white,
                regular,
                negrita,
              ),
              _contador(
                'En riesgo (amarillo)',
                '$amarillos',
                amarillo,
                PdfColors.black,
                regular,
                negrita,
              ),
              _contador(
                'Desnutrición aguda (rojo)',
                '${rojos.length}',
                rojo,
                PdfColors.white,
                regular,
                negrita,
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ---------------------------------------------------- casos críticos
          pw.Text(
            'Casos críticos (ROJO)',
            style: pw.TextStyle(font: negrita, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          if (rojos.isEmpty)
            pw.Text(
              'Sin casos críticos en el periodo/filtros.',
              style: pw.TextStyle(font: regular, fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Infante',
                'Ranchería',
                'Fecha',
                'Z P/T',
                'Z T/E',
                'Z P/E',
                'Coordenadas',
              ],
              data: [
                for (final e in rojos)
                  [
                    e.nombreCompleto,
                    e.rancheria,
                    e.fechaEvaluacionTexto,
                    e.zPesoTalla.toStringAsFixed(2),
                    e.zTallaEdad?.toStringAsFixed(2) ?? 'N/D',
                    e.zPesoEdad?.toStringAsFixed(2) ?? 'N/D',
                    e.tieneUbicacion
                        ? '${e.latitud!.toStringAsFixed(5)}, '
                              '${e.longitud!.toStringAsFixed(5)}'
                        : 'N/D',
                  ],
              ],
              headerStyle: pw.TextStyle(
                font: negrita,
                fontSize: 8,
                color: PdfColors.white,
              ),
              cellStyle: pw.TextStyle(font: regular, fontSize: 7.5),
              headerDecoration: pw.BoxDecoration(color: rojo),
              cellPadding: const pw.EdgeInsets.all(3),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.3),
                1: const pw.FlexColumnWidth(2.0),
                2: const pw.FlexColumnWidth(1.7),
                3: const pw.FlexColumnWidth(0.8),
                4: const pw.FlexColumnWidth(0.8),
                5: const pw.FlexColumnWidth(0.8),
                6: const pw.FlexColumnWidth(1.8),
              },
            ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Solo se listan los casos con clasificación ROJO. Para el detalle '
            'completo use la exportación CSV.',
            style: pw.TextStyle(
              font: regular,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Guarda el PDF en `<documentos>/exports/` (sandbox de la app, RNF-06).
  Future<File> guardar(Uint8List bytes) async {
    final documentos = await getApplicationDocumentsDirectory();
    final exports = Directory(p.join(documentos.path, 'exports'));
    if (!await exports.exists()) {
      await exports.create(recursive: true);
    }
    final archivo = File(p.join(exports.path, nombreSugerido(DateTime.now())));
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo;
  }

  /// Nombre sugerido, p. ej. `nutrilaguajira_reporte_20261117_181500.pdf`.
  static String nombreSugerido(DateTime ahora) {
    String dos(int v) => v.toString().padLeft(2, '0');
    final fecha =
        '${ahora.year}${dos(ahora.month)}${dos(ahora.day)}_'
        '${dos(ahora.hour)}${dos(ahora.minute)}${dos(ahora.second)}';
    return 'nutrilaguajira_reporte_$fecha.pdf';
  }

  pw.Widget _contador(
    String etiqueta,
    String valor,
    PdfColor fondo,
    PdfColor texto,
    pw.Font regular,
    pw.Font negrita,
  ) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: fondo,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(font: negrita, fontSize: 22, color: texto),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              etiqueta,
              style: pw.TextStyle(font: regular, fontSize: 8, color: texto),
            ),
          ],
        ),
      ),
    );
  }
}
