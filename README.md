# NutriLaGuajira

Plataforma móvil **offline-first** para el control y la alerta temprana de
desnutrición infantil en comunidades rurales dispersas de La Guajira, Colombia.

Proyecto académico — Escuela de Ingeniería de Sistemas. Metodología Scrum
(3 sprints).

## Estado: Sprints 1, 2, 3 y 4 técnico completos

| Sprint | Entregado |
|---|---|
| **1** | Login local, registro de infantes/tutores, formulario antropométrico, persistencia SQLite offline e historial. |
| **2** | Z-score Peso/Talla con tabla DEMO, semáforo (verde/amarillo/rojo), captura **opcional de GPS** (alta precisión + fallback offline) y detalle georreferenciado. |
| **3** | **Reportes CSV/PDF** con filtros, **alertas SMS** con cola local y reintento, y **zonas en riesgo** consolidadas por ranchería. |
| **4 (técnico, completo)** | Z **Talla/Edad** y **Peso/Edad** con tabla **DEMO (LMS)**, migración de esquema v4, reportes/UI con los índices, **PDF con TTF local** (`—`, `«»`, `¿¡`) y `historial_screen` corregido. |

**Calidad actual:** `flutter test` **101/101** · `flutter analyze` **0 issues** ·
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
  casos ROJO con **Z P/T, Z T/E, Z P/E** y coordenadas; **TTF local (Roboto)**
  que soporta `—`, `«»`, `¿¡`, tildes y ñ; pie que marca la fuente DEMO; vista
  previa.
- **Alertas SMS**: cola local (`alertas_pendientes`), encolado automático al
  registrar una evaluación ROJA, envío por intent `sms:?body=` (sin `SEND_SMS`)
  y reintento de fallidas.
- **Zonas en riesgo**: consolidado por ranchería ordenado por criticidad, con
  detalle de los casos ROJO y copia de coordenadas.
- **100 % sin internet** (los reportes y la cola de alertas son locales).

## Instalación (APK de distribución v0.4.0-sprint4)

> Release: **`v0.4.0-sprint4`** — APK firmado con clave de **release** (no debug).

Descarga el APK según la arquitectura del dispositivo (build `--split-per-abi`):

| APK | Dispositivos | Tamaño |
|---|---|---|
| [`app-arm64-v8a-release.apk`](https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.4.0-sprint4/app-arm64-v8a-release.apk) | **La mayoría** de Android modernos (64 bits) | 21.4 MB |
| [`app-armeabi-v7a-release.apk`](https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.4.0-sprint4/app-armeabi-v7a-release.apk) | Android de 32 bits (equipos antiguos) | 19.4 MB |
| [`app-x86_64-release.apk`](https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.4.0-sprint4/app-x86_64-release.apk) | Emuladores x86_64 | 22.9 MB |

Requisito: **Android 7.0 (API 24) o superior**. Firmado con clave de **release**
propia; el keystore se guarda **fuera del repositorio** y no se publica.

Verificar el SHA256 (opcional):

```bash
sha256sum app-arm64-v8a-release.apk
# 1f9843c8b7982a72a2723296acbb160d0d0c1045ac1821a5eacb863858eccf30
```

| APK | SHA256 |
|---|---|
| `arm64-v8a` | `1f9843c8b7982a72a2723296acbb160d0d0c1045ac1821a5eacb863858eccf30` |
| `armeabi-v7a` | `88b4ad943162d170712283bb4a9604a585689da964125b4bd965437f384af26d` |
| `x86_64` | `87898f489f624c6e44ce45335f34fa9b7e933c219e1af0bc9c831f1da9a6eb62` |

> Las APK **no** se commitean: se descargan desde la sección *Releases*.

## Inicio rápido

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter pub get
flutter test      # 101/101
flutter analyze   # 0 issues
flutter run       # con un dispositivo o emulador Android conectado
```

Credenciales demo: usuario `promotor`, contraseña `demo123`.

## Documentación y evidencias

- [`ESTADO.md`](ESTADO.md) — estado del proyecto, deudas técnicas y Sprint 4 técnico completo.
- [`COMO_PROBAR.md`](COMO_PROBAR.md) — guía paso a paso para probar el APK.
- [`entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT2.md`](entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT2.md) — evidencias del GPS.
- [`entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT3.md`](entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT3.md) — resumen 6.1 y evidencias 6.2 del Sprint 3.
- [`entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT4.md`](entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT4.md) — cierre técnico post-entrega (T/E, P/E, historial y TTF).
- [`entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md`](entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md) — fases y gates de interoperabilidad (post-Sprint 4).
- [`entrega_avance1_nutrilaguajira/screenshots/`](entrega_avance1_nutrilaguajira/screenshots/) — capturas (`sprint2_gps/`, `sprint3_reportes/` y `sprint4_te_pe/`).
- [`entrega_avance1_nutrilaguajira/`](entrega_avance1_nutrilaguajira/) — informe, guion de demo y proyecto Flutter completo.

## Estructura del repositorio

```
README.md
ESTADO.md                       traspaso: estado, deudas y plan
COMO_PROBAR.md                  guía de prueba del APK
entrega_avance1_nutrilaguajira/
  EVIDENCIAS_SPRINT2.md         evidencias GPS
  EVIDENCIAS_SPRINT3.md         evidencias reportes/alertas/zonas
  EVIDENCIAS_SPRINT4.md         cierre técnico: T/E, P/E, historial y TTF
  ROADMAP_INTEROPERABILIDAD.md  fases y gates post-Sprint 4
  informe_avance1.md            informe del avance
  demo_script.md                guion de exposición
  screenshots/                  capturas reales (sprint2_gps, sprint3_reportes, sprint4_te_pe)
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
