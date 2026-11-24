# Firebase en NutriLaGuajira (Firestore + Auth)

Esta guía explica cómo dejar operativa la sincronización **sin romper el modo
offline**. La regla de oro de la arquitectura:

> **SQLite es la fuente de verdad local.** Firestore es solo el canal de
> transporte y respaldo. El cálculo del Z-score y el semáforo siguen siendo
> 100 % locales.

📐 El diseño detallado de colecciones, campos, tipos, relaciones, ejemplo real
de documentos y flujo de sincronización está en
[`DISENO_FIRESTORE.md`](DISENO_FIRESTORE.md).

---

## 1. Dependencias y estructura

Agregadas en `pubspec.yaml`:

| Paquete | Uso |
|---|---|
| `firebase_core` | Inicialización del SDK |
| `firebase_auth` | Login de cada promotor (UID) |
| `cloud_firestore` | Sincronización en lotes + alertas críticas |
| `connectivity_plus` | Detectar offline → online |
| `shared_preferences` | Guardar UID y hash salado para login offline |
| `crypto` | SHA-256 del hash local (nunca se guarda la clave) |

Archivos nuevos relevantes:

```
lib/services/firebase_auth_service.dart   login online + respaldo offline
lib/services/firestore_strategy.dart      sincronizar() e implements SincronizacionStrategy
lib/services/firestore_almacen.dart       WriteBatch sobre Firestore (abstraído para pruebas)
lib/services/sync_manager.dart            conectividad automática + contador pendientes
lib/services/conectividad_service.dart    envoltura de connectivity_plus
lib/services/uuid_local.dart              id estable para documentos remotos
firestore.rules                           reglas de seguridad
firestore.indexes.json                    índices (vacío por ahora)
```

`SmsIntentStrategy` **no se eliminó**: sigue siendo el canal por defecto de la
cola de alertas (`AppServices.alertas`). `FirestoreStrategy` además publica la
alerta en `alertas_criticas` durante la sincronización.

---

## 2. Colocar las credenciales de Firebase

1. Descarga `google-services.json` desde Firebase Console:
   **Configuración del proyecto → Tus apps → Android**.
2. Guárdalo exactamente en:

   ```
   android/app/google-services.json
   ```

3. Verifica que `android/app/google-services.json` corresponda al paquete
   `co.edu.uniguajira.nutrilaguajira` y al proyecto `nutrilaguajira`.
4. `lib/firebase_options.dart` ya existe. Si cambias de proyecto, regénéralo con:

   ```bash
   flutterfire configure
   ```

5. El plugin de Gradle ya está aplicado en
   `android/app/build.gradle.kts` (`com.google.gms.google-services`) y declarado
   en `android/settings.gradle.kts`.

> **Si falta `google-services.json`**, la app **no se cierra**: en la consola de
> Flutter verás un mensaje `[NutriLaGuajira] Firebase no está disponible...` y
> todo seguirá funcionando con SQLite en modo local.

---

## 3. Configurar Firebase Console

1. **Authentication → Sign-in method**: habilita **Correo electrónico/contraseña**.
2. **Authentication → Users → Add user**: crea un usuario de prueba, por ejemplo:

   ```
   Correo:      promotor1@nutrilaguajira.edu.co
   Contraseña:  Demo12345
   ```

   Ese correo es el que se escribe en la pantalla de login. No hace falta que el
   usuario confirme el correo para el piloto (puedes desactivar la verificación
   o confirmarlo manualmente).
3. **Firestore Database → Create database**: modo producción.
4. Publica las reglas:

   ```bash
   firebase login
   firebase use nutrilaguajira
   firebase deploy --only firestore:rules
   ```

   También puedes pegar el contenido de `firestore.rules` en
   **Firestore → Rules → Publish**.

> ⚠️ **La base debe llamarse exactamente `(default)`**, no `default`. El SDK
> de Flutter siempre usa `(default)`; si creas una base llamada `default` la
> app recibirá `The database (default) does not exist...`. Si usas la CLI:
>
> ```bash
> firebase firestore:databases:create "(default)" --location us-east1
> firebase deploy --only firestore:rules
> ```
>
> En este proyecto la base quedó creada en `us-east1` (no hay región de
> Firestore en Colombia; es la de menor latencia habitual desde La Guajira).

### Cuenta demo vs. cuenta Firebase

| Identificador | Dónde se valida | ¿Sincroniza? |
|---|---|---|
| `promotor` / `demo123` | Tabla `usuarios` de SQLite | **No** (UID local; las reglas exigen Auth) |
| `correo@dominio.com` | Firebase Auth | **Sí**, en `promotores/{uid}/...` |

La cuenta demo se conserva para calificar el avance sin Internet. Para ver la
sincronización usa un correo creado en Firebase Console.

---

## 4. Esquema de datos en Firestore

```
promotores/{uid}/ninos/{uuid}
  idLocal, uuid, nombres, apellidos, documento, fechaNacimiento, sexo,
  tutor, comunidad, createdAt, actualizadoEnLocal, promotorUid,
  origen, sincronizadoEn (serverTimestamp)

promotores/{uid}/evaluaciones/{uuid}
  idLocal, uuid, ninoUuid, ninoNombre, comunidad, fecha, edadMeses,
  pesoKg, tallaCm, muacCm, edema, zPesoTalla, zTallaEdad, zPesoEdad,
  clasificacion, color, observacion, lat, lng, alertaCritica,
  actualizadoEnLocal, promotorUid, origen, sincronizadoEn

alertas_criticas/{uid}_{uuidEvaluacion}
  promotorUid, ninoUuid, ninoNombre, comunidad, evaluacionUuid,
  severidad: "ROJO", clasificacion, color, fecha, edadMeses, pesoKg,
  tallaCm, muacCm, edema, lat, lng, atendida: false, origen
```

Notas:

- El `uuid` local (no el `id` autoincremental) es el id del documento. Así dos
  dispositivos no colisionan y reintentar es idempotente (`set(merge: true)`).
- Cada lote usa `WriteBatch` (máximo 400 escrituras por lote en este código).
- Los ROJOS generan además un documento en `alertas_criticas`, que el panel
  central podrá escuchar con `snapshots()`.
- Estrategia de conflictos: **última escritura gana** con `sincronizadoEn`
  (hora del servidor) y `actualizadoEnLocal`.
- No se usa Firebase Storage: no se suben PDF ni imágenes en esta fase.

---

## 5. Cómo probar la sincronización

### A. Flujo offline → online

1. Abre la app con el emulador/dispositivo **en modo avión**.
2. Inicia sesión con el **correo** creado en Firebase (la primera vez requiere
   red; después el hash local permite entrar offline).
3. Registra un infante y uno o dos tamizajes (incluye uno con edema o Z bajo
   para obtener ROJO).
4. Comprueba en la pantalla principal:
   - la tarjeta de sincronización dice **“Sin conexión”** y muestra los
     pendientes;
   - aún no hay documentos en Firestore.
5. Desactiva el modo avión. El listener de `connectivity_plus` dispara la
   sincronización automáticamente.
6. Verifica en Firebase Console → Firestore:

   ```
   promotores/{tu-uid}/ninos/{uuid}
   promotores/{tu-uid}/evaluaciones/{uuid}
   alertas_criticas/{tu-uid}_{uuidEvaluacion}   (solo si hubo ROJO)
   ```

7. La tarjeta debe pasar a **“Todo sincronizado”**. En SQLite,
   `evaluaciones.sincronizado = 1` y `updated_at` quedó con la marca del envío.

### B. Sincronización manual

Toca el icono de nube/sync en la tarjeta de la pantalla principal. Si estás
offline, los datos permanecen pendientes y la app no se cierra ni muestra un
error bloqueante.

### C. Consultas rápidas para el panel central

```dart
// Casos críticos vivos, más recientes primero
FirebaseFirestore.instance
    .collection('alertas_criticas')
    .where('atendida', isEqualTo: false)
    .orderBy('fecha', descending: true)
    .snapshots();
```

Para consultas por promotor (reglas actuales), el panel debe autenticarse con
una cuenta autorizada. En una siguiente fase conviene una colección agregada o
un rol de brigada en Custom Claims.

---

## 6. Reglas de seguridad

`firestore.rules` implementa:

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

Con esto, extraer el APK y la configuración no permite leer los datos de otros
promotores.

---

## 7. Manejo de errores y limitaciones

- **Fallo de red / permisos / configuración**: `FirestoreStrategy` captura la
  excepción, escribe un `debugPrint` y devuelve un resultado fallido. Los datos
  siguen con `sincronizado = 0` y se reintentan al recuperar red, al volver a la
  app o al pulsar el icono de nube.
- **Doble envío**: `set(merge: true)` + id de documento estable hacen la
  operación idempotente.
- **Login offline**: requiere haber iniciado sesión al menos una vez con red en
  ese dispositivo. Al cerrar sesión se borran UID, correo y hash local.
- **Seguridad del hash offline**: se guarda SHA-256 salado, nunca la contraseña.
  Si el modelo de amenaza crece, conviene sustituirlo por un token de refresco
  de Firebase o biometría del sistema.
- **Costos**: piloto académico dentro de la capa gratuita de Firestore
  (50 000 lecturas y 20 000 escrituras/día). Cada sincronización escribe solo
  registros pendientes.
- **No incluido**: panel web, notificaciones push, Firebase Storage y
  resolución automática de conflictos por campo.

---

## 8. Checklist de entrega

- [x] `firebase_core`, `firebase_auth`, `cloud_firestore`, `connectivity_plus`,
      `shared_preferences` y `crypto` en `pubspec.yaml`.
- [x] `FirebaseAuthService` con login online + respaldo offline.
- [x] `FirestoreStrategy implements SincronizacionStrategy`.
- [x] Guardado local marca `sincronizado = 0` (infantes y evaluaciones).
- [x] Sincronización por lotes a `promotores/{uid}/...` con `WriteBatch`.
- [x] Alerta ROJO en `alertas_criticas`.
- [x] Escucha de conectividad + sincronización al volver a la app.
- [x] Indicador de nube con pendientes en la pantalla principal.
- [x] `firestore.rules` y `firestore.indexes.json`.
- [x] Cierre de sesión limpia (`Firebase Auth` + `SharedPreferences`).
- [x] Pruebas automatizadas del canal SQLite → Firestore con nube simulada.
