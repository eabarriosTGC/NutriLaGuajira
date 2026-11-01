import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/services/validadores.dart';

void main() {
  group('peso', () {
    test('rechaza valores negativos', () {
      expect(Validadores.peso('-5'), isNotNull);
      expect(Validadores.peso('-0.1'), isNotNull);
    });

    test('rechaza cero y valores fuera del rango 0.5 - 30 kg', () {
      expect(Validadores.peso('0'), isNotNull);
      expect(Validadores.peso('0.4'), isNotNull);
      expect(Validadores.peso('30.1'), isNotNull);
      expect(Validadores.peso('120'), isNotNull);
    });

    test('acepta valores válidos con punto o coma', () {
      expect(Validadores.peso('9.5'), isNull);
      expect(Validadores.peso('9,5'), isNull);
      expect(Validadores.peso('0.5'), isNull);
      expect(Validadores.peso('30'), isNull);
    });

    test('exige el campo', () {
      expect(Validadores.peso(''), isNotNull);
      expect(Validadores.peso('   '), isNotNull);
    });

    test('rechaza texto no numérico', () {
      expect(Validadores.peso('abc'), isNotNull);
    });
  });

  group('talla', () {
    test('rechaza tallas imposibles', () {
      expect(Validadores.talla('29'), isNotNull);
      expect(Validadores.talla('131'), isNotNull);
      expect(Validadores.talla('200'), isNotNull);
      expect(Validadores.talla('-80'), isNotNull);
    });

    test('acepta el rango útil 30 - 130 cm', () {
      expect(Validadores.talla('30'), isNull);
      expect(Validadores.talla('85'), isNull);
      expect(Validadores.talla('130'), isNull);
    });
  });

  group('MUAC', () {
    test('rechaza valores fuera de 5 - 25 cm', () {
      expect(Validadores.muac('4.9'), isNotNull);
      expect(Validadores.muac('25.1'), isNotNull);
      expect(Validadores.muac('-12'), isNotNull);
    });

    test('acepta el rango útil', () {
      expect(Validadores.muac('11.5'), isNull);
      expect(Validadores.muac('12'), isNull);
    });
  });

  group('edad en meses', () {
    test('acepta de 0 a 59 meses', () {
      expect(Validadores.edadMeses(0), isNull);
      expect(Validadores.edadMeses(59), isNull);
    });

    test('rechaza 60 meses o más', () {
      expect(Validadores.edadMeses(60), isNotNull);
      expect(Validadores.edadMeses(72), isNotNull);
    });

    test('rechaza edades negativas', () {
      expect(Validadores.edadMeses(-1), isNotNull);
    });
  });

  group('fecha de nacimiento', () {
    final hoy = DateTime(2026, 11, 1);

    test('exige la fecha', () {
      expect(Validadores.fechaNacimiento(null, hoy: hoy), isNotNull);
    });

    test('rechaza fechas futuras', () {
      final futura = hoy.add(const Duration(days: 1));
      expect(Validadores.fechaNacimiento(futura, hoy: hoy), isNotNull);
    });

    test('rechaza infantes de 60 meses o más', () {
      final hace60Meses = DateTime(2021, 11, 1);
      expect(Validadores.fechaNacimiento(hace60Meses, hoy: hoy), isNotNull);
    });

    test('acepta un infante de 24 meses', () {
      final hace24Meses = DateTime(2024, 11, 1);
      expect(Validadores.fechaNacimiento(hace24Meses, hoy: hoy), isNull);
    });
  });

  group('parseNumero', () {
    test('normaliza coma decimal', () {
      expect(Validadores.parseNumero('9,5'), 9.5);
      expect(Validadores.parseNumero(' 12.25 '), 12.25);
      expect(Validadores.parseNumero(''), isNull);
      expect(Validadores.parseNumero('x'), isNull);
    });
  });
}
