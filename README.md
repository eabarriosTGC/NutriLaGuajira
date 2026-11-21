# NutriLaGuajira

Plataforma móvil **offline-first** para el control y la alerta temprana de
desnutrición infantil en comunidades rurales dispersas de La Guajira, Colombia.

Proyecto académico — Escuela de Ingeniería de Sistemas. Metodología Scrum
(3 sprints).

## Estado: Sprints 1, 2 y 3 completos · Sprint 4 técnico en curso

| Sprint | Entregado |
|---|---|
| **1** | Login local, registro de infantes/tutores, formulario antropométrico, persistencia SQLite offline e historial. |
| **2** | Z-score Peso/Talla con tabla DEMO, semáforo (verde/amarillo/rojo), captura **opcional de GPS** (alta precisión + fallback offline) y detalle georreferenciado. |
| **3** | **Reportes CSV/PDF** con filtros, **alertas SMS** con cola local y reintento, y **zonas en riesgo** consolidadas por ranchería. |
| **4 (técnico, en curso)** | Z **Talla/Edad** y **Peso/Edad** con tabla **DEMO (LMS)**, migración de esquema v4 y reportes/UI con los índices. |

**Calidad actual:** `flutter test` **98/98** · `flutter analyze` **0 issues** ·
`dart format` sin cambios pendientes.

## Funcionalidades

- **Login local** (demo `promotor` / `demo123`).
- **Registro** de infantes menores de 5 años y su tutor.
- **Evaluación antropométrica**: peso, talla, MUAC y edema bilateral.
- **Z-score Peso/Talla** con tabla DEMO y **semáforo** verde/amarillo/rojo.
- **Z-scores Talla/Edad y Peso/Edad** (informativos, tabla **DEMO** LMS; no
  clasifican el semáforo).
- **Captura opcional de GPS** de la ranchería (lat/lng).
- **Historial y detalle** de tamizajes.
- **Reportes CSV**: filtros por fecha/comunidad/estado, UTF-8 con BOM, escape
  RFC 4180, guardado en el sandbox y acciones Compartir/Abrir.
- **Reportes PDF**: encabezado con filtros aplicados, resumen por semáforo,
  casos ROJO con **Z P/T, Z T/E, Z P/E** y coordenadas; pie que marca la fuente
  DEMO; vista previa.
- **Alertas SMS**: cola local (`alertas_pendientes`), encolado automático al
  registrar una evaluación ROJA, envío por intent `sms:?body=` (sin `SEND_SMS`)
  y reintento de fallidas.
- **Zonas en riesgo**: consolidado por ranchería ordenado por criticidad, con
  detalle de los casos ROJO y copia de coordenadas.
- **100 % sin internet** (los reportes y la cola de alertas son locales).

## Descargar el APK (Sprint 3)

> Release: **`v0.3.0-sprint3`**

<https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.3.0-sprint3/app-debug.apk>

Requiere **Android 7.0 (API 24) o superior**. Es un **APK universal**
(arm64-v8a, armeabi-v7a y x86_64) firmado con la clave de *debug*: si Play
Protect avisa al instalar, es esperado → "Instalar de todas formas".

> El APK **no** se commitea (pesa cientos de MB): se descarga desde la sección
> *Releases* del repositorio.

## Inicio rápido

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter pub get
flutter test      # 98/98
flutter analyze   # 0 issues
flutter run       # con un dispositivo o emulador Android conectado
```

Credenciales demo: usuario `promotor`, contraseña `demo123`.

## Documentación y evidencias

- [`ESTADO.md`](ESTADO.md) — estado del proyecto, deudas técnicas y plan del Sprint 4.
- [`COMO_PROBAR.md`](COMO_PROBAR.md) — guía paso a paso para probar el APK.
- [`entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT2.md`](entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT2.md) — evidencias del GPS.
- [`entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT3.md`](entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT3.md) — resumen 6.1 y evidencias 6.2 del Sprint 3.
- [`entrega_avance1_nutrilaguajira/screenshots/`](entrega_avance1_nutrilaguajira/screenshots/) — capturas (`sprint2_gps/` y `sprint3_reportes/`).
- [`entrega_avance1_nutrilaguajira/`](entrega_avance1_nutrilaguajira/) — informe, guion de demo y proyecto Flutter completo.

## Estructura del repositorio

```
README.md
ESTADO.md                       traspaso: estado, deudas y plan
COMO_PROBAR.md                  guía de prueba del APK
entrega_avance1_nutrilaguajira/
  EVIDENCIAS_SPRINT2.md         evidencias GPS
  EVIDENCIAS_SPRINT3.md         evidencias reportes/alertas/zonas
  informe_avance1.md            informe del avance
  demo_script.md                guion de exposición
  screenshots/                  capturas reales de la app
  nutrilaguajira/               proyecto Flutter (lib/, test/, assets/)
```

## Limitaciones conocidas (honestas)

- **Talla/Edad y Peso/Edad** ya se calculan con una tabla **DEMO (LMS)**; el
  reemplazo por la tabla OMS oficial queda como **Gate 1** (post-Sprint 4). El
  semáforo sigue usando solo P/T, MUAC y edema.
- La **sincronización por API** no está implementada: `SincronizacionStrategy`
  es la interfaz preparada; hoy solo existe `SmsIntentStrategy`.
- **SMS sin destinatario** por diseño: el brigadista elige el destinatario en su
  app de mensajes. No se usa `SEND_SMS` ni `SharedPreferences`.
- La tabla de referencia es **DEMO** (no las tablas OMS completas); la validación
  clínica final usará las tablas OMS y la Resolución 2465/2016 y 115/2026.
- La **validación en campo y la capacitación** se ejecutan en **2027-1** según el
  plan de trabajo.
- El APK es **debug** (clave de debug). Para distribución real falta keystore +
  `--release` + `--split-per-abi`.
- No hay cifrado local: los datos de menores están en SQLite en claro (aceptable
  para un prototipo académico, no para producción).

## Aviso

Prototipo académico. **No sustituye diagnóstico médico.** Las tablas de
referencia están en modo demostración; la validación clínica final usará las
tablas OMS completas y la Resolución 2465 de 2016 / Resolución 115 de 2026.

Licencia: MIT.
