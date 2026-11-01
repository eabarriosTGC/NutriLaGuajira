import 'package:flutter/material.dart';

import '../services/nutricion_service.dart';
import '../theme/semaforo.dart';

/// Boton grande del menu principal (área táctil amplia para uso en campo).
class BotonMenu extends StatelessWidget {
  const BotonMenu({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: titulo,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: esquema.primaryContainer,
                  child: Icon(
                    icono,
                    size: 28,
                    color: esquema.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: TextStyle(
                          fontSize: 14,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip gris que anuncia una funcion que llegara en el proximo sprint.
class ChipProximoSprint extends StatelessWidget {
  const ChipProximoSprint({super.key, required this.etiqueta});

  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        Icons.lock_outline,
        size: 18,
        color: esquema.onSurfaceVariant,
      ),
      label: Text(etiqueta),
      labelStyle: TextStyle(color: esquema.onSurfaceVariant),
      backgroundColor: esquema.surfaceContainerHighest,
      side: BorderSide(color: esquema.outlineVariant),
    );
  }
}

/// Etiqueta compacta con el color del semáforo, para listas e historial.
class ChipSemaforo extends StatelessWidget {
  const ChipSemaforo({
    super.key,
    required this.claveColor,
    required this.etiqueta,
  });

  final String claveColor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Semaforo.fondoDesdeClave(claveColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Semaforo.iconoDesdeClave(claveColor),
            size: 16,
            color: Semaforo.textoDesdeClave(claveColor),
          ),
          const SizedBox(width: 6),
          Text(
            etiqueta,
            style: TextStyle(
              color: Semaforo.textoDesdeClave(claveColor),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vacio reutilizable.
class PanelVacio extends StatelessWidget {
  const PanelVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 72, color: esquema.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: esquema.onSurfaceVariant),
            ),
            if (accion != null) ...[const SizedBox(height: 24), accion!],
          ],
        ),
      ),
    );
  }
}

/// Fila de dato etiqueta / valor usada en detalles.
class FilaDato extends StatelessWidget {
  const FilaDato({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.icono,
  });

  final String etiqueta;
  final String valor;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 20, color: esquema.primary),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 132,
            child: Text(
              etiqueta,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: esquema.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto que traduce la clasificacion a algo legible en pantalla.
String descripcionClasificacion(ClasificacionNutricional clasificacion) {
  switch (clasificacion) {
    case ClasificacionNutricional.rojo:
      return 'Requiere remisión inmediata al centro de salud';
    case ClasificacionNutricional.amarillo:
      return 'Requiere seguimiento cercano y control en 7 días';
    case ClasificacionNutricional.verde:
      return 'Sin signos de desnutrición aguda en este tamizaje';
  }
}
