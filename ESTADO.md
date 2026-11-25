# Estado del proyecto — NutriLaGuajira

Documento de traspaso para retomar el trabajo sin reconstruir contexto.
Última actualización: **2026-11-25** (Firebase operativo: reglas desplegadas y `.firebaserc`; sesión pausada).

> **Nota honesta.** El Sprint 3 entrega el módulo de **reportes (CSV/PDF),
> alertas SMS y zonas en riesgo**. La **validación en campo** con promotores se
> ejecuta en **2027-1**, conforme al plan de trabajo, y no en este sprint.
>
> **Sincronización integrada (2026-11-24).** Firebase Auth + Cloud Firestore:
> subida por lotes, alertas ROJAS y estado en el Home. **SQLite sigue siendo la
> fuente de verdad** y la app funciona sin red. Detalle en
> [`nutrilaguajira/README_FIREBASE.md`](entrega_avance1_nutrilaguajira/nutrilaguajira/README_FIREBASE.md).
>
> **Sprint 4 técnico cerrado (post-entrega).** Talla/Edad y Peso/Edad con tabla
> **DEMO (LMS)**, `historial_screen` corregido y PDF con TTF local. El plan de
> trabajo está entregado; la fase de implementación en campo se ejecuta en
> **2027-1**. **APK de distribución publicado:** `v0.4.0-sprint4` (release
> firmado, split por ABI).

---

## 1. Dónde estamos

| Dato | Valor |
|---|---|
| Repo | https://github.com/eabarriosTGC/NutriLaGuajira (público, MIT) |
| Rama | `main` |
| HEAD | el último commit de `main` (ver `git log -1`); esta tabla no se actualiza en cada commit |
| Tag / release | `v0.4.0-sprint4` (APK de distribución, release firmado) · `v0.3.0-sprint3` (debug) · `v0.1.0-avance1` (histórico) |
| Estado | **Sprint 1–4 técnicos completos** + **Firebase Auth + Firestore** (esquema v5, reglas desplegadas) + **APK `v0.4.0-sprint4`** (sin Firebase): `flutter analyze` limpio, **110/110 tests**, formato limpio |
| Evidencias | `entrega_avance1_nutrilaguajira/EVIDENCIAS_SPRINT{2,3,4}.md` + `screenshots/` |

Alcance funcional: login local, registro de infantes/tutores, evaluación
antropométrica con **Z Peso/Talla**, **Z Talla/Edad** y **Z Peso/Edad**
(informativos, tabla DEMO), semáforo, **captura opcional de GPS**, historial,
**reportes CSV/PDF**, **alertas SMS** y **zonas en riesgo**. Pendiente:
reemplazar las tablas DEMO por las OMS oficiales (Gate 1), sincronización por API,
validación en campo y capacitación (2027-1).

---

## 2. Cómo retomar

```bash
git clone https://github.com/eabarriosTGC/NutriLaGuajira.git
cd NutriLaGuajira/entrega_avance1_nutrilaguajira/nutrilaguajira

flutter pub get
flutter test        # debe dar 110/110 antes de tocar nada
flutter analyze     # debe estar limpio
dart format --output=none --set-exit-if-changed lib test tool

flutter run         # dispositivo/emulador Android
```

Entorno que **debe** estar así (probado el 2026-11-25):

| Pieza | Valor |
|---|---|
| Flutter / Dart | 3.47.9 (stable) / 3.13.7 |
| Java / keytool | `/opt/android-studio/jbr/bin` (no está en PATH por defecto) |
| `firebase` | 15.37.0 en `~/.local/bin/firebase` |
| `flutterfire` | 1.5.0 en `~/.local/bin/flutterfire` (symlink a `~/.pub-cache/bin`) |
| Keystore | `~/nutrilaguajira-keystore/nutrilaguajira.jks` (**fuera del repo**) |
| Secretos | keyring libsecret: `servicio=nutrilaguajira clave=keystore` y `clave=gpg-backup` |
| AVD | **no hay uno de este proyecto**; existe `moteros_test` (otro proyecto) |

Para publicar una versión nueva del APK (firma real + split por ABI):

```bash
export PATH="$PATH:/opt/android-studio/jbr/bin"
# 1. subir version en pubspec.yaml (version: X.Y.Z+N)
flutter build apk --release --split-per-abi
sha256sum build/app/outputs/flutter-apk/*release.apk
/home/x/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
gh release create vX.Y.Z <los 3 apk> --title "..." --notes-file ...
```

> El certificado de firma es `B4:C9:B4:92…92:F5` y **no cambia** al rotar la
> contraseña del keystore. Los APK publicados se actualizan con la misma firma.

El APK **no** se commitea (está en `.gitignore`): va como asset del release.

---

## 3. Mapa del código (dónde tocar cada cosa)

```
lib/
  main.dart                 arranque, tema, locale es, pantalla de carga
  app_services.dart         localizador de dependencias + Sesion en memoria
  data/
    db_nutrilaguajira.dart  esquema v4, semilla, migraciones, carga de CSVs
    repositorio.dart        consultas (login, infantes, evaluaciones, reportes,
                            alertas, zonas en riesgo)
    models/                 Nino, Usuario, Evaluacion, ReferenciaWho,
                            ReferenciaEdad, EvaluacionReporte,
                            AlertaPendiente, ResumenZona
  services/
    nutricion_service.dart  MOTOR de cálculo P/T, T/E y P/E (LMS)
    validadores.dart        reglas de formulario (rangos, fecha, edad)
    edad.dart               meses cumplidos
    fechas.dart             formato dd/MM/yyyy (intl)
    referencias_csv.dart    parser del CSV P/T (Dart puro)
    referencias_loader.dart acceso al asset P/T
    referencias_edad_csv.dart    parser del CSV LMS por edad (Dart puro)
    referencias_edad_loader.dart acceso al asset LMS por edad
    localizacion_service.dart GPS opcional (geolocator) + Coordenada
    reporte_csv_service.dart  filtros + CSV (BOM UTF-8, RFC 4180)
    reporte_pdf_service.dart  PDF con TTF local (encabezado, resumen, pie)
    sincronizacion_strategy.dart  interfaz (ApiStrategy FHIR sigue sin implementar)
    firebase_auth_service.dart    Firebase Auth + respaldo offline (hash salado)
    firestore_strategy.dart       sincronización SQLite -> Firestore + alertas ROJAS
    firestore_almacen.dart        WriteBatch (400 docs), set(merge: true), timeout 30 s
    sync_manager.dart             conectividad + ValueNotifier<EstadoSync>
    conectividad_service.dart     envoltura de connectivity_plus
    uuid_local.dart               ids estables para documentos remotos
    sms_intent_strategy.dart  envío por intent `sms:?body=` (sin SEND_SMS)
    alerta_service.dart       encolado en ROJO, envío y reintento
  screens/                  login, home, seleccion, nino_form, evaluacion_form,
                            resultado, historial, detalle, acerca_de,
                            reportes, reporte_pdf_preview, alertas,
                            zonas_riesgo, zona_detalle
  theme/                    tema Material 3 + colores del semáforo
  widgets/componentes.dart  botones, chips, PanelVacio, FilaDato
test/                       110 pruebas (motor, validadores, widget, SQLite real,
                            migración, reportes, alertas, zonas, T/E-P/E)
tool/calcular_demo.dart     recalcula los casos semilla con el motor real
```

Assets de referencia: `assets/who_referencia_demo.csv` (P/T **DEMO**),
`assets/who_edad_demo.csv` (LMS por edad **DEMO**, reemplazable por la OMS sin
tocar código) y `assets/fonts/` (Roboto Regular/Bold, Apache 2.0, para el PDF).

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

**Calidad:** `flutter test` 110/110, `flutter analyze` 0 issues, `dart format`
limpio.

---

## 6. Sprint 4 técnico — COMPLETO / interoperabilidad BLOQUEADA

> **Sprint 4 técnico cerrado.** El plan de trabajo está entregado. La fase de
> implementación en campo se ejecuta en **2027-1**.

### 6.1 Entregado en el Sprint 4 técnico

| # | Feature | Estado |
|---|---|---|
| 1 | Talla/Edad y Peso/Edad con tablas **DEMO (LMS)** + migración v4 | ✅ (100 % DEMO / 40 % oficial) |
| 2 | `historial_screen` (`setState` con `Future`) | ✅ corregido + 2 tests |
| 3 | TTF local para el PDF (Roboto; `—`, `«»`, `¿¡`) | ✅ |

### 6.2 Pendientes técnicos post-Sprint 4

| # | Tarea | Notas |
|---|---|---|
| 1 | Tablas OMS completas (P/T y por edad) | reemplazar los CSV DEMO; es el **Gate 1** del roadmap |
| 2 | Editar / borrar evaluaciones | hoy solo inserción y lectura |
| 3 | ~~APK de distribución~~ ✅ **publicado `v0.4.0-sprint4`** | release firmado + `--split-per-abi` (3 APK) |

### 6.3 Interoperabilidad (fase institucional) — BLOQUEADA

No se puede resolver escribiendo código todavía. Depende de tres *gates*
documentados en
[`entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md`](entrega_avance1_nutrilaguajira/ROADMAP_INTEROPERABILIDAD.md):

1. **Gate 1 — Terminología validada** (CIE-10/11, LOINC/UCUM, perfiles IHCE):
   desbloquea el esqueleto de `FhirMapperService` + tests.
2. **Gate 2 — Socio con endpoint sandbox:** desbloquea `ApiStrategy` real + outbox.
3. **Gate 3 — Consentimiento extendido aprobado:** desbloquea el envío real.

**Regla:** si un gate no se cumple, **no se escribe código** de esa fase. Hoy no
existen `FhirMapperService`, `ApiStrategy` ni tests FHIR. La sincronización API y
el enrutamiento SMS a centros de salud pertenecen a esta fase institucional.

### 6.4 Validación en campo y capacitación (2027-1)

Materiales de trabajo en
[`entrega_avance1_nutrilaguajira/fase_campo/`](entrega_avance1_nutrilaguajira/fase_campo/README.md)
(**borradores v0.1**, pendientes de aprobación):

| Documento | Contenido |
|---|---|
| `PROTOCOLO_VALIDACION.md` | piloto en 3 rancherías, 8 criterios de éxito, ética y análisis |
| `GUIA_USUARIO.md` | guía del promotor en español (2 páginas) |
| `GUIA_USUARIO_WAYUUNAIKI.md` | plantilla bilingüe; **traducción pendiente de hablantes nativos** |
| `CAPACITACION.md` | taller de 4 h, ejercicios y certificación práctica |
| `CONSENTIMIENTO_INFORMADO.md` | Ley 1581/8430, datos de menores y transferencia a terceros |
| `INSTRUMENTOS/` | F1–F6 y plantillas CSV |

| # | Tarea | Notas |
|---|---|---|
| 1 | Validación en 3 rancherías piloto (Manaure/Uribia) | con promotores y Uniguajira |
| 2 | Capacitación de gestores y estudiantes | talleres + guía en español/wayuunaiki |
| 3 | Articulación con PMA, Baylor y Secretaría | canales de notificación y brigadas |

### 6.5 Sincronización con Firebase (2026-11-24)

| Pieza | Estado |
|---|---|
| Firebase Auth (correo) + respaldo offline con hash salado | ✅ |
| Firestore: `promotores/{uid}/ninos`, `.../evaluaciones`, `alertas_criticas` | ✅ |
| Esquema SQLite **v5** (`uuid`, `sincronizado`, `updated_at`) + migración | ✅ |
| Subida por lotes (400), `set(merge: true)`, timeout 30 s | ✅ |
| Tarjeta de estado en Home + disparadores (login, guardar, conectividad, resume, manual) | ✅ |
| Reglas y configuración (`firestore.rules`, `firebase.json`, `google-services.json`) | ✅ |
| Semilla DEMO marcada `sincronizado = 1` (no se sube) | ✅ |

**Limitaciones:** solo subida (no restaura en un teléfono nuevo); la cuenta demo
no sincroniza; **interoperabilidad FHIR/API sigue bloqueada** (Gates 1–3). La
sincronización con Firestore **no es interoperabilidad**: es un canal propio.

> ⚠️ **Privacidad:** con cuenta institucional se envían datos de menores
> (nombres, documento, medidas, coordenadas) a **Google Cloud, `us-east1`**. Los
> documentos de `fase_campo/` ya lo declaran y exigen consentimiento explícito y
> aprobación del comité de ética antes del piloto.

---

## 7. Deudas técnicas conocidas

- **~~`historial_screen._recargar`~~** ✅ **corregido en el Bloque 2**: el `setState`
  usa bloque (`{ ... }`) y hay un widget test que verifica el refresco.
- **SMS sin destinatario**: por diseño hasta que exista API/configuración de
  centros de salud. Sin `SEND_SMS`, sin `SharedPreferences`.
- **Sin cifrado local**: los datos de menores están en SQLite en claro. Aceptable
  para prototipo académico, no para producción.
- **Tablas DEMO**: el cálculo usa `who_referencia_demo` (P/T) y
  `who_edad_demo` (T/E y P/E, LMS); no son las tablas OMS completas. El reemplazo
  por las oficiales es el **Gate 1** del roadmap. El aviso académico está en
  "Acerca de".
- **Emulador**: Google Messages abre en modo *onboarding*, por lo que el cuerpo
  del SMS no siempre se ve en el compositor; el intent y el `body` son correctos.
- **Compañero de equipo**: falta agregarlo como colaborador de GitHub si va a
  hacer commits.
- **Sincronización solo de subida**: no hay descarga ni restauración de SQLite en
  un dispositivo nuevo (Caso 5 del `CONTEXTO_OPENCODE.md`).
- **Firestore con datos identificables**: nombres y documento viajan a la nube;
  antes del piloto se requiere consentimiento extendido y acuerdo de tratamiento
  con Google.
- **APK publicado sin Firebase**: `v0.4.0-sprint4` no incluye la sincronización.

---

## 8. Cómo se verificó (repetir antes de cada entrega)

1. `flutter analyze` → sin observaciones.
2. `flutter test` → **110/110**.
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

## 11. Punto de reanudación (2026-11-25)

Sesión pausada aquí. Todo está commiteado y subido; no hay trabajo a medias.

### 11.1 Hecho y verificado

| Ítem | Evidencia |
|---|---|
| Firebase integrado (Auth + Firestore, esquema v5) | commit `615f56d`; 110/110; `flutter build apk --debug` OK |
| Firebase CLI autenticada y reglas publicadas | `coachingedwin@gmail.com`; `deploy --only firestore:rules` → *released* |
| Proyecto fijado | `.firebaserc` (commit `d8e25a9`) |
| Documentos de campo | `fase_campo/` (borradores v0.1; consentimiento v0.2 con la nube declarada) |
| Keystore | contraseña nueva, `.tar.gz` + `.gpg` verificados, secretos en keyring |

### 11.2 Pendiente, en orden sugerido

1. **Prueba real de login + sync** (no hecha: sin cuenta de prueba en un
   dispositivo). Checklist:
   - crear/iniciar sesión con un correo de Firebase en el teléfono;
   - modo avión → tamizar → ver "pendientes";
   - quitar modo avión → debe subir solo;
   - en consola: `promotores/{uid}/ninos`, `.../evaluaciones` y
     `alertas_criticas/{uid}_{uuid}` solo si hubo ROJO.
2. **Restringir la API key** en Google Cloud (package + SHA-1 de firma).
3. **Release `v0.5.0`** con Firebase (subir `version:` en `pubspec.yaml`).
4. **Distribuir el kit del keystore** a gestor + USB cifrado + nube, y verificar
   cada copia con `verificar-backup.sh`.
5. **Aprobación institucional** de protocolo/consentimiento + validación del
   wayuunaiki con hablantes nativos.
6. **Decidir R-03/R-04** (SMS con nombre del niño y sin destinatario fijo).

### 11.3 Comandos de reanudación

```bash
cd ~/dev/NutriLaGuajira && git pull
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter pub get
flutter analyze && flutter test          # 0 issues / 110/110
dart format --output=none --set-exit-if-changed lib test tool

firebase login:list                       # debe seguir coachingedwin@gmail.com
firebase deploy --only firestore:rules    # idempotente
```

### 11.4 Reglas que no se rompen

Resumen de `nutrilaguajira/CONTEXTO_OPENCODE.md` §8:

- SQLite es la **fuente de verdad**; Firestore es transporte. La app abre sin
  red y sin Firebase.
- El cálculo y el semáforo **nunca** se mueven a la nube.
- `SmsIntentStrategy` no se elimina.
- Errores de red **silenciosos**: quedan pendientes y se reintentan.
- Cambios de esquema → subir `versionEsquema` + migración + tests.
- Base `(default)` con paréntesis; no crear otra.
- No commitear `local.properties`, `key.properties`, `*.jks`, `build/`.

---

## 10. Contacto y equipo

- Autor del repo: `eabarriosTGC` (LinuxeroGuajiro).
- Compañero de equipo: **pendiente** de agregar como colaborador / de registrar
  los hallazgos que reporte desde `COMO_PROBAR.md`.
