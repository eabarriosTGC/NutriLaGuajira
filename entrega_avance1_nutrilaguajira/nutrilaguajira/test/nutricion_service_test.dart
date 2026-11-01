import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/referencia_who.dart';
import 'package:nutrilaguajira/services/nutricion_service.dart';
import 'package:nutrilaguajira/services/referencias_loader.dart';

/// Pruebas del motor de cálculo.
///
/// Usan el CSV real que se embarca en la app, de modo que si alguien cambia la
/// tabla DEMO estas pruebas detectan el efecto sobre la clasificación.
void main() {
  late List<ReferenciaWho> referencias;
  late NutricionService servicio;

  setUpAll(() {
    final csv = File('assets/who_referencia_demo.csv').readAsStringSync();
    referencias = ReferenciasLoader.desdeCsv(csv);
    servicio = NutricionService(referencias);
  });

  group('tabla de referencia DEMO', () {
    test('carga 28 filas (14 por sexo) y valores positivos', () {
      expect(referencias.length, 28);
      expect(referencias.where((r) => r.sexo == 'M').length, 14);
      expect(referencias.where((r) => r.sexo == 'F').length, 14);
      expect(referencias.every((r) => r.de > 0), isTrue);
      expect(referencias.every((r) => r.mediana > 0), isTrue);
    });

    test('interpola linealmente mediana y DE entre tallas', () {
      // Entre 75 cm (9.20 / 0.95) y 80 cm (10.20 / 1.00) para masculino.
      final referencia = servicio.referenciaPara(sexo: 'M', tallaCm: 77);
      expect(referencia.mediana, closeTo(9.60, 0.0001));
      expect(referencia.de, closeTo(0.97, 0.0001));
      expect(referencia.interpolada, isTrue);
    });

    test('usa el valor exacto cuando la talla coincide con una fila', () {
      final referencia = servicio.referenciaPara(sexo: 'F', tallaCm: 80);
      expect(referencia.mediana, closeTo(9.90, 0.0001));
      expect(referencia.de, closeTo(1.00, 0.0001));
      expect(referencia.interpolada, isFalse);
    });
  });

  group('casos obligatorios del semáforo', () {
    test('1. VERDE: sin edema y Z >= -1', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 11,
        pesoKg: 9.5,
        tallaCm: 75,
        muacCm: 13.5,
        edema: false,
      );
      expect(resultado.zPesoTalla, closeTo(0.3158, 0.001));
      expect(resultado.zPesoTalla, greaterThanOrEqualTo(-1));
      expect(resultado.clasificacion, ClasificacionNutricional.verde);
    });

    test('2. AMARILLO: sin edema y -2 <= Z < -1', () {
      final resultado = servicio.evaluar(
        sexo: 'F',
        edadMeses: 18,
        pesoKg: 8.7,
        tallaCm: 80,
        muacCm: 12.2,
        edema: false,
      );
      expect(resultado.zPesoTalla, closeTo(-1.20, 0.001));
      expect(resultado.clasificacion, ClasificacionNutricional.amarillo);
    });

    test('3. ROJO por Z: sin edema y Z < -2', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 24,
        pesoKg: 8.8,
        tallaCm: 85,
        muacCm: 12.0,
        edema: false,
      );
      expect(resultado.zPesoTalla, closeTo(-2.2727, 0.001));
      expect(resultado.clasificacion, ClasificacionNutricional.rojo);
    });

    test('4. ROJO por edema bilateral aunque el Z sea normal', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 25,
        pesoKg: 12.0,
        tallaCm: 86,
        muacCm: 12.4,
        edema: true,
      );
      expect(resultado.zPesoTalla, greaterThan(-1));
      expect(resultado.clasificacion, ClasificacionNutricional.rojo);
      expect(resultado.observacion, contains('Edema'));
    });

    test('desnutrición aguda severa (Z < -3) también es ROJO', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 14,
        pesoKg: 5.5,
        tallaCm: 70,
        muacCm: 12.4,
        edema: false,
      );
      expect(resultado.zPesoTalla, lessThan(-3));
      expect(resultado.clasificacion, ClasificacionNutricional.rojo);
    });
  });

  group('bordes de clasificación', () {
    test('Z exactamente -1 es VERDE (la regla es Z >= -1)', () {
      // masculino 75 cm: mediana 9.20, DE 0.95 => 8.25 kg da Z = -1.00
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 8.25,
        tallaCm: 75,
        muacCm: 13.5,
        edema: false,
      );
      expect(resultado.zPesoTalla, closeTo(-1.0, 1e-9));
      expect(resultado.clasificacion, ClasificacionNutricional.verde);
    });

    test('Z exactamente -2 es AMARILLO (la regla es -2 <= Z < -1)', () {
      // masculino 85 cm: mediana 11.30, DE 1.10 => 9.10 kg da Z = -2.00
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 24,
        pesoKg: 9.10,
        tallaCm: 85,
        muacCm: 13.5,
        edema: false,
      );
      expect(resultado.zPesoTalla, closeTo(-2.0, 1e-9));
      expect(resultado.clasificacion, ClasificacionNutricional.amarillo);
    });
  });

  group('reglas del MUAC', () {
    test('se ignora en menores de 6 meses', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 3,
        pesoKg: 9.5,
        tallaCm: 75,
        muacCm: 10.0, // sería ROJO si aplicara
        edema: false,
      );
      expect(resultado.muacEvaluado, isFalse);
      expect(resultado.clasificacion, ClasificacionNutricional.verde);
      expect(resultado.observacion, contains('MUAC no evaluado'));
    });

    test('aplica desde los 6 meses y agrava el resultado', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 9.5, // Z normal (verde)
        tallaCm: 75,
        muacCm: 11.0, // ROJO por MUAC
        edema: false,
      );
      expect(resultado.muacEvaluado, isTrue);
      expect(resultado.clasificacion, ClasificacionNutricional.rojo);
    });

    test('MUAC entre 11.5 y 12.5 deja AMARILLO', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 9.5,
        tallaCm: 75,
        muacCm: 12.0,
        edema: false,
      );
      expect(resultado.clasificacion, ClasificacionNutricional.amarillo);
    });
  });

  group('validación de rangos del motor', () {
    test('rechaza peso fuera de rango', () {
      expect(
        () => servicio.evaluar(
          sexo: 'M',
          edadMeses: 12,
          pesoKg: -1,
          tallaCm: 75,
          muacCm: 13,
          edema: false,
        ),
        throwsArgumentError,
      );
    });

    test('rechaza talla fuera de rango', () {
      expect(
        () => servicio.evaluar(
          sexo: 'M',
          edadMeses: 12,
          pesoKg: 9,
          tallaCm: 200,
          muacCm: 13,
          edema: false,
        ),
        throwsArgumentError,
      );
    });

    test('rechaza edad mayor a 59 meses', () {
      expect(
        () => servicio.evaluar(
          sexo: 'M',
          edadMeses: 60,
          pesoKg: 9,
          tallaCm: 75,
          muacCm: 13,
          edema: false,
        ),
        throwsArgumentError,
      );
    });

    test('rechaza un sexo sin filas en la tabla', () {
      expect(
        () => servicio.evaluar(
          sexo: 'X',
          edadMeses: 12,
          pesoKg: 9,
          tallaCm: 75,
          muacCm: 13,
          edema: false,
        ),
        throwsStateError,
      );
    });
  });
}
