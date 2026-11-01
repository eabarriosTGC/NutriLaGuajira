# NutriLaGuajira — Avance 1: Tamizaje rápido y semáforo nutricional offline

Prototipo funcional en **Flutter + SQLite** para el control y la alerta temprana
de desnutrición infantil en comunidades rurales dispersas de La Guajira.

Este entregable corresponde al **Sprint 1 y parte del Sprint 2** del proyecto
(metodología Scrum, Escuela de Ingeniería de Sistemas). El alcance es
**tamizaje + semáforo + persistencia local + historial**. GPS, reportes
PDF/CSV, SMS y sincronización quedan como *próximo sprint* y aparecen
deshabilitados en la interfaz.

> **Aviso académico.** Prototipo académico. **No sustituye diagnóstico médico.**
> Las tablas de referencia están en **modo demostración (DEMO)**; la validación
> clínica final usará las tablas OMS completas y la normativa colombiana
> (Resolución 2465 de 2016 / Resolución 115 de 2026).

---

## 1. Qué quedó funcional

| Requisito | Estado |
|---|---|
| Login local con usuario demo | ✅ `promotor` / `demo123` (tabla `usuarios` en SQLite) |
| Registro de infante y tutor | ✅ nombres, apellidos, documento, fecha de nacimiento, sexo, tutor, comunidad |
| Edad automática en meses | ✅ calculada desde la fecha de nacimiento |
| Formulario antropométrico | ✅ peso, talla, MUAC, edema bilateral, fecha/hora automática |
| Cálculo de Z-score Peso/Talla | ✅ `NutricionService` con interpolación lineal sobre tabla DEMO |
| Semáforo nutricional | ✅ Verde / Amarillo / Rojo con reglas explícitas |
| Edema bilateral fuerza ROJO | ✅ criterio independiente del Z-score |
| Persistencia SQLite offline | ✅ `sqflite` + `path`, sin red ni backend |
| Historial por fecha descendente | ✅ con nombre, fecha, comunidad y chip de color |
| Detalle de evaluación | ✅ medidas, criterios aplicados y recomendación |
| Datos semilla | ✅ 3 infantes y 4 evaluaciones (verde, amarilla, roja, roja por edema) |
| Pruebas automatizadas | ✅ 45 tests (`flutter test`) |
| Pantalla "Acerca de" con disclaimer | ✅ |
| GPS, PDF/CSV, SMS, sincronización, push, iOS | ⛔ fuera de alcance (placeholders "próximo sprint") |

---

## 2. Requisitos

- **Flutter 3.x** (probado con Flutter 3.47.7 / Dart 3.13.5)
- **Android SDK** (probado con SDK 36, build-tools 36.0.0, JDK 25)
- Dispositivo o emulador Android (API 31 o superior)
- No requiere conexión a internet para funcionar

Dependencias de la app (livianas, ninguna de red):

```yaml
sqflite: ^2.4.5   # SQLite local
path: ^1.9.1      # rutas de archivos
intl: ^0.20.3     # formato de fechas
```

Solo para pruebas: `sqflite_common_ffi` (ejecuta SQLite real en el escritorio).

---

## 3. Cómo ejecutar

```bash
# 1. Entrar al proyecto Flutter
cd entrega_avance1_nutrilaguajira/nutrilaguajira

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en un dispositivo/emulador conectado
flutter run

# 4. Ejecutar las pruebas automatizadas
flutter test

# 5. Compilar el APK de depuración
flutter build apk --debug
#    salida: build/app/outputs/flutter-apk/app-debug.apk
```

Instalación directa en un dispositivo:

```bash
adb install -r app-debug.apk
```

La base de datos se crea y se siembra automáticamente en el primer arranque
(`nutrilaguajira.db`). Si se desinstala la app, los datos locales se borran.

### Credenciales demo

| Usuario | Contraseña |
|---|---|
| `promotor` | `demo123` |

La pantalla de login tiene un botón **"Usar credenciales demo"** que rellena
los campos para la exposición.

---

## 4. Estructura del proyecto

```
entrega_avance1_nutrilaguajira/
├── README.md                        ← este archivo
├── demo_script.md                   ← guion de exposición de 3 minutos
├── informe_avance1.md               ← informe corto del avance
├── assets/who_referencia_demo.csv   ← copia de la tabla DEMO (referencia)
├── screenshots/                     ← capturas de la app en ejecución
├── app-debug.apk                    ← APK de depuración (si se incluye)
└── nutrilaguajira/                  ← proyecto Flutter
    ├── assets/who_referencia_demo.csv
    ├── lib/
    │   ├── main.dart                ← arranque, tema y pantalla de carga
    │   ├── app_services.dart        ← localizador de dependencias + sesión
    │   ├── data/
    │   │   ├── db_nutrilaguajira.dart   ← esquema SQLite, semilla, referencias
    │   │   ├── repositorio.dart         ← consultas (login, niños, evaluaciones)
    │   │   └── models/                  ← Nino, Usuario, Evaluacion, ReferenciaWho
    │   ├── services/
    │   │   ├── nutricion_service.dart   ← MOTOR de cálculo (puro, testeable)
    │   │   ├── validadores.dart         ← validaciones de formulario
    │   │   ├── edad.dart                ← edad en meses
    │   │   ├── fechas.dart              ← formato de fechas (intl)
    │   │   ├── referencias_csv.dart     ← parser del CSV (Dart puro)
    │   │   └── referencias_loader.dart  ← carga del asset
    │   ├── screens/                 ← login, home, selección, infante,
    │   │                              evaluación, resultado, historial,
    │   │                              detalle y acerca de
    │   ├── theme/                   ← tema Material 3 y colores del semáforo
    │   └── widgets/                 ← componentes reutilizables
    ├── test/
    │   ├── nutricion_service_test.dart     ← 20 tests del motor
    │   ├── validadores_test.dart           ← validaciones
    │   ├── evaluacion_form_widget_test.dart← widget test del formulario
    │   └── db_persistencia_test.dart       ← SQLite real + persistencia
    └── tool/calcular_demo.dart      ← recalcula los casos semilla (apoyo)
```

---

## 5. Modelo de base de datos

```sql
usuarios(id, usuario UNIQUE, clave, nombre)

ninos(id, nombres, apellidos, documento UNIQUE, fecha_nacimiento,
      sexo, tutor, comunidad, created_at)

evaluaciones(id, nino_id → ninos(id) ON DELETE CASCADE, fecha, edad_meses,
             peso_kg, talla_cm, muac_cm, edema, z_peso_talla,
             clasificacion, color, observacion, sincronizado)

who_referencia_demo(id, sexo, talla_cm, mediana, de,
                    UNIQUE(sexo, talla_cm))
```

Notas de implementación:

- Las fechas se guardan como ISO-8601 (`TEXT`), lo que permite ordenar el
  historial directamente en SQL (`ORDER BY fecha DESC`).
- `color` guarda la clave estable (`verde` / `amarillo` / `rojo`) para que la
  interfaz pinte sin volver a calcular.
- `sincronizado` queda en `0`: no hay sincronización en este avance.
- `PRAGMA foreign_keys = ON` está activo, de modo que borrar un infante
  elimina sus evaluaciones.

---

## 6. Cálculo del Z-score y semáforo

### 6.1 Interpolación sobre la tabla

La tabla tiene filas por sexo y talla (`mediana` y `de` del peso). Para una
talla `T`:

```
Si T coincide exactamente con una fila  → se usa esa fila tal cual.
Si T cae entre dos filas (T0 < T < T1)   → factor = (T - T0) / (T1 - T0)
                                          mediana = m0 + (m1 - m0) * factor
                                          de      = d0 + (d1 - d0) * factor
Si T está fuera del rango tabulado       → se usa el extremo más cercano.
```

Ejemplo real de la app: talla 77 cm (masculino) cae entre 75 cm (9.20 / 0.95) y
80 cm (10.20 / 1.00) → mediana 9.60 kg, DE 0.97 kg.

### 6.2 Cálculo

```
Z = (peso_kg − mediana) / de
```

El Z se clasifica **redondeado a 2 decimales**, que es la misma precisión que
se muestra y se guarda. Esto evita que el error de coma flotante mueva un caso
límite (por ejemplo `-2.0000000000000009`, que en pantalla se lee `-2.00`)
a la categoría siguiente.

### 6.3 Reglas de clasificación

| Condición | Resultado |
|---|---|
| Edema bilateral = sí | **ROJO** (criterio independiente del Z) |
| Z < −3 | **ROJO** — desnutrición aguda severa |
| −3 ≤ Z < −2 | **ROJO** — desnutrición aguda moderada |
| −2 ≤ Z < −1 | **AMARILLO** — riesgo de desnutrición |
| Z ≥ −1 | **VERDE** — adecuado |

MUAC (solo si la edad es **≥ 6 meses**; en menores de 6 meses se ignora):

| MUAC | Resultado |
|---|---|
| < 11.5 cm | **ROJO** |
| 11.5 – 12.5 cm | **AMARILLO** |

Cuando el Z-score y el MUAC no coinciden **se conserva el criterio más grave**
(criterio de seguridad: ante la duda, se deriva).

### 6.4 Tabla DEMO incluida

`assets/who_referencia_demo.csv` contiene 28 filas (14 por sexo) entre 45 y
110 cm de talla, con mediana y DE de peso. Está marcada como **DEMO** en el
propio archivo y en la pantalla "Acerca de". **No es validación clínica.**

Para reemplazarla por las tablas OMS completas:

1. Sustituir `assets/who_referencia_demo.csv` manteniendo las columnas
   `sexo,talla_cm,mediana,de`.
2. Borrar los datos de la app (desinstalar) o subir `versionEsquema` en
   `lib/data/db_nutrilaguajira.dart` con una migración que repueble
   `who_referencia_demo`.
3. No hay que tocar el motor: `NutricionService` recibe la tabla por
   inyección y solo depende de esas cuatro columnas.

### 6.5 Valores de los casos semilla (calculados con el motor real)

| Caso | Sexo | Edad | Peso | Talla | MUAC | Edema | Mediana / DE usadas | Z | Resultado |
|---|---|---|---|---|---|---|---|---|---|
| Verde | M | 11 m | 9.50 kg | 75.0 cm | 13.5 cm | No | 9.20 / 0.95 | **+0.32** | VERDE |
| Amarillo | F | 18 m | 8.70 kg | 80.0 cm | 12.2 cm | No | 9.90 / 1.00 | **−1.20** | AMARILLO |
| Rojo por Z | M | 24 m | 8.80 kg | 85.0 cm | 12.0 cm | No | 11.30 / 1.10 | **−2.27** | ROJO |
| Rojo por edema | M | 25 m | 12.00 kg | 86.0 cm | 12.4 cm | **Sí** | 11.52 / 1.12 (interp.) | **+0.43** | ROJO |

El último caso es el más demostrativo: el Z es normal (+0.43 → verde), pero el
edema bilateral fuerza ROJO. Estos valores se pueden reproducir con:

```bash
cd nutrilaguajira && dart run tool/calcular_demo.dart
```

---

## 7. Validaciones

| Campo | Regla |
|---|---|
| Edad del infante | 0 a 59 meses (fuera de rango se bloquea el cálculo) |
| Fecha de nacimiento | obligatoria, no futura, menor de 60 meses |
| Peso | 0.5 – 30 kg |
| Talla | 30 – 130 cm |
| MUAC | 5 – 25 cm |
| Nombres, apellidos, documento, tutor, comunidad | obligatorios |
| Documento del infante | único (evita duplicados) |

Los campos numéricos aceptan coma o punto decimal (`9,5` y `9.5`). El signo
menos se admite en el campo para que el validador lo rechace de forma explícita
con un mensaje, en lugar de descartarlo silenciosamente.

---

## 8. Pruebas

```bash
cd nutrilaguajira
flutter analyze   # sin observaciones
flutter test      # 45 tests, todos en verde
```

Cobertura por archivo:

| Archivo | Qué valida |
|---|---|
| `test/nutricion_service_test.dart` | casos **verde / amarillo / rojo por Z / rojo por edema**, desnutrición severa (Z < −3), bordes exactos (Z = −1 y Z = −2), interpolación lineal, MUAC ignorado en < 6 meses, MUAC que agrava, y rechazo de entradas fuera de rango |
| `test/validadores_test.dart` | peso negativo/cero/fuera de rango, talla imposible, MUAC, edad > 59 meses, fecha futura, coma decimal |
| `test/evaluacion_form_widget_test.dart` | pruebas de widget: campos vacíos, peso negativo + talla 200 cm + MUAC 2 cm, bloqueo con 60 meses |
| `test/db_persistencia_test.dart` | SQLite real: semilla (3 infantes / 4 evaluaciones con los 3 colores), login, orden del historial y **persistencia tras cerrar y reabrir la base** |

### Checklist manual (verificado en emulador Android)

- [x] La app abre sin conexión a internet.
- [x] Login con `promotor` / `demo123`; una clave incorrecta muestra error.
- [x] Registrar un infante nuevo y guardarlo.
- [x] Registrar una evaluación y ver el semáforo con su color.
- [x] El edema bilateral fuerza ROJO con Z normal.
- [x] Cerrar la app por completo, abrirla de nuevo y ver el historial intacto.
- [x] El historial muestra las evaluaciones ordenadas por fecha descendente.
- [x] El formulario rechaza peso negativo, talla de 200 cm y MUAC de 2 cm.
- [x] Un infante de 60 meses o más bloquea el cálculo.

Las capturas de pantalla de cada paso están en `screenshots/`.

---

## 9. Decisiones de diseño tomadas durante el avance

1. **Tabla DEMO en SQLite, no en código.** La tabla vive en la tabla
   `who_referencia_demo` y el motor se construye leyéndola, de modo que el
   reemplazo por la OMS real sea un cambio de datos y no de lógica.
2. **Semilla calculada con el motor.** Los datos de ejemplo no guardan colores
   escritos a mano: se evalúan con `NutricionService` al crear la base, así la
   semilla nunca puede quedar inconsistente con el cálculo.
3. **Criterio más grave entre Z y MUAC.** La especificación no define qué hacer
   cuando ambos criterios difieren; se optó por conservar el más grave
   (seguridad del paciente pediátrico).
4. **Z redondeado a 2 decimales para clasificar.** Coherencia entre lo que se
   muestra (`-2.00`) y la categoría asignada.
5. **Tema claro por defecto.** La app se usa en campo y a plena luz del día;
   el tema oscuro queda disponible si el sistema lo pide.
6. **Pantalla adicional de selección de infante.** La lista mínima de pantallas
   no contempla cómo elegir un infante ya registrado para un nuevo tamizaje; se
   agregó `SeleccionNinoScreen` para que un mismo infante acumule historial.
7. **Login contra la tabla `usuarios`.** Aunque se permitía hardcodear, se usó
   la tabla local para que el flujo sea el mismo que tendrá la versión final.

---

## 10. Limitaciones conocidas

- La tabla de referencia es **DEMO**: no sirve para diagnóstico real.
- No hay validación clínica, ni curvas completas, ni puntaje Z para Talla/Edad
  o Peso/Edad (solo Peso/Talla, como pide este avance).
- No hay GPS, mapas, reportes PDF/CSV, SMS, sincronización ni notificaciones.
- El login no tiene seguridad real (clave en texto plano, sesión en memoria).
- Solo Android; no se configuró iOS.
- No hay edición ni borrado de evaluaciones desde la interfaz (sí de infantes
  vía repositorio).
- Los reportes georreferenciados y la exportación de datos quedan para el
  próximo sprint.

---

## 11. Próximo sprint (fuera de este entregable)

- GPS y captura de coordenadas de la ranchería.
- Reportes georreferenciados (PDF/CSV).
- Alertas por SMS a los centros de salud.
- Sincronización offline-first con backend y resolución de conflictos.
- Tablas OMS completas y validación clínica con la normativa colombiana.

---

## 12. Capturas de pantalla

En `screenshots/` están las capturas tomadas con la app instalada en un
emulador Android en **modo avión** (sin red). El índice completo, con la
explicación de cada imagen, está en `screenshots/README.md`.

| Captura | Contenido |
|---|---|
| `01_login.png`, `01b_login_credenciales.png` | Login local y credenciales demo |
| `02_menu.png` | Menú principal con contadores y chips "próximo sprint" |
| `03_seleccion_infante.png` | Selección del infante a tamizar |
| `04_registro_infante.png` | Registro de infante con edad calculada |
| `05_evaluacion_llena.png`, `05b_evaluacion_edema.png` | Formulario de evaluación y edema activado |
| `06_resultado_amarillo.png` | **AMARILLO** · Z = −1.20 |
| `07_resultado_verde.png` | **VERDE** · Z = +0.32 |
| `08_resultado_rojo_edema.png` | **ROJO** con Z normal (+0.43) por edema bilateral |
| `09_historial.png` | Historial con chips de color, orden descendente |
| `10_detalle_evaluacion.png` | Detalle con la trazabilidad del cálculo |
| `11_acerca_de.png` | Aviso académico y limitaciones |
| `12_login_tras_cierre.png`, `13_historial_tras_reinicio.png` | Persistencia tras cerrar y reabrir la app |

Las capturas se tomaron con 4 infantes y 8 tamizajes: los 3 infantes y 4
evaluaciones de la semilla, más un infante y cuatro tamizajes registrados en
vivo durante la demostración. Las filas repetidas de un mismo infante son
historial de visitas, no duplicados.

## 13. Defectos encontrados en la verificación y corregidos

Ejecutar la app de verdad (emulador) —y no solo las pruebas automatizadas—
expuso seis defectos que ya están corregidos en esta entrega:

1. **Nombre del infante ilegible** en la lista de selección: el
   `ListTileThemeData.titleTextStyle` no declaraba color y el texto salía casi
   blanco sobre tarjeta clara. Se fijó `esquema.onSurface`.
2. **"Comunidad —" en la pantalla de resultado**: la evaluación recién creada
   no llevaba nombre ni comunidad (esos campos venían del JOIN del historial).
   Ahora se copian del infante al construir el registro.
3. **Borde de clasificación Z = −2**: el cálculo en coma flotante daba
   `-2.0000000000000009` y clasificaba ROJO mientras la pantalla mostraba
   `-2.00`. Se clasifica con el Z redondeado a 2 decimales y la interpolación
   exacta ya no pasa por el factor 1.0 de la fila vecina.
4. **Concordancia de género** en los mensajes de validación
   ("La talla es obligatorio" → "La talla es obligatoria").
5. **Selector de fecha en inglés**: se agregó `flutter_localizations` con
   `locale: es`, de modo que el calendario, los botones y los tooltips salen en
   español.
6. **Tildes faltantes** en textos visibles ("desnutricion", "remision",
   "dias", "progresión") corregidas en toda la interfaz y en los datos semilla.

## 14. Créditos

Proyecto académico — Escuela de Ingeniería de Sistemas.
Metodología Scrum (3 sprints). Este entregable: Sprint 1 + parte del Sprint 2.
Licencia del repositorio: MIT.
