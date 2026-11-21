import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilaguajira/data/models/referencia_edad.dart';
import 'package:nutrilaguajira/data/models/referencia_who.dart';
import 'package:nutrilaguajira/services/nutricion_service.dart';
import 'package:nutrilaguajira/services/referencias_edad_loader.dart';
import 'package:nutrilaguajira/services/referencias_loader.dart';

/// Pruebas del motor de cálculo.
///
/// Usan el CSV real que se embarca en la app, de modo que si alguien cambia la
/// tabla DEMO estas pruebas detectan el efecto sobre la clasificación.
void main() {
  late List<ReferenciaWho> referencias;
  late List<ReferenciaEdad> referenciasEdad;
  late NutricionService servicio;
  late NutricionService servicioEdad;

  setUpAll(() {
    final csv = File('assets/who_referencia_demo.csv').readAsStringSync();
    referencias = ReferenciasLoader.desdeCsv(csv);
    final csvEdad = File('assets/who_edad_demo.csv').readAsStringSync();
    referenciasEdad = ReferenciasEdadLoader.desdeCsv(csvEdad);
    servicio = NutricionService(referencias);
    servicioEdad = NutricionService(
      referencias,
      referenciasEdad: referenciasEdad,
    );
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

  group('T/E y P/E (tabla DEMO, informativos)', () {
    test('calcula T/E y P/E en la mediana (Z = 0)', () {
      final resultado = servicioEdad.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 9.60,
        tallaCm: 75.70,
        muacCm: 13.5,
        edema: false,
      );

      expect(resultado.zTallaEdad, closeTo(0, 1e-9));
      expect(resultado.zPesoEdad, closeTo(0, 1e-9));
      expect(resultado.clasificacion, ClasificacionNutricional.verde);
    });

    test('T/E y P/E no alteran el semáforo', () {
      // Talla muy baja para la edad (T/E muy negativo) pero P/T normal.
      final resultado = servicioEdad.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 9.5,
        tallaCm: 60,
        muacCm: 13.5,
        edema: false,
      );

      expect(resultado.zTallaEdad, lessThan(-3));
      expect(resultado.clasificacion, ClasificacionNutricional.verde);
    });

    test('sin referencias por edad, T/E y P/E son null', () {
      final resultado = servicio.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 9.5,
        tallaCm: 75,
        muacCm: 13.5,
        edema: false,
      );

      expect(resultado.zTallaEdad, isNull);
      expect(resultado.zPesoEdad, isNull);
      expect(resultado.observacion, contains('no calculados'));
    });

    test('soporta L != 0 en la fórmula LMS', () {
      final custom = <ReferenciaEdad>[
        const ReferenciaEdad(
          indice: IndiceAntropometrico.tallaEdad,
          sexo: 'M',
          edadMeses: 12,
          l: 2,
          m: 10,
          s: 0.1,
        ),
        const ReferenciaEdad(
          indice: IndiceAntropometrico.pesoEdad,
          sexo: 'M',
          edadMeses: 12,
          l: 2,
          m: 10,
          s: 0.1,
        ),
      ];
      final servicioCustom = NutricionService(
        referencias,
        referenciasEdad: custom,
      );

      final resultado = servicioCustom.evaluar(
        sexo: 'M',
        edadMeses: 12,
        pesoKg: 11,
        tallaCm: 11,
        muacCm: 13,
        edema: false,
        validarRangos: false,
      );

      // ((11/10)^2 - 1) / (2 * 0.1) = 1.05
      expect(resultado.zTallaEdad, closeTo(1.05, 1e-9));
      expect(resultado.zPesoEdad, closeTo(1.05, 1e-9));
    });

    test('cubre los bordes de edad 0 y 59 meses', () {
      final enCero = servicioEdad.evaluar(
        sexo: 'M',
        edadMeses: 0,
        pesoKg: 3.3,
        tallaCm: 49.9,
        muacCm: 10,
        edema: false,
      );
      final enCincuentaYNueve = servicioEdad.evaluar(
        sexo: 'M',
        edadMeses: 59,
        pesoKg: 18.3,
        tallaCm: 110,
        muacCm: 13.5,
        edema: false,
      );

      expect(enCero.zTallaEdad, isNotNull);
      expect(enCero.zPesoEdad, isNotNull);
      expect(enCincuentaYNueve.zTallaEdad, isNotNull);
      expect(enCincuentaYNueve.zPesoEdad, isNotNull);
    });
  });
}
