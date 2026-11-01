# Cómo probar el Avance 1 (guía para el equipo)

Todo lo necesario para instalar el APK, probar el flujo completo y reportar
hallazgos sin preguntar nada.

---

## 1. Descargar e instalar el APK

**Descarga directa:**
https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.1.0-avance1/app-debug.apk

- **Requiere Android 7.0 (API 24) o superior.** Probado en Android 16 (API 36).
- Pesa **166 MB** porque es un APK universal con las tres arquitecturas
  (`arm64-v8a`, `armeabi-v7a`, `x86_64`): sirve para teléfono real y emulador.
- `applicationId`: `co.edu.uniguajira.nutrilaguajira` · versión `1.0.0`

**Integridad de la descarga** (opcional, para confirmar que bajó completo):

```
SHA256: b2c8f939fc4ada208d8935670e577dc89e40a9694f26e5624f94ffa4b105f319
```

Comprobar en el PC:

```bash
sha256sum app-debug.apk          # Linux
shasum -a 256 app-debug.apk      # macOS
certutil -hashfile app-debug.apk SHA256   # Windows
```

### Instalación en el teléfono

1. Copiar el APK al teléfono (cable, Drive, Telegram, lo que sea) y abrirlo.
2. Android pedirá permitir **"instalar apps de fuentes desconocidas"** para la
   app desde la que lo abriste (Archivos, Chrome, etc.). Concederlo.
3. Si aparece **Play Protect: "No se pudo analizar la app"** o "app no segura":
   tocar **"Instalar de todas formas"**. Es normal: es un APK de **depuración**
   firmado con la clave de debug de Flutter, no con una clave de publicación.
4. Abrir **NutriLaGuajira**.

### Instalación por USB (alternativa)

```bash
adb install -r app-debug.apk
adb shell am start -n co.edu.uniguajira.nutrilaguajira/.MainActivity
```

### Desinstalar

Desinstalar la app **borra la base de datos local**: todos los infantes y
tamizajes viven solo en el teléfono (no hay nube). Si quieres empezar de cero,
desinstala y vuelve a instalar; la semilla se recrea sola.

---

## 2. Entrar

| Usuario | Contraseña |
|---|---|
| `promotor` | `demo123` |

Hay un botón **"Usar credenciales demo"** que rellena los dos campos.
Probar también una clave incorrecta: debe salir "Usuario o contraseña incorrectos"
sin dejar entrar.

---

## 3. Casos que deben dar cada color

En **Nuevo tamizaje** elige el infante de la tabla y escribe exactamente estos
valores (la app acepta coma o punto decimal: `8,7` = `8.7`).

| Caso a verificar | Infante | Peso | Talla | MUAC | Edema | Resultado esperado |
|---|---|---|---|---|---|---|
| **Verde** | José Ángel Epieyú Uriana | `9,5` | `75` | `13,5` | No | VERDE · Z = **+0.32** |
| **Amarillo** | Yuliana Andrea Ipuana Pushaina | `8,7` | `80` | `12,2` | No | AMARILLO · Z = **−1.20** |
| **Rojo por Z** | Andrés David Jusayú González | `8,8` | `85` | `12,0` | No | ROJO · Z = **−2.27** |
| **Rojo por edema** | Andrés David Jusayú González | `12` | `86` | `12,4` | **Sí** | ROJO · Z = **+0.43** |

El último es el caso más importante: **el Z-score es normal (verde) pero el
edema bilateral fuerza ROJO**. Si ese da verde, hay un bug real.

Los cuatro Z-scores también se pueden reproducir sin la app:

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
dart run tool/calcular_demo.dart
```

---

## 4. Validaciones (deben rechazar)

| Prueba | Qué debe pasar |
|---|---|
| Peso `-5` | "El peso debe estar entre 0.5 y 30 kg" |
| Peso `0` o `35` | mismo mensaje |
| Talla `200` | "La talla debe estar entre 30 y 130 cm" |
| MUAC `2` | "El MUAC debe estar entre 5 y 25 cm" |
| Dejar campos vacíos y guardar | mensajes de obligatorio en cada uno |
| Registrar un infante con fecha de nacimiento futura | "La fecha de nacimiento no puede ser futura" |
| Registrar un infante de 60 meses o más | "El infante debe tener menos de 60 meses" |
| Abrir un infante de 60+ meses en el tamizaje | el botón "Calcular semáforo y guardar" queda **deshabilitado** |
| Documento repetido | "Ya existe un infante registrado con ese documento" |
| MUAC en un infante menor de 6 meses | el criterio dice "MUAC no evaluado: ... < 6 meses" |

---

## 5. Persistencia (la prueba clave)

1. Guarda un tamizaje nuevo.
2. **Cierra la app de verdad**: botón de recientes → deslizar la tarjeta hacia
   arriba (no alcanza con volver al inicio).
3. Vuelve a abrir y entra con `promotor` / `demo123`.
4. Ve a **Historial**: el tamizaje tiene que estar ahí, con su color.

Si el registro desapareció, es un bug crítico: repórtalo con la marca del
teléfono y la versión de Android.

---

## 6. Correr el proyecto y los tests

```bash
git clone https://github.com/eabarriosTGC/NutriLaGuajira.git
cd NutriLaGuajira/entrega_avance1_nutrilaguajira/nutrilaguajira
flutter pub get
flutter test      # 45 pruebas: motor, validadores, widget y SQLite real
flutter run       # requiere dispositivo o emulador Android conectado
```

En este equipo dieron: `flutter analyze` sin observaciones y **45/45 tests en
verde**.

---

## 7. Cómo reportar un hallazgo

Abre un *issue* en el repo (o mándalo por el chat) con esta plantilla:

```
Pantalla:        (login / menú / evaluación / resultado / historial / acerca de)
Pasos:           1) ... 2) ... 3) ...
Datos usados:    peso=..., talla=..., MUAC=..., edema=..., edad=...
Esperado:        ...
Obtenido:        ...
Captura:         (adjunta)
Dispositivo:     marca/modelo · Android xx · APK v0.1.0-avance1
```

Sin los **datos usados** no se puede reproducir: el resultado depende del peso,
la talla, el sexo y la edad en meses.

---

## 8. Lo que NO es un bug (alcance del avance)

- **GPS, reportes PDF/CSV y SMS** aparecen bloqueados en el menú: son del
  próximo sprint, a propósito.
- **No hay sincronización ni respaldo en la nube**: todo es local.
- **La tabla de referencia es DEMO** (28 filas, 45–110 cm). No es validación
  clínica; la versión final usa las tablas OMS completas.
- **El login no tiene seguridad real**: la clave está en texto plano en SQLite,
  es una puerta de entrada del prototipo.
- **No se pueden editar ni borrar evaluaciones** desde la interfaz.
- Solo Android: no hay versión iOS.

---

## 9. Acceso al repositorio

El repositorio es **público**: no hace falta invitación para clonar ni para
descargar el APK del release. Si el equipo decide pasarlo a privado, hay que
agregar al compañero en *Settings → Collaborators* (con permiso de lectura o
escritura según si va a hacer commits).
