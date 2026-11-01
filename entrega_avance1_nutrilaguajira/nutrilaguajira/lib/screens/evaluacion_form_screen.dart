import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/models/evaluacion.dart';
import '../data/models/nino.dart';
import '../services/edad.dart';
import '../services/fechas.dart';
import '../services/validadores.dart';
import 'resultado_screen.dart';

/// Formulario de evaluación antropométrica.
///
/// No pide la fecha: usa la fecha y hora del dispositivo en el momento de
/// guardar (requisito del Avance 1: registro offline con hora local).
class EvaluacionFormScreen extends StatefulWidget {
  const EvaluacionFormScreen({super.key, required this.nino, this.ahora});

  final Nino nino;

  /// Inyectable para pruebas; por defecto usa DateTime.now().
  final DateTime? ahora;

  @override
  State<EvaluacionFormScreen> createState() => _EvaluacionFormScreenState();
}

class _EvaluacionFormScreenState extends State<EvaluacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _peso = TextEditingController();
  final _talla = TextEditingController();
  final _muac = TextEditingController();

  bool _edema = false;
  bool _guardando = false;

  DateTime get _ahora => widget.ahora ?? DateTime.now();

  @override
  void dispose() {
    _peso.dispose();
    _talla.dispose();
    _muac.dispose();
    super.dispose();
  }

  int get _edadMeses => Edad.enMeses(widget.nino.fechaNacimiento, _ahora);

  bool get _edadValida =>
      Validadores.edadMeses(_edadMeses, nacimiento: widget.nino.fechaNacimiento) ==
      null;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_edadValida) {
      _avisar(
        'Edad fuera de rango para el tamizaje: '
        '${Edad.etiqueta(_edadMeses)} (se exige 0 a 59 meses)',
      );
      return;
    }

    final peso = Validadores.parseNumero(_peso.text)!;
    final talla = Validadores.parseNumero(_talla.text)!;
    final muac = Validadores.parseNumero(_muac.text)!;

    setState(() => _guardando = true);
    try {
      final resultado = AppServices.nutricion.evaluar(
        sexo: widget.nino.sexo,
        edadMeses: _edadMeses,
        pesoKg: peso,
        tallaCm: talla,
        muacCm: muac,
        edema: _edema,
      );

      final evaluacion = Evaluacion(
        ninoId: widget.nino.id!,
        fecha: _ahora,
        edadMeses: _edadMeses,
        pesoKg: peso,
        tallaCm: talla,
        muacCm: muac,
        edema: _edema,
        zPesoTalla: resultado.zPesoTalla,
        clasificacion: resultado.clasificacion.etiqueta,
        color: resultado.clasificacion.clave,
        observacion: resultado.observacion,
        // Datos de contexto para la pantalla de resultado (normalmente vienen
        // del JOIN con `ninos`; aqui el registro es nuevo, no pasó por SQL).
        ninoNombre: widget.nino.nombreCompleto,
        comunidad: widget.nino.comunidad,
      );

      final id = await AppServices.repo.insertarEvaluacion(evaluacion);
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultadoScreen(
            evaluacion: evaluacion.copyWithId(id),
            resultado: resultado,
          ),
        ),
      );
    } catch (error) {
      _avisar('No se pudo guardar la evaluación: $error');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final nino = widget.nino;

    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación antropométrica')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nino.nombreCompleto,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${Edad.etiqueta(_edadMeses)} · ${nino.sexoEtiqueta} · '
                        '${nino.comunidad}',
                        style: TextStyle(color: esquema.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_edadValida) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esquema.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: esquema.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este infante tiene ${Edad.etiqueta(_edadMeses)}: '
                          'el tamizaje de este avance aplica solo de 0 a 59 '
                          'meses.',
                          style: TextStyle(color: esquema.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Medidas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo-peso'),
                controller: _peso,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Peso (kg) *',
                  helperText: 'Entre 0.5 y 30 kg · use coma o punto',
                  suffixText: 'kg',
                ),
                validator: Validadores.peso,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo-talla'),
                controller: _talla,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Talla (cm) *',
                  helperText: 'Entre 30 y 130 cm',
                  suffixText: 'cm',
                ),
                validator: Validadores.talla,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo-muac'),
                controller: _muac,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Perímetro braquial MUAC (cm) *',
                  helperText: 'Entre 5 y 25 cm · no aplica si es menor de 6 meses',
                  suffixText: 'cm',
                ),
                validator: Validadores.muac,
              ),
              const SizedBox(height: 18),
              Card(
                child: SwitchListTile(
                  value: _edema,
                  onChanged: (valor) => setState(() => _edema = valor),
                  title: const Text('Edema bilateral'),
                  subtitle: const Text(
                    'Hinchazón en ambos pies. Si está presente, el resultado '
                    'siempre es ROJO.',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: esquema.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Se registrará con la fecha y hora actual: '
                          '${Fechas.conHora(_ahora)}',
                          style: TextStyle(color: esquema.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('boton-calcular'),
                onPressed: (_guardando || !_edadValida) ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate_outlined),
                label: Text(
                  _guardando ? 'Calculando...' : 'Calcular semáforo y guardar',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _guardando
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
