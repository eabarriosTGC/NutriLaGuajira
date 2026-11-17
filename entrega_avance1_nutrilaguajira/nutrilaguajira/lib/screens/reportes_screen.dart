import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../app_services.dart';
import '../data/repositorio.dart';
import '../services/fechas.dart';
import '../services/reporte_csv_service.dart';

/// Pantalla de reportes (RF-09, alcance de este bloque: CSV).
///
/// Filtra evaluaciones por fecha, ranchería y estado, genera un CSV local
/// (100 % offline) y permite compartirlo o abrirlo.
///
/// El PDF se agrega en el siguiente bloque; por eso la pantalla no muestra
/// ningún botón de PDF todavía.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({
    super.key,
    this.repo,
    this.csvService,
    this.fechaInicioInicial,
    this.fechaFinInicial,
    this.alCompartir,
    this.alAbrir,
  });

  /// Inyectable para pruebas; por defecto usa el repositorio de la app.
  final Repositorio? repo;

  /// Inyectable para pruebas; por defecto escribe en documentos/exports.
  final ReporteCsvService? csvService;

  /// Valores iniciales de los filtros de fecha (pruebas).
  final DateTime? fechaInicioInicial;
  final DateTime? fechaFinInicial;

  /// Callbacks inyectables para probar Compartir/Abrir sin plugins.
  final Future<void> Function(File archivo)? alCompartir;
  final Future<void> Function(File archivo)? alAbrir;

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  late final Repositorio _repo = widget.repo ?? AppServices.repo;
  late final ReporteCsvService _csv = widget.csvService ?? ReporteCsvService();

  late DateTime? _inicio = widget.fechaInicioInicial;
  late DateTime? _fin = widget.fechaFinInicial;

  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  List<String> _comunidades = const <String>[];

  /// '' = todas las rancherías.
  String _comunidad = '';

  /// 'todos' | 'riesgo' | 'aguda'
  String _estado = 'todos';

  bool _generando = false;

  @override
  void initState() {
    super.initState();
    _sincronizarTextoFechas();
    _cargarComunidades();
  }

  @override
  void dispose() {
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarComunidades() async {
    try {
      final comunidades = await _repo.comunidades();
      if (!mounted) return;
      setState(() => _comunidades = comunidades);
    } catch (_) {
      // Si falla, el filtro queda solo con "Todas".
    }
  }

  void _sincronizarTextoFechas() {
    _inicioCtrl.text = _inicio == null ? 'Sin límite' : Fechas.corta(_inicio!);
    _finCtrl.text = _fin == null ? 'Sin límite' : Fechas.corta(_fin!);
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _inicio : _fin) ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 1),
      helpText: esInicio ? 'Fecha inicial' : 'Fecha final',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (seleccion == null) return;
    setState(() {
      if (esInicio) {
        _inicio = seleccion;
      } else {
        _fin = seleccion;
      }
      _sincronizarTextoFechas();
    });
  }

  ReporteFiltros _construirFiltros() => ReporteFiltros(
    fechaInicio: _inicio ?? DateTime(2000, 1, 1),
    fechaFin: _fin ?? DateTime.now(),
    comunidad: _comunidad.isEmpty ? null : _comunidad,
    estado: switch (_estado) {
      'riesgo' => EstadoReporte.riesgo,
      'aguda' => EstadoReporte.desnutricionAguda,
      _ => null,
    },
  );

  Future<void> _generarCsv() async {
    final filtros = _construirFiltros();
    try {
      filtros.validar();
    } on ArgumentError catch (error) {
      _avisar('${error.message}');
      return;
    }

    setState(() => _generando = true);
    File? archivo;
    try {
      final evaluaciones = await _repo.evaluacionesParaReporte();
      if (!evaluaciones.any(filtros.cumple)) {
        _avisar('No hay evaluaciones para los filtros seleccionados');
        return;
      }

      final csv = _csv.generar(evaluaciones, filtros);
      final nombre = ReporteCsvService.nombreSugerido(DateTime.now());
      archivo = await _csv.guardar(csv, nombre);
    } catch (error) {
      _avisar('No se pudo generar el archivo: $error');
    } finally {
      if (mounted) setState(() => _generando = false);
    }

    if (!mounted || archivo == null) return;
    await _mostrarDialogo(archivo);
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _mostrarDialogo(File archivo) {
    // Se muestra la ruta relativa al directorio de documentos para no exponer
    // la ruta absoluta del sandbox (RNF-06).
    final rutaRelativa = 'exports/${p.basename(archivo.path)}';
    final esquema = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reporte CSV generado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archivo guardado en el almacenamiento privado de la app:',
            ),
            const SizedBox(height: 8),
            Text(
              rutaRelativa,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'La generación fue 100 % local; no se envió nada a internet.',
              style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _compartir(archivo),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Compartir'),
          ),
          TextButton.icon(
            onPressed: () => _abrir(archivo),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _compartir(File archivo) async {
    final callback = widget.alCompartir;
    if (callback != null) {
      await callback(archivo);
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archivo.path)],
          subject: 'Reporte NutriLaGuajira',
          text: 'Reporte de tamizajes NutriLaGuajira (CSV).',
        ),
      );
    } catch (error) {
      _avisar('No se pudo compartir el archivo: $error');
    }
  }

  Future<void> _abrir(File archivo) async {
    final callback = widget.alAbrir;
    if (callback != null) {
      await callback(archivo);
      return;
    }
    try {
      final resultado = await OpenFilex.open(archivo.path);
      if (resultado.type != ResultType.done) {
        _avisar('No se pudo abrir el archivo: ${resultado.message}');
      }
    } catch (error) {
      _avisar('No se pudo abrir el archivo: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Reporte de evaluaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Exporta los tamizajes filtrados a CSV. Todo se genera en el '
              'dispositivo, sin internet.',
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros del reporte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('filtro-fecha-inicio'),
                      controller: _inicioCtrl,
                      readOnly: true,
                      onTap: () => _elegirFecha(esInicio: true),
                      decoration: const InputDecoration(
                        labelText: 'Fecha inicial',
                        helperText: 'Opcional · por defecto sin límite',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('filtro-fecha-fin'),
                      controller: _finCtrl,
                      readOnly: true,
                      onTap: () => _elegirFecha(esInicio: false),
                      decoration: const InputDecoration(
                        labelText: 'Fecha final',
                        helperText: 'Opcional · por defecto hoy',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const Key('filtro-comunidad'),
                      initialValue: _comunidad,
                      decoration: const InputDecoration(
                        labelText: 'Comunidad / ranchería',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Todas')),
                        for (final comunidad in _comunidades)
                          DropdownMenuItem(
                            value: comunidad,
                            child: Text(comunidad),
                          ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _comunidad = valor ?? ''),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: const Key('filtro-estado'),
                      initialValue: _estado,
                      decoration: const InputDecoration(
                        labelText: 'Estado nutricional',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(
                          value: 'riesgo',
                          child: Text('Riesgo'),
                        ),
                        DropdownMenuItem(
                          value: 'aguda',
                          child: Text('Desnutrición aguda'),
                        ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _estado = valor ?? 'todos'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('boton-generar-csv'),
              onPressed: _generando ? null : _generarCsv,
              icon: _generando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_view_outlined),
              label: Text(_generando ? 'Generando...' : 'Generar CSV'),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.offline_bolt_outlined, color: esquema.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El archivo queda en el almacenamiento privado de la '
                        'app y solo sale si usted lo comparte.',
                        style: TextStyle(
                          fontSize: 13,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
