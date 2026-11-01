# Informe — Avance 1: Tamizaje rápido y semáforo nutricional offline

**Proyecto:** NutriLaGuajira
**Entregable:** Sprint 1 + parte del Sprint 2
**Fecha:** noviembre de 2026
**Tecnología:** Flutter + SQLite (Android)
**Repositorio:** https://github.com/eabarriosTGC/NutriLaGuajira

---

## 1. Objetivo

Desarrollar un prototipo funcional de aplicación móvil **offline-first** que
permita a un promotor de salud:

1. autenticarse localmente en el dispositivo,
2. registrar infantes menores de 5 años y su tutor,
3. registrar una evaluación antropométrica (peso, talla, MUAC, edema),
4. calcular automáticamente el Z-score Peso/Talla con una tabla de referencia
   local,
5. clasificar el estado nutricional en un semáforo (verde / amarillo / rojo),
6. guardar todo en el teléfono sin internet, y
7. consultar el historial de evaluaciones con su color.

El objetivo de este avance **no** es validar clínicamente el instrumento, sino
demostrar el flujo completo de tamizaje en condiciones de conectividad nula.

---

## 2. Alcance

### Incluido

- Login local con usuario demo (`promotor` / `demo123`).
- Menú principal con tres funciones y dos chips deshabilitados
  ("GPS/Reportes: próximo sprint", "SMS: próximo sprint").
- Registro de infante: nombres, apellidos, documento, fecha de nacimiento,
  sexo, tutor, comunidad/ranchería.
- Cálculo automático de edad en meses.
- Formulario de evaluación: peso, talla, MUAC, edema bilateral, fecha/hora
  automática.
- Motor de cálculo separado (`NutricionService`) con interpolación lineal de
  mediana y DE sobre una tabla de referencia.
- Semáforo de resultado con Z-score, recomendación textual y trazabilidad del
  cálculo.
- Persistencia local en SQLite y datos semilla.
- Historial ordenado por fecha descendente y pantalla de detalle.
- Pantalla "Acerca de" con disclaimer académico.
- Pruebas automatizadas y checklist manual.

### Excluido (próximo sprint)

GPS y mapas, reportes PDF/CSV, alertas por SMS, sincronización con backend,
notificaciones push, iOS, login con servidor y diagnóstico médico.

---

## 3. Tecnologías

| Componente | Tecnología | Justificación |
|---|---|---|
| Framework móvil | Flutter 3.x / Dart | Un solo código, UI Material 3, buen soporte offline |
| Base de datos | SQLite con `sqflite` | Embebida, sin servidor, transaccional, probada en Android |
| Rutas de archivos | `path` | Resolución portable de la ruta de la base |
| Formato de fechas | `intl` | Fechas legibles en español (`dd/MM/yyyy`) |
| Pruebas | `flutter_test` + `sqflite_common_ffi` | Tests del motor y de la persistencia real |

No se usó Firebase, ni backend, ni ningún servicio externo. La app no abre
conexiones de red.

---

## 4. Arquitectura

Separación en cuatro capas, con el motor de cálculo aislado para poder
probarlo sin interfaz ni base de datos:

```
screens/        UI (login, home, infante, evaluación, resultado, historial…)
   │
widgets/ theme/ componentes y tema Material 3
   │
services/       nutricion_service (MOTOR), validadores, edad, fechas,
   │            referencias_csv, referencias_loader
   │
data/           repositorio (consultas), db_nutrilaguajira (esquema/semilla),
                models (Nino, Usuario, Evaluacion, ReferenciaWho)
```

Decisiones relevantes:

- **`NutricionService` es puro**: no importa Flutter ni SQLite. Recibe la tabla
  de referencia por inyección, lo que permite testearlo y reemplazar la tabla
  DEMO por la OMS completa sin tocar la lógica.
- **La tabla de referencia vive en SQLite** (`who_referencia_demo`), no en el
  código: es dato, no lógica.
- **La semilla se calcula con el motor real**, por lo que los datos de ejemplo
  no pueden quedar inconsistentes con el cálculo.

---

## 5. Base de datos

```sql
usuarios(id, usuario UNIQUE, clave, nombre)
ninos(id, nombres, apellidos, documento UNIQUE, fecha_nacimiento,
      sexo, tutor, comunidad, created_at)
evaluaciones(id, nino_id → ninos(id) ON DELETE CASCADE, fecha, edad_meses,
             peso_kg, talla_cm, muac_cm, edema, z_peso_talla, clasificacion,
             color, observacion, sincronizado)
who_referencia_demo(id, sexo, talla_cm, mediana, de, UNIQUE(sexo, talla_cm))
```

- Fechas en ISO-8601 (texto) para ordenar en SQL con `ORDER BY fecha DESC`.
- `PRAGMA foreign_keys = ON` para que el borrado de un infante elimine sus
  evaluaciones.
- `color` persiste la clave (`verde`/`amarillo`/`rojo`) para pintar el semáforo
  sin recalcular.
- `sincronizado` permanece en `0`: no existe sincronización en este avance.

### Datos semilla

3 infantes (José Ángel, Yuliana Andrea, Andrés David) y 4 evaluaciones
calculadas por el motor:

| Caso | Peso | Talla | MUAC | Edema | Z | Resultado |
|---|---|---|---|---|---|---|
| Verde | 9.50 kg | 75.0 cm | 13.5 cm | No | +0.32 | VERDE |
| Amarillo | 8.70 kg | 80.0 cm | 12.2 cm | No | −1.20 | AMARILLO |
| Rojo por Z | 8.80 kg | 85.0 cm | 12.0 cm | No | −2.27 | ROJO |
| Rojo por edema | 12.00 kg | 86.0 cm | 12.4 cm | **Sí** | +0.43 | ROJO |

---

## 6. Cálculo y clasificación

```
factor  = (talla - talla_inferior) / (talla_superior - talla_inferior)
mediana = mediana_inferior  + (mediana_superior - mediana_inferior) * factor
de      = de_inferior       + (de_superior - de_inferior) * factor
Z       = (peso_kg - mediana) / de
```

Clasificación: edema → ROJO; Z < −3 → ROJO severo; −3 ≤ Z < −2 → ROJO
moderado; −2 ≤ Z < −1 → AMARILLO; Z ≥ −1 → VERDE. El MUAC (solo desde los 6
meses) agrava el resultado; si hay discrepancia se conserva el criterio más
grave. El Z se clasifica redondeado a 2 decimales, la misma precisión que se
muestra en pantalla.

**La tabla incluida es DEMO** (28 filas, 45–110 cm) y está marcada como tal en
el CSV, en la app y en este informe. No constituye validación clínica.

---

## 7. Pruebas realizadas

### 7.1 Automatizadas

```
flutter analyze  →  No issues found!
flutter test     →  45 tests, All tests passed!
```

| Archivo | Pruebas | Qué cubre |
|---|---|---|
| `nutricion_service_test.dart` | 20 | los 4 casos obligatorios (verde, amarillo, rojo por Z, rojo por edema), desnutrición severa, bordes exactos Z = −1 y Z = −2, interpolación lineal, valor exacto de tabla, MUAC ignorado en < 6 meses, MUAC que agrava, rechazo de entradas fuera de rango y de sexo sin filas |
| `validadores_test.dart` | 20 | peso negativo / cero / fuera de rango, talla imposible, MUAC, edad > 59 meses, fecha futura, coma decimal |
| `evaluacion_form_widget_test.dart` | 4 | widget test: campos vacíos, peso −5 + talla 200 + MUAC 2, bloqueo a los 60 meses, entrada válida |
| `db_persistencia_test.dart` | 7 | SQLite real: semilla, tabla de referencia, login, orden del historial, **persistencia tras cerrar y reabrir**, recuperación por id, JOIN de detalle |

### 7.2 Manuales (emulador Android)

| # | Prueba | Resultado |
|---|---|---|
| 1 | La app abre sin internet | ✅ |
| 2 | Login demo funciona / clave incorrecta falla | ✅ |
| 3 | Registrar infante y evaluación | ✅ |
| 4 | Semáforo verde / amarillo / rojo en los tres casos semilla | ✅ |
| 5 | El edema fuerza ROJO con Z normal | ✅ |
| 6 | Cerrar la app y reabrir conserva los datos | ✅ |
| 7 | Historial con colores, orden descendente | ✅ |
| 8 | Validaciones bloquean peso negativo y talla de 200 cm | ✅ |

### 7.3 Defectos encontrados durante las pruebas y corregidos

Además del bug de coma flotante descrito en 7.1, la verificación manual en
emulador expuso y permitió corregir:

| # | Defecto | Causa | Corrección |
|---|---|---|---|
| 1 | Nombre del infante casi invisible en la lista de selección | `ListTileThemeData.titleTextStyle` sin color propio | se declaró `color: esquema.onSurface` |
| 2 | "Comunidad —" en la pantalla de resultado | la evaluación nueva no llevaba nombre/comunidad (venían del JOIN) | se copian del infante al construir el registro |
| 3 | Z = −2 exacto clasificaba ROJO mostrando "−2.00" | error de coma flotante en la división | clasificar con el Z redondeado a 2 decimales; coincidencia exacta de talla sin pasar por factor 1.0 |
| 4 | "La talla es obligatorio" | falta de concordancia de género | mensaje parametrizado por género |
| 5 | Selector de fecha en inglés | la app no declaraba localización | `flutter_localizations` con `locale: es` |
| 6 | Tildes faltantes en textos visibles y en la semilla | strings escritos sin tilde | corrección de toda la interfaz |

El punto 3 es el más relevante desde el método: la prueba automatizada del
borde detectó un comportamiento que a ojo era invisible (la pantalla mostraba
`−2.00` con semáforo rojo), y la corrección evita que la categoría dependa del
error de representación binaria.

---

## 8. Evidencias

- `screenshots/` — capturas de login, menú, registro de infante, formulario de
  evaluación, resultado verde / amarillo / rojo, historial y "Acerca de".
- `app-debug.apk` — APK de depuración instalable.
- `nutrilaguajira/test/` — código de las 45 pruebas automatizadas.
- `nutrilaguajira/tool/calcular_demo.dart` — reproducible con
  `dart run tool/calcular_demo.dart`, imprime los valores exactos de los casos
  semilla.

---

## 9. Limitaciones

- Tabla de referencia **DEMO**: no apta para uso clínico.
- Solo Peso/Talla; no se calculan Talla/Edad ni Peso/Edad.
- Login sin seguridad real (clave en texto plano, sesión en memoria).
- Sin GPS, reportes, SMS, sincronización ni notificaciones.
- Sin edición ni borrado de evaluaciones desde la interfaz.
- Solo Android.

---

## 10. Trabajo futuro

1. Reemplazar la tabla DEMO por las tablas OMS completas y validar contra la
   Resolución 2465 de 2016 / Resolución 115 de 2026.
2. Añadir Peso/Edad y Talla/Edad.
3. Captura de coordenadas GPS y reportes georreferenciados (PDF/CSV).
4. Alertas por SMS a los centros de salud.
5. Sincronización offline-first con resolución de conflictos.
6. Cifrado local y control de acceso (datos de menores).
