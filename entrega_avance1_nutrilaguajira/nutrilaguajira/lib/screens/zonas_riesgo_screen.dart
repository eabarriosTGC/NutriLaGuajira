import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/models/resumen_zona.dart';
import '../data/repositorio.dart';
import '../services/fechas.dart';
import '../theme/semaforo.dart';
import '../widgets/componentes.dart';
import 'zona_detalle_screen.dart';

/// Vista consolidada de rancherías ordenadas por criticidad (RF-09).
class ZonasRiesgoScreen extends StatefulWidget {
  const ZonasRiesgoScreen({
    super.key,
    this.repo,
    this.alCopiar,
    this.desdeInicial,
  });

  /// Inyectables para pruebas.
  final Repositorio? repo;
  final Future<void> Function(String texto)? alCopiar;
  final DateTime? desdeInicial;

  @override
  State<ZonasRiesgoScreen> createState() => _ZonasRiesgoScreenState();
}

class _ZonasRiesgoScreenState extends State<ZonasRiesgoScreen> {
  late final Repositorio _repo = widget.repo ?? AppServices.repo;
  late DateTime? _desde = widget.desdeInicial;
  late Future<List<ResumenZona>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  Future<List<ResumenZona>> _cargar() async {
    final resumenes = await _repo.resumenPorRancheria(desde: _desde);
    // Orden defensivo (el SQL ya ordena): rojos, amarillos, total.
    return resumenes..sort((a, b) {
      final porRojos = b.rojos.compareTo(a.rojos);
      if (porRojos != 0) return porRojos;
      final porAmarillos = b.amarillos.compareTo(a.amarillos);
      if (porAmarillos != 0) return porAmarillos;
      return b.total.compareTo(a.total);
    });
  }

  Future<void> _recargar() async {
    final nuevo = _cargar();
    setState(() {
      _futuro = nuevo;
    });
    await nuevo;
  }

  Future<void> _elegirDesde() async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _desde ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: DateTime(hoy.year + 1),
      helpText: 'Evaluaciones desde',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (seleccion == null) return;
    setState(() {
      _desde = seleccion;
    });
    await _recargar();
  }

  Future<void> _limpiarDesde() async {
    setState(() {
      _desde = null;
    });
    await _recargar();
  }

  void _abrirDetalle(ResumenZona zona) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ZonaDetalleScreen(
          rancheria: zona.rancheria,
          repo: _repo,
          desde: _desde,
          alCopiar: widget.alCopiar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas en riesgo'),
        actions: [
          IconButton(
            tooltip: 'Filtrar desde una fecha',
            onPressed: _elegirDesde,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: esquema.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _desde == null
                          ? 'Todas las evaluaciones'
                          : 'Desde ${Fechas.corta(_desde!)}',
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                  ),
                  if (_desde != null)
                    TextButton(
                      onPressed: _limpiarDesde,
                      child: const Text('Quitar filtro'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ResumenZona>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return PanelVacio(
                      icono: Icons.error_outline,
                      titulo: 'No se pudo leer el consolidado',
                      mensaje: '${snapshot.error}',
                    );
                  }

                  final zonas = snapshot.data ?? const <ResumenZona>[];
                  if (zonas.isEmpty) {
                    return const PanelVacio(
                      icono: Icons.location_off_outlined,
                      titulo: 'Sin zonas registradas',
                      mensaje:
                          'No hay evaluaciones registradas. Registra una '
                          'evaluación para empezar a ver el consolidado por '
                          'zona.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _recargar,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: zonas.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final zona = zonas[index];
                        return _TarjetaZona(
                          zona: zona,
                          onTap: () => _abrirDetalle(zona),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaZona extends StatelessWidget {
  const _TarjetaZona({required this.zona, required this.onTap});

  final ResumenZona zona;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      zona.rancheria,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (zona.tieneCritico)
                    Icon(Icons.warning_amber, color: Semaforo.rojo),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipConteo(
                    cantidad: zona.rojos,
                    etiqueta: 'rojos',
                    fondo: Semaforo.rojo,
                    texto: Colors.white,
                  ),
                  _ChipConteo(
                    cantidad: zona.amarillos,
                    etiqueta: 'amarillos',
                    fondo: Semaforo.amarillo,
                    texto: Colors.black,
                  ),
                  _ChipConteo(
                    cantidad: zona.verdes,
                    etiqueta: 'verdes',
                    fondo: Semaforo.verde,
                    texto: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${zona.total} · Último caso: '
                '${Fechas.corta(zona.ultimaFecha)}',
                style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant),
              ),
              if (zona.tieneCritico)
                Text(
                  'Último rojo: '
                  '${zona.tieneUbicacionCritico ? '${zona.latitudCritico!.toStringAsFixed(5)}, ${zona.longitudCritico!.toStringAsFixed(5)}' : 'sin GPS'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: esquema.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipConteo extends StatelessWidget {
  const _ChipConteo({
    required this.cantidad,
    required this.etiqueta,
    required this.fondo,
    required this.texto,
  });

  final int cantidad;
  final String etiqueta;
  final Color fondo;
  final Color texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$cantidad $etiqueta',
        style: TextStyle(
          color: texto,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
