import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/models/nino.dart';
import '../services/edad.dart';
import '../services/fechas.dart';
import '../services/validadores.dart';

/// Registro (o edición) de un infante menor de 5 años y su tutor.
class NinoFormScreen extends StatefulWidget {
  const NinoFormScreen({super.key, this.nino});

  final Nino? nino;

  bool get esEdicion => nino != null;

  @override
  State<NinoFormScreen> createState() => _NinoFormScreenState();
}

class _NinoFormScreenState extends State<NinoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombres;
  late final TextEditingController _apellidos;
  late final TextEditingController _documento;
  late final TextEditingController _tutor;
  late final TextEditingController _comunidad;
  late final TextEditingController _fechaTexto;

  DateTime? _fechaNacimiento;
  String _sexo = 'M';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final nino = widget.nino;
    _nombres = TextEditingController(text: nino?.nombres ?? '');
    _apellidos = TextEditingController(text: nino?.apellidos ?? '');
    _documento = TextEditingController(text: nino?.documento ?? '');
    _tutor = TextEditingController(text: nino?.tutor ?? '');
    _comunidad = TextEditingController(text: nino?.comunidad ?? '');
    _fechaNacimiento = nino?.fechaNacimiento;
    _fechaTexto = TextEditingController(
      text: nino == null ? '' : Fechas.corta(nino.fechaNacimiento),
    );
    _sexo = nino?.sexo ?? 'M';
  }

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _documento.dispose();
    _tutor.dispose();
    _comunidad.dispose();
    _fechaTexto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? hoy.subtract(const Duration(days: 365)),
      firstDate: DateTime(hoy.year - 6, hoy.month, hoy.day),
      lastDate: hoy,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (seleccion == null) return;
    setState(() {
      _fechaNacimiento = seleccion;
      _fechaTexto.text = Fechas.corta(seleccion);
    });
  }

  String _textoEdad() {
    final fecha = _fechaNacimiento;
    if (fecha == null) return 'Sin fecha de nacimiento';
    final meses = Edad.enMeses(fecha, DateTime.now());
    return 'Edad calculada: ${Edad.etiqueta(meses)} ($meses meses)';
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final fecha = _fechaNacimiento;
    if (fecha == null) return;

    setState(() => _guardando = true);
    try {
      final documento = _documento.text.trim();
      final duplicado = await AppServices.repo.documentoRegistrado(
        documento,
        excluirId: widget.nino?.id,
      );
      if (duplicado) {
        _avisar('Ya existe un infante registrado con ese documento');
        return;
      }

      final nino = Nino(
        id: widget.nino?.id,
        nombres: _nombres.text.trim(),
        apellidos: _apellidos.text.trim(),
        documento: documento,
        fechaNacimiento: fecha,
        sexo: _sexo,
        tutor: _tutor.text.trim(),
        comunidad: _comunidad.text.trim(),
      );

      late final int id;
      if (widget.esEdicion) {
        await AppServices.repo.actualizarNino(nino);
        id = widget.nino!.id!;
      } else {
        id = await AppServices.repo.insertarNino(nino);
      }

      if (!mounted) return;
      Navigator.of(context).pop(nino.copyWith(id: id));
    } catch (error) {
      _avisar('No se pudo guardar el infante: $error');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar infante' : 'Registrar infante'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Datos del infante',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Solo menores de 5 años (0 a 59 meses).',
                style: TextStyle(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombres,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombres *'),
                validator: (v) => Validadores.obligatorio(v, campo: 'Nombres'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellidos,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellidos *'),
                validator: (v) => Validadores.obligatorio(v, campo: 'Apellidos'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _documento,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Documento *',
                  helperText: 'Registro civil, tarjeta de identidad o código',
                ),
                validator: (v) => Validadores.obligatorio(v, campo: 'Documento'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _fechaTexto,
                readOnly: true,
                onTap: _elegirFecha,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento *',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (_) => Validadores.fechaNacimiento(_fechaNacimiento),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cake_outlined, size: 18, color: esquema.primary),
                  const SizedBox(width: 6),
                  Text(
                    _textoEdad(),
                    style: TextStyle(color: esquema.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Sexo *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: esquema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'M',
                    label: Text('Masculino'),
                    icon: Icon(Icons.male),
                  ),
                  ButtonSegment(
                    value: 'F',
                    label: Text('Femenino'),
                    icon: Icon(Icons.female),
                  ),
                ],
                selected: {_sexo},
                onSelectionChanged: (seleccion) =>
                    setState(() => _sexo = seleccion.first),
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size.fromHeight(52)),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Tutor o cuidador',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tutor,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del tutor *',
                ),
                validator: (v) => Validadores.obligatorio(v, campo: 'Tutor'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _comunidad,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Comunidad / ranchería *',
                ),
                validator: (v) =>
                    Validadores.obligatorio(v, campo: 'Comunidad / ranchería'),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Guardando...' : 'Guardar infante'),
              ),
              const SizedBox(height: 12),
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
