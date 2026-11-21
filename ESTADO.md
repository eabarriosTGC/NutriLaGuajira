# Estado del proyecto — NutriLaGuajira

Documento de traspaso para retomar el trabajo sin reconstruir contexto.
Última actualización: **2026-11-17** (Sprint 3 cerrado).

> **Nota honesta.** El Sprint 3 entrega el módulo de **reportes (CSV/PDF),
> alertas SMS y zonas en riesgo**. La **validación en campo** con promotores se
> ejecuta en **2027-1**, conforme al plan de trabajo, y no en este sprint.

---

## 1. Dónde estamos

| Dato | Valor |
|---|---|
| Repo | https://github.com/eabarriosTGC/NutriLaGuajira (público, MIT) |
| Rama | `main` |
| HEAD | `9aba19f` (docs: README con Sprints 1–3 y APK) |
| Tag / release | `v0.3.0-sprint3` (actual) y `v0.1.0-avance1` (histórico), ambos con `app-debug.apk` adjunto |
| Estado | **Sprint 1 + Sprint 2 + Sprint 3 completos**: `flutter analyze` limpio, **85/85 tests**, formato limpio |
| Evidencias | `entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT{2,3}.md` + `screenshots/` |

Alcance funcional: login local, registro de infantes/tutores, evaluación
antropométrica con **Z Peso/Talla** y semáforo, **captura opcional de GPS**,
historial, **reportes CSV/PDF**, **alertas SMS** (cola local + intent) y **zonas
en riesgo**. Pendiente: Talla/Edad, Peso/Edad, sincronización por API, validación
en campo y capacitación (Sprint 4 / 2027-1).

---

## 2. Cómo retomar

```bash
git clone https://github.com/eabarriosTGC/NutriLaGuajira.git
cd NutriLaGuajira/entrega_avance1_nutrilaguajira/nutrilaguajira

flutter pub get
flutter test        # debe dar 85/85 antes de tocar nada
flutter analyze     # debe estar limpio
dart format --output=none --set-exit-if-changed lib test tool

flutter run         # dispositivo/emulador Android
```

Para publicar una versión nueva del APK:

```bash
flutter build apk --debug
cp build/app/outputs/flutter-apk/app-debug.apk ../../app-debug.apk
gh release upload <tag> ../../app-debug.apk --clobber
```

El APK **no** se commitea (está en `.gitignore`): va como asset del release.

---

## 3. Mapa del código (dónde tocar cada cosa)

```
lib/
  main.dart                 arranque, tema, locale es, pantalla de carga
  app_services.dart         localizador de dependencias + Sesion en memoria
  data/
    db_nutrilaguajira.dart  esquema v3, semilla, migraciones, carga del CSV
    repositorio.dart        consultas (login, infantes, evaluaciones, reportes,
                            alertas, zonas en riesgo)
    models/                 Nino, Usuario, Evaluacion, ReferenciaWho,
                            EvaluacionReporte, AlertaPendiente, ResumenZona
  services/
    nutricion_service.dart  MOTOR de cálculo P/T (puro: sin Flutter ni SQLite)
    validadores.dart        reglas de formulario (rangos, fecha, edad)
    edad.dart               meses cumplidos
    fechas.dart             formato dd/MM/yyyy (intl)
    referencias_csv.dart    parser del CSV (Dart puro)
    referencias_loader.dart acceso al asset
    localizacion_service.dart GPS opcional (geolocator) + Coordenada
    reporte_csv_service.dart  filtros + CSV (BOM UTF-8, RFC 4180)
    reporte_pdf_service.dart  PDF (encabezado, resumen, casos rojos, pie)
    sincronizacion_strategy.dart  interfaz (TODO: ApiStrategy Sprint 4)
    sms_intent_strategy.dart  envío por intent `sms:?body=` (sin SEND_SMS)
    alerta_service.dart       encolado en ROJO, envío y reintento
  screens/                  login, home, seleccion, nino_form, evaluacion_form,
                            resultado, historial, detalle, acerca_de,
                            reportes, reporte_pdf_preview, alertas,
                            zonas_riesgo, zona_detalle
  theme/                    tema Material 3 + colores del semáforo
  widgets/componentes.dart  botones, chips, PanelVacio, FilaDato
test/                       85 pruebas (motor, validadores, widget, SQLite real,
                            migración, reportes, alertas, zonas)
tool/calcular_demo.dart     recalcula los casos semilla con el motor real
```

Dependencias principales: `sqflite, path, intl, geolocator, path_provider,
share_plus, open_filex, pdf, printing, url_launcher`.

---

## 4. Reglas del dominio que NO se deben romper

1. **Z se clasifica con el valor redondeado a 2 decimales** (lo mismo que se
   muestra). Si se clasifica con el valor crudo, `-2.0000000000000009` cae en la
   categoría siguiente aunque en pantalla se lea `-2.00`.
2. **Edema bilateral ⇒ ROJO**, sin importar el Z.
3. **MUAC solo aplica desde los 6 meses**; en menores se ignora y se informa.
4. Si Z y MUAC discrepan, **gana el criterio más grave**.
5. La tabla de referencia es **dato, no lógica**: vive en `who_referencia_demo`
   y el motor se construye leyéndola. Reemplazarla no toca el cálculo.
6. **La semilla se calcula con el motor**, nunca con colores escritos a mano.
7. Los textos de la interfaz van **en español con tildes**.
8. **ROJO = evaluación con `clasificacion == 'ROJO'`** (clave `'rojo'`). Es el
   único criterio que encola alertas.

---

## 5. Sprint 3 — COMPLETO

| Módulo | Qué hace | Evidencia |
|---|---|---|
| Reportes CSV | Filtros por fecha/comunidad/estado, 17 columnas, BOM UTF-8, RFC 4180, guardar en sandbox, compartir/abrir. | `11`, `12` |
| Reportes PDF | Encabezado con filtros, resumen por semáforo, casos ROJO con coordenadas, pie con nota T/E y P/E, vista previa (`printing`). | `13` |
| Alertas SMS | Tabla `alertas_pendientes` (v3), encolado automático en ROJO, intent `sms:?body=` (sin destinatario ni `SEND_SMS`), estados y reintento. | `14`, `14b` |
| Zonas en riesgo | Consolidado por ranchería ordenado por criticidad, detalle de casos ROJO y copia de coordenadas. | `15` |
| Menú | 6 accesos definitivos con iconos, sin chips de "próximo". | código |

**Commits del Sprint 3:** `7bebbd3` (CSV), `012811c` (pantalla reportes),
`09553c5` (PDF), `3476dfb` (tabla v3 + servicios de alertas), `5e919b1`
(pantalla de alertas) + commits de cierre (zonas, menú, docs).

**Calidad:** `flutter test` 85/85, `flutter analyze` 0 issues, `dart format`
limpio.

---

## 6. Sprint 4 — PLANIFICADO

### 6.1 Sprint 4 técnico (puede arrancar ya)

| # | Tarea | Notas de arranque |
|---|---|---|
| 1 | **Talla/Edad y Peso/Edad** | tablas OMS por edad + motor + migración; el CSV/PDF ya reservan las columnas (hoy vacías) |
| 2 | **Tablas OMS completas** | reemplazar `assets/who_referencia_demo.csv`; revisar Resolución 2465/2016 y 115/2026 |
| 3 | **Corregir `historial_screen`** | `setState` con callback que devuelve un `Future` (deuda detectada en el Sprint 3) |
| 4 | **TTF opcional para el PDF** | para soportar `—` (U+2014) y otros caracteres fuera de Latin-1 |
| 5 | **Editar / borrar evaluaciones** | hoy solo hay inserción y lectura |
| 6 | **APK de distribución** | keystore + `--release` + `--split-per-abi` |

### 6.2 Interoperabilidad (post-Sprint 4 / fase institucional) — BLOQUEADO

No es Sprint 4 y **no se puede resolver escribiendo código todavía**. Depende de
tres *gates* documentados en
[`entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md`](entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md):

1. **Gate 1 — Terminología validada** (CIE-10/11, LOINC/UCUM, perfiles IHCE):
   desbloquea el esqueleto de `FhirMapperService` + tests.
2. **Gate 2 — Socio con endpoint sandbox:** desbloquea `ApiStrategy` real + outbox.
3. **Gate 3 — Consentimiento extendido aprobado:** desbloquea el envío real.

**Regla:** si un gate no se cumple, **no se escribe código** de esa fase. Hoy no
existen `FhirMapperService`, `ApiStrategy` ni tests FHIR. La sincronización API y
el enrutamiento SMS a centros de salud pertenecen a esta fase institucional, no
al Sprint 4 técnico.

### 6.3 Validación en campo y capacitación (2027-1)

| # | Tarea | Notas |
|---|---|---|
| 1 | Validación en 3 rancherías piloto (Manaure/Uribia) | con promotores y Uniguajira |
| 2 | Capacitación de gestores y estudiantes | talleres + guía en español/wayuunaiki |
| 3 | Articulación con PMA, Baylor y Secretaría | canales de notificación y brigadas |

---

## 7. Deudas técnicas conocidas

- **`historial_screen._recargar`**: usa `setState(() => _futuro = nuevo)`, que
  devuelve un `Future` y Flutter rechaza en debug. Detectado en el Bloque D (se
  corrigió en Alertas). No se tocó por la regla de no refactorizar Sprint 1/2;
  pendiente de mantenimiento.
- **SMS sin destinatario**: por diseño hasta que exista API/configuración de
  centros de salud. Sin `SEND_SMS`, sin `SharedPreferences`.
- **Sin cifrado local**: los datos de menores están en SQLite en claro. Aceptable
  para prototipo académico, no para producción.
- **Tabla DEMO**: el cálculo sigue usando `who_referencia_demo` (no las tablas OMS
  completas); el aviso académico está en "Acerca de".
- **Emulador**: Google Messages abre en modo *onboarding*, por lo que el cuerpo
  del SMS no siempre se ve en el compositor; el intent y el `body` son correctos.
- **Compañero de equipo**: falta agregarlo como colaborador de GitHub si va a
  hacer commits.

---

## 8. Cómo se verificó (repetir antes de cada entrega)

1. `flutter analyze` → sin observaciones.
2. `flutter test` → **85/85**.
3. `dart format --set-exit-if-changed lib test tool` → sin cambios.
4. Emulador: login → registrar infante → evaluación → semáforo → cerrar app →
   reabrir → historial intacto; generar CSV/PDF; encolar y enviar una alerta;
   abrir "Zonas en riesgo".
5. Clonar el repo en `/tmp` y correr `flutter test` desde el clon.

Evidencia visual: `entrega_avance1_nutrilaguajira/screenshots/`
(`sprint2_gps/`, `sprint3_reportes/`) y los resúmenes
`EVIDENCIAS_SPRINT2.md` / `EVIDENCIAS_SPRINT3.md`.

---

## 9. Defectos ya corregidos (no reintroducir)

1. `ListTileThemeData.titleTextStyle` sin `color` → nombre del infante invisible.
2. Evaluación recién creada sin `ninoNombre`/`comunidad` → "Comunidad —" en el
   resultado.
3. Borde Z = −2 con error de coma flotante → clasificaba ROJO mostrando −2.00.
4. "La talla es obligatorio" → concordancia de género en validadores.
5. Date picker en inglés → `flutter_localizations` con `locale: es`.
6. Tildes faltantes en textos visibles y en la semilla.
7. `setState` con callback que devuelve `Future` en la pantalla de alertas →
   corregido con bloque `{ ... }` (la misma deuda existe en `historial_screen`).

---

## 10. Contacto y equipo

- Autor del repo: `eabarriosTGC` (LinuxeroGuajiro).
- Compañero de equipo: **pendiente** de agregar como colaborador / de registrar
  los hallazgos que reporte desde `COMO_PROBAR.md`.
