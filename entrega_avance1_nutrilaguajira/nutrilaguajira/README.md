# nutrilaguajira

Proyecto Flutter de **NutriLaGuajira – Avance 1** (tamizaje rápido y semáforo
nutricional offline).

La documentación completa (alcance, modelo de datos, cálculo, pruebas,
limitaciones y capturas) está en el README de la entrega:

    ../README.md

## Arranque rápido

```bash
flutter pub get
flutter test        # 45 pruebas: motor, validadores, formulario y SQLite real
flutter run         # requiere dispositivo/emulador Android
```

Credenciales demo: `promotor` / `demo123`.

## Estructura

```
lib/
  main.dart                 arranque, tema, localización es y pantalla de carga
  app_services.dart         localizador de dependencias + sesión en memoria
  data/
    db_nutrilaguajira.dart  esquema SQLite, semilla y carga de la tabla DEMO
    repositorio.dart        consultas (login, infantes, evaluaciones)
    models/                 Nino, Usuario, Evaluacion, ReferenciaWho
  services/
    nutricion_service.dart  MOTOR de cálculo (puro: sin Flutter ni SQLite)
    validadores.dart        reglas de validación de formularios
    edad.dart               edad en meses
    fechas.dart             formato de fechas (intl)
    referencias_csv.dart    parser del CSV (Dart puro)
    referencias_loader.dart carga del asset
  screens/                  login, menú, selección, infante, evaluación,
                            resultado, historial, detalle, acerca de
  theme/                    Material 3 + colores del semáforo
  widgets/                  componentes reutilizables
test/                       45 pruebas automatizadas
tool/calcular_demo.dart     recalcula los casos semilla (dart run)
assets/who_referencia_demo.csv   tabla de referencia DEMO
```

## Aviso

Prototipo académico. **No sustituye diagnóstico médico.** Tabla de referencia en
modo demostración (DEMO); la versión final usará las tablas OMS completas y la
Resolución 2465 de 2016 / Resolución 115 de 2026.
