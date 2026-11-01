import 'package:intl/intl.dart';

/// Formatos de fecha centralizados (intl).
class Fechas {
  Fechas._();

  static final DateFormat _corta = DateFormat('dd/MM/yyyy');
  static final DateFormat _conHora = DateFormat('dd/MM/yyyy HH:mm');

  static String corta(DateTime fecha) => _corta.format(fecha);

  static String conHora(DateTime fecha) => _conHora.format(fecha);
}
