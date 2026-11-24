# nutrilaguajira

Proyecto Flutter de **NutriLaGuajira – Avance 1** (tamizaje rápido y semáforo
nutricional offline).

La documentación completa (alcance, modelo de datos, cálculo, pruebas,
limitaciones y capturas) está en el README de la entrega:

    ../README.md

## Arranque rápido

```bash
flutter pub get
flutter test        # motor, validadores, UI, SQLite real y sincronización simulada
flutter run         # requiere dispositivo/emulador Android
```

Credenciales demo: `promotor` / `demo123` (solo local). Para sincronizar con
Cloud Firestore, usa un correo creado en Firebase Console; la configuración
completa está en `README_FIREBASE.md` y el diseño de colecciones y campos en
`DISENO_FIRESTORE.md`.

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
    firebase_auth_service.dart login Firebase + respaldo offline
    firestore_strategy.dart sincronización SQLite -> Firestore
    sync_manager.dart       conectividad automática y contadores
    validadores.dart        reglas de validación de formularios
    edad.dart               edad en meses
    fechas.dart             formato de fechas (intl)
    referencias_csv.dart    parser del CSV (Dart puro)
    referencias_loader.dart carga del asset
  screens/                  login, menú, selección, infante, evaluación,
                            resultado, historial, detalle, acerca de
  theme/                    Material 3 + colores del semáforo
  widgets/                  componentes reutilizables
test/                       pruebas automatizadas (motor, UI, SQLite, sync)
tool/calcular_demo.dart     recalcula los casos semilla (dart run)
assets/who_referencia_demo.csv   tabla de referencia DEMO
```

## Documentos de diseño

- [`CONTEXTO_OPENCODE.md`](CONTEXTO_OPENCODE.md) — resumen operativo del
  proyecto para retomar el trabajo con OpenCode en otro equipo.
- [`DISENO_FIRESTORE.md`](DISENO_FIRESTORE.md) — colecciones, campos y flujo de
  sincronización de NutriLaGuajira con Cloud Firestore.
- [`DISENO_MOTOTRACK_RTDB.md`](DISENO_MOTOTRACK_RTDB.md) — adaptación del mismo
  enfoque al caso MotoTrack / LiveControl con Firebase Realtime Database
  (despacho en tiempo real, presencia y offline).

## Aviso

Prototipo académico. **No sustituye diagnóstico médico.** Tabla de referencia en
modo demostración (DEMO); la versión final usará las tablas OMS completas y la
Resolución 2465 de 2016 / Resolución 115 de 2026.
