import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Vista previa del PDF generado, con acciones de imprimir y compartir
/// provistas por `printing`.
class ReportePdfPreviewScreen extends StatelessWidget {
  const ReportePdfPreviewScreen({
    super.key,
    required this.bytes,
    required this.nombre,
  });

  final Uint8List bytes;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nombre)),
      body: PdfPreview(
        build: (format) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: nombre,
      ),
    );
  }
}
