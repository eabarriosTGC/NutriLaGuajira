# CONTEXTO_OPENCODE — NutriLaGuajira

> **Para el agente:** lee este archivo completo antes de tocar código. Luego
> revisa `README.md`, `README_FIREBASE.md` y `DISENO_FIRESTORE.md`. El proyecto
> está en la carpeta `nutrilaguajira/` y ya funcionó de punta a punta con
> Firebase.

---

## 1. Resumen del proyecto

**NutriLaGuajira** es un prototipo académico Flutter de tamizaje rápido y
semáforo nutricional **offline-first** para comunidades rurales dispersas de La
Guajira (Colombia).

- El **cálculo clínico es 100 % local**: Z-score Peso/Talla, Talla/Edad,
  Peso/Edad y semáforo VERDE/AMARILLO/ROJO.
- **SQLite es la fuente de verdad local.** Firestore es solo canal de
  sincronización y respaldo.
- El prototipo **no sustituye diagnóstico médico**; usa tabla de referencia
  DEMO.

Stack:

- Flutter 3.47.7 · Dart 3.13.5
- `sqflite` (SQLite), `path`
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `connectivity_plus`, `shared_preferences`, `crypto`
- `intl`, `geolocator`, `path_provider`, `share_plus`, `open_filex`,
  `pdf`, `printing`, `url_launcher`

---

## 2. Estado actual (verificado)

- `flutter analyze` → **sin issues**.
- `flutter test` → **110 pruebas aprobadas**.
- `flutter build apk --debug` → **APK compilado**.
- Login con Firebase Auth probado con una cuenta real.
- Sincronización real a Firestore verificada:
  - 1 evaluación ROJO en
    `promotores/{uid}/evaluaciones/{uuid}`.
  - 1 alerta en `alertas_criticas/{uid}_{uuidEvaluacion}`.
- La app muestra en el Home el estado de sincronización y el contador de
  pendientes.
- El proyecto se empaquetó en un ZIP sin `build/`, `.dart_tool/`, `.idea/`,
  `android/local.properties` ni archivos de firma.

### Datos de Firebase ya configurados

- Proyecto: `nutrilaguajira`
- Número de proyecto: `158549952047`
- App Android: `1:158549952047:android:4918d994a533c638c768da`
- Paquete: `co.edu.uniguajira.nutrilaguajira`
- Firestore: base **`(default)`** (¡con paréntesis!), región `us-east1`,
  edición STANDARD, FIRESTORE_NATIVE.
- Reglas publicadas en el release `cloud.firestore`.
- Cuenta de prueba creada en Authentication → Users:
  `correoprueba@nutri.laguajira.com` (contraseña definida por el usuario; **no
  está escrita en el repo**).
- UID de referencia de esa cuenta: `YDWkkHh0Z4PhbCC010aL5KIXavy2`.
- Documento verificado:
  `promotores/YDWkkHh0Z4PhbCC010aL5KIXavy2/evaluaciones/eval-660f3a6d4ac62-b81c9bfec1a0169c`
- Alerta verificada:
  `alertas_criticas/YDWkkHh0Z4PhbCC010aL5KIXavy2_eval-660f3a6d4ac62-b81c9bfec1a0169c`

> ⚠️ **Error histórico que no se debe repetir:** crear una base llamada
> `default` (sin paréntesis). El SDK usa `(default)`. Si se crea mal, Firestore
> responde `The database (default) does not exist...`. La base correcta ya
> existe; no crear otra.

---

## 3. Arquitectura

```text
Formulario
  ↓ guarda en SQLite con sincronizado = 0
Repositorio (ninosPendientes / evaluacionesPendientes)
  ↓
FirestoreStrategy.sincronizar()
  ↓ verifica sesión Firebase + conectividad
FirestoreAlmacen.guardarLote() → WriteBatch (400 docs por lote)
  ↓ set(merge: true) + FieldValue.serverTimestamp()
  ↓ commit con timeout de 30 s
Repositorio.marcarSincronizados() → sincronizado = 1
  ↓
SyncManager actualiza el estado de la tarjeta (pendientes, en línea, última sync)
```

### Disparadores de sincronización

- Login exitoso.
- Guardar infante.
- Guardar evaluación.
- Cambio de conectividad offline → online (`connectivity_plus`).
- Volver a la app (`WidgetsBindingObserver`).
- Toque manual en la tarjeta de sincronización del Home.

### SQLite (esquema v5)

Tablas relevantes: `usuarios`, `ninos`, `evaluaciones`, `alertas_pendientes`,
`who_referencia_demo`, `who_referencia_edad_demo`.

Columnas añadidas para sincronización:

- `ninos`: `uuid`, `sincronizado INTEGER NOT NULL DEFAULT 0`, `updated_at`.
- `evaluaciones`: `uuid`, `updated_at` (ya tenía `sincronizado`).
- Migración v5 rellena `uuid` con `'nino-' || id` / `'eval-' || id` para datos
  antiguos y crea índices de sincronización.
- La semilla DEMO (3 infantes, 4 evaluaciones) se marca con
  `sincronizado = 1` para **no subir datos ficticios** a Firestore.

### Firestore

Rutas:

```text
promotores/{uid}/ninos/{uuid}
promotores/{uid}/evaluaciones/{uuid}
alertas_criticas/{uid}_{uuidEvaluacion}
```

- Cada documento incluye `promotorUid`, `origen: "nutrilaguajira-movil"` y
  `sincronizadoEn` (timestamp del servidor).
- Los ROJOS generan además la alerta global.
- `set(merge: true)` hace la sincronización idempotente.
- No se escriben documentos padre `promotores/{uid}`.
- No se suben PDF, imágenes ni adjuntos (no se usa Storage).

El detalle completo de campos y tipos está en
[`DISENO_FIRESTORE.md`](DISENO_FIRESTORE.md).

---

## 4. Archivos clave

### Servicios Firebase / sincronización

| Archivo | Responsabilidad |
|---|---|
| `lib/services/firebase_auth_service.dart` | Inicializa Firebase, activa persistencia offline de Firestore, login online, login offline con hash salado, sesión y logout. También imprime el mensaje claro si falta configuración. |
| `lib/services/firestore_strategy.dart` | `sincronizar()`: consulta pendientes, construye documentos, envía lotes, publica alertas ROJAS y marca sincronizados. Implementa `SincronizacionStrategy.enviar()` para alertas. |
| `lib/services/firestore_almacen.dart` | `AlmacenNube` + `FirestoreAlmacen`: `WriteBatch`, lotes de 400, `SetOptions(merge: true)`, `serverTimestamp`, timeout de 30 s. |
| `lib/services/sync_manager.dart` | Escucha conectividad, expone `ValueNotifier<EstadoSync>` (en línea, sincronizando, pendientes, última sync). |
| `lib/services/conectividad_service.dart` | Envoltura de `connectivity_plus`. |
| `lib/services/uuid_local.dart` | Genera ids estables para documentos remotos. |

### Datos

| Archivo | Responsabilidad |
|---|---|
| `lib/data/db_nutrilaguajira.dart` | Esquema SQLite, migraciones (v5), semilla DEMO, referencias CSV. |
| `lib/data/repositorio.dart` | Consultas: infantes, evaluaciones, reportes, pendientes, conteo y marcado de sincronizados. |
| `lib/data/models/nino.dart` | Modelo con `uuid`, `sincronizado`, `updatedAt`. |
| `lib/data/models/evaluacion.dart` | Modelo con `uuid`, `updatedAt`, `ninoUuid`. |
| `lib/data/models/alerta_pendiente.dart` | Cola local de alertas SMS (no se debe eliminar). |

### UI

- `lib/app_services.dart`: localizador de dependencias (`repo`, `nutricion`,
  `alertas`, `auth`, `firestore`, `sync`) y `Sesion` (UID, en línea, Firebase).
- `lib/main.dart`: arranque; Firebase se inicializa dentro de `AppServices.init()`
  para no bloquear el primer frame.
- `lib/screens/login_screen.dart`: login con correo o usuario demo.
- `lib/screens/home_screen.dart`: tarjeta de sincronización, disparadores y
  logout.
- `lib/screens/nino_form_screen.dart` y `evaluacion_form_screen.dart`: guardan
  y disparan sincronización best-effort.
- `lib/screens/detalle_evaluacion_screen.dart`: muestra si está sincronizada.

### Configuración

- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json` (vacío por ahora)

### Pruebas

- `test/firestore_sync_test.dart`: pruebas del canal SQLite → Firestore con
  nube falsa (no requiere Firebase real).
- `test/db_migracion_test.dart`, `test/db_persistencia_test.dart`,
  `test/alerta_service_test.dart`, pruebas de pantallas, etc.
- Total actual: **110 pruebas**.

### Documentación

- `README.md` — arranque y estructura.
- `README_FIREBASE.md` — configuración de Firebase, credenciales, pruebas y
  troubleshooting.
- `DISENO_FIRESTORE.md` — diseño completo de la base Firestore de
  NutriLaGuajira.
- `DISENO_MOTOTRACK_RTDB.md` — **otro caso** (MotoTrack / Realtime Database),
  no forma parte de la app; es documentación de adaptación.

---

## 5. Reglas de seguridad

`firestore.rules`:

```text
match /promotores/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}

match /alertas_criticas/{alertaId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null
                && request.resource.data.promotorUid == request.auth.uid;
  allow update, delete: if request.auth != null
                        && resource.data.promotorUid == request.auth.uid;
}

match /{document=**} { allow read, write: if false; }
```

- Aísla a cada promotor en su carpeta.
- Las alertas las puede leer cualquier autenticado (panel central), pero solo
  el autor las modifica.
- **Limitación:** un panel central no puede leer las evaluaciones de todos los
  promotores ni marcar alertas como atendidas sin un rol/custom claim. Está
  documentado como siguiente fase.

Publicar reglas:

```bash
firebase login
firebase use nutrilaguajira
firebase deploy --only firestore:rules
```

> Ese comando ya funciona. Si algún día se recrea la base, debe ser
> `firebase firestore:databases:create "(default)" --location us-east1`.

---

## 6. Comportamientos y limitaciones conocidas

1. **Cuenta demo `promotor` / `demo123`** se valida contra SQLite y **no
   sincroniza** (UID local; las reglas exigen Firebase Auth). Es solo para
   probar sin internet.
2. **Login offline** con correo requiere haber iniciado sesión al menos una vez
   con red en ese dispositivo. Al cerrar sesión se borra el hash local, por lo
   que se necesita red para el siguiente login.
3. **Solo subida:** la app no descarga datos de Firestore ni restaura SQLite en
   un dispositivo nuevo (Caso 5 pendiente).
4. **Semilla no se sube:** los 3 infantes y 4 evaluaciones DEMO tienen
   `sincronizado = 1`. Solo se sincronizan registros nuevos o editados.
5. **Sincronización silenciosa:** si falla (sin red, permisos, timeout), el
   registro queda `sincronizado = 0` y se reintenta. No se debe lanzar un error
   bloqueante al usuario.
6. **Timeout de 30 s por lote** para no dejar la sincronización colgada.
7. **Sin Firebase Storage**, sin PDF/imágenes en la nube.
8. **`android/local.properties` no está en el repo/ZIP.** Flutter/Android
   Studio lo regeneran. No commitearlo.
9. **No commitear** `android/key.properties`, `*.jks`, `*.keystore`, `build/`,
   `.dart_tool/`, `.idea/`.
10. **`google-services.json` y `lib/firebase_options.dart`** sí están incluidos
    (configuración pública de Firebase). No contienen contraseñas.
11. **Índices:** `firestore.indexes.json` está vacío. Si se implementa el panel
    central, agregar el índice compuesto `alertas_criticas(atendida ASC,
    fecha DESC)` que aparece en `DISENO_FIRESTORE.md`.
12. **Emulador/AVD:** en este PC se creó `NutriLaGuajiraDebug` (Pixel 7, API 36,
    12 GB de datos, 4 GB RAM) porque el AVD original estaba lleno. Ese AVD es
    local y no viaja en el ZIP.
13. **Pruebas en Windows:** el test de PDF omite `pdftotext` si no existe
    (corrección de portabilidad ya aplicada).

---

## 7. Cómo trabajar en el PC de casa

Requisitos: Flutter 3.47.7 o compatible, Android Studio + SDK, Java 21,
`firebase-tools` (opcional, solo para reglas).

```bash
# 1. Descomprimir y entrar
cd nutrilaguajira

# 2. Dependencias
flutter pub get

# 3. Verificar
flutter analyze
flutter test

# 4. Ejecutar
flutter run

# 5. Compilar APK
flutter build apk --debug
```

Si falla por SDK de Android:

```bash
flutter doctor
# Abrir Android Studio → Settings → Android SDK
# y dejar que se genere android/local.properties
```

Para Firebase:

```bash
firebase login
firebase use nutrilaguajira
firebase deploy --only firestore:rules
```

La base `(default)` y las reglas ya existen en la nube; no hace falta recrearlas.

---

## 8. Reglas para el agente (importante)

- **No reemplazar SQLite como fuente de verdad local.** Firestore es una capa
  de transporte, no el motor de la app.
- **No mover el cálculo del Z-score ni el semáforo a la nube.** Todo debe
  seguir funcionando sin internet.
- **No eliminar `SmsIntentStrategy`.** La cola de alertas SMS sigue siendo el
  canal principal; Firestore es alternativo.
- **No añadir `await` que bloqueen el arranque** si Firebase no está
  configurado. La app debe abrir siempre con SQLite.
- **Mantener el manejo silencioso de errores de red.** Los pendientes se
  reintentan; no cerrar la app ni mostrar errores bloqueantes.
- **Si se cambia el esquema SQLite:** subir `versionEsquema`, agregar migración
  incremental y actualizar las pruebas. Nunca borrar datos del usuario.
- **Si se cambian reglas Firestore:** actualizar `firestore.rules`, probar en
  consola/emulador y desplegar. No abrir `promotores/{uid}` a otros roles sin
  diseñar el rol de brigada.
- **Mantener IDs de documento estables** (`uuid`), `set(merge: true)` y lotes
  de máximo 400.
- **No subir** `android/local.properties`, `key.properties`, `*.jks`,
  `*.keystore`, `build/`, `.dart_tool/`, `.idea/`.
- **No crear la base como `default`**: debe ser `(default)`.
- **Estilo:** el código, comentarios y textos de UI están en español. Mantener
  esa convención.
- **Antes de terminar un cambio:** ejecutar `flutter analyze` y `flutter test`.
  Si se tocó sync, ejecutar además
  `flutter test test/firestore_sync_test.dart`.

---

## 9. Backlog sugerido (siguiente fase)

1. **Panel central** (Flutter Web o web app ligera) que escuche
   `alertas_criticas` y muestre casos ROJOS en vivo.
2. **Rol de brigada** con Custom Claims para leer
   `promotores/*/evaluaciones` mediante `collectionGroup` y marcar alertas
   como atendidas.
3. **Restauración en dispositivo nuevo:** descargar el historial de Firestore y
   reconstruir SQLite (Caso 5).
4. **Notificaciones push (FCM)** para alertas ROJAS con la app cerrada.
5. **Índice compuesto** para `alertas_criticas(atendida, fecha)` cuando se
   implemente el panel.
6. **Bidireccionalidad / conflictos:** si se editara en varios dispositivos,
   definir merge por campo o LWW explícito con `updatedAt`.
7. **Pruebas con Firebase Emulator Suite** para Auth + Firestore (hoy las
   pruebas usan una nube simulada).
8. **Documento de perfil** `promotores/{uid}` con nombre, comunidad asignada y
   fecha de alta (opcional).
9. **MotoTrack:** si se implementa, es un proyecto aparte con Realtime Database;
   no mezclar con NutriLaGuajira. El diseño está en
   `DISENO_MOTOTRACK_RTDB.md`.

---

## 10. Snapshot de verificación

- Fecha: 2026-11-23.
- `flutter analyze`: sin issues.
- `flutter test`: 110/110.
- `flutter build apk --debug`: correcto.
- Prueba real:
  - Tamizaje de Andrés David Jusayú González: 8.8 kg, 85 cm, MUAC 12 cm,
    sin edema → **ROJO**, Z P/T **-2.27**.
  - Firestore: 1 evaluación + 1 alerta crítica.
  - Home: “Todo sincronizado”.
- ZIP de entrega generado en el PC de trabajo:
  `NutriLaGuajira-repo-actualizado-2026-11-23.zip`
  (sin `build/`, sin `.dart_tool/`, sin firmas).

---

## 11. Enlaces útiles

- Consola Firebase:
  https://console.firebase.google.com/project/nutrilaguajira/overview
- Firestore:
  https://console.firebase.google.com/project/nutrilaguajira/firestore/databases/-default-/data
- Authentication:
  https://console.firebase.google.com/project/nutrilaguajira/authentication/users
- Reglas:
  https://console.firebase.google.com/project/nutrilaguajira/firestore/databases/-default-/rules
