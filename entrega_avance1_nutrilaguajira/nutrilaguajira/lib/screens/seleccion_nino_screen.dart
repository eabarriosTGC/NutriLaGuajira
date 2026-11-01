import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/models/nino.dart';
import '../services/edad.dart';
import '../services/fechas.dart';
import '../widgets/componentes.dart';
import 'evaluacion_form_screen.dart';
import 'nino_form_screen.dart';

/// Paso previo al tamizaje: elegir el infante (o registrar uno nuevo).
class SeleccionNinoScreen extends StatefulWidget {
  const SeleccionNinoScreen({super.key});

  @override
  State<SeleccionNinoScreen> createState() => _SeleccionNinoScreenState();
}

class _SeleccionNinoScreenState extends State<SeleccionNinoScreen> {
  late Future<List<Nino>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = AppServices.repo.listarNinos();
  }

  void _recargar() {
    setState(() => _futuro = AppServices.repo.listarNinos());
  }

  Future<void> _nuevoInfante() async {
    final nino = await Navigator.of(context).push<Nino>(
      MaterialPageRoute<Nino>(builder: (_) => const NinoFormScreen()),
    );
    if (nino == null || !mounted) return;
    await _irAEvaluacion(nino);
  }

  Future<void> _irAEvaluacion(Nino nino) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EvaluacionFormScreen(nino: nino)),
    );
    if (mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo tamizaje')),
      body: SafeArea(
        child: FutureBuilder<List<Nino>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return PanelVacio(
                icono: Icons.error_outline,
                titulo: 'No se pudo leer la base local',
                mensaje: '${snapshot.error}',
              );
            }

            final ninos = snapshot.data ?? const <Nino>[];
            if (ninos.isEmpty) {
              return PanelVacio(
                icono: Icons.child_care,
                titulo: 'Todavía no hay infantes',
                mensaje:
                    'Registre el primer infante para comenzar el tamizaje '
                    'nutricional.',
                accion: FilledButton.icon(
                  onPressed: _nuevoInfante,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Registrar infante'),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '¿A quién vamos a tamizar?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: ninos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final nino = ninos[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: esquema.primaryContainer,
                            child: Text(
                              nino.nombres.isEmpty
                                  ? '?'
                                  : nino.nombres.characters.first.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: esquema.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(nino.nombreCompleto),
                          subtitle: Text(
                            '${Edad.etiqueta(nino.edadMeses)} · '
                            '${nino.sexoEtiqueta} · ${nino.comunidad}\n'
                            'Nacimiento: ${Fechas.corta(nino.fechaNacimiento)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _irAEvaluacion(nino),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FilledButton.icon(
                    onPressed: _nuevoInfante,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Registrar nuevo infante'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
