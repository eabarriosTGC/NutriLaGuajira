# Protocolo de validación — piloto en 3 rancherías (2027-1)

**Versión:** 0.1 (borrador) · **Fecha:** 2026-11-21
**Ejecuta:** Universidad de La Guajira (Uniguajira) + equipo NutriLaGuajira
**App evaluada:** `v0.4.0-sprint4` (`applicationId co.edu.uniguajira.nutrilaguajira`)
**Estado:** pendiente de aprobación por Uniguajira, la Secretaría de Salud y el
comité de ética correspondiente.

> **Alcance honesto.** Este es un **piloto de factibilidad y usabilidad**, no un
> estudio de validez diagnóstica. Las tablas de referencia son **DEMO**: el
> piloto comprueba que la app *funciona y se puede usar en ranchería*, no que
> clasifique igual que la norma OMS. La sustitución por las tablas oficiales es
> el **Gate 1** del roadmap y debe ocurrir **antes** de cualquier uso clínico.

---

## 1. Objetivo y preguntas

**Objetivo general.** Determinar si NutriLaGuajira es **factible, usable y
segura** para el tamizaje nutricional de niños de 6 a 59 meses en rancherías sin
conectividad, en condiciones reales de operación por promotores comunitarios.

| # | Pregunta | Cómo se responde |
|---|---|---|
| P1 | ¿El promotor completa el flujo (login → infante → tamizaje → resultado) sin ayuda? | Observación de tareas + tiempos |
| P2 | ¿El semáforo y la recomendación se entienden y se explican a la familia? | Comprensión + retroalimentación |
| P3 | ¿Los datos sobreviven al cierre de la app, al reinicio y al cambio de día? | Verificación de persistencia |
| P4 | ¿El cálculo es **consistente** con la misma tabla aplicada a mano? | Planilla de verificación |
| P5 | ¿La app resiste el contexto (sol, lluvia, batería, calor, sin señal)? | Bitácora + incidencias |
| P6 | ¿Qué debe cambiar antes de escalar? | Análisis temático + priorización |

**Fuera de alcance:** sensibilidad/especificidad frente a diagnóstico clínico,
comparación con otros instrumentos (MUAC, OMS), evaluación de impacto en
desnutrición y telemedicina. La sincronización con Cloud Firestore **existe**
desde 2026-11-24, pero el piloto no la evalúa como objetivo: se opera y se
vigila como riesgo (R-07 a R-09).

---

## 2. Diseño

- **Tipo:** piloto exploratorio, mixto (cuantitativo descriptivo + cualitativo).
- **Unidad de análisis:** el **tamizaje** (para métricas de tarea y cálculo) y el
  **promotor** (para usabilidad y aceptabilidad).
- **Fases:**
  1. **Capacitación** (semana 0): taller de 4 h con evaluación práctica.
  2. **Operación acompañada** (semanas 1–4): el promotor usa la app en visitas
     reales; un observador lo acompaña en al menos 2 jornadas por ranchería.
  3. **Operación autónoma** (semanas 5–6): sin observador; se mide persistencia
     del uso y se registran incidencias por bitácora.
  4. **Cierre** (semanas 7–8): análisis, devolución a la comunidad, informe y
     decisión **go/no-go**.
- **Sin grupo control.** No se compara contra otra app ni contra no-usar la app:
  sería éticamente discutible y no responde a las preguntas del piloto.

---

## 3. Sitios y participantes

### 3.1 Selección de las 3 rancherías

Se definen con la Secretaría/Uniguajira aplicando **todos** estos criterios:

1. Comunidad **sin conectividad** estable (verificada en visita previa).
2. Al menos **8 niños de 6–59 meses** residentes.
3. **Autorización de la comunidad** (autoridad tradicional) y del cabildo/leader.
4. Distancia y acceso compatibles con la logística (Manaure o Uribia).
5. Presencia de un **promotor activo** o gestor comunitario dispuesto.
6. Cobertura por un canal de referencia para casos ROJO (PMA, Baylor o
   Secretaría).

Las rancherías se nombran **R1, R2 y R3** hasta que la Secretaría confirme los
nombres; no se inventan comunidades en este documento.

### 3.2 Participantes

| Grupo | n | Criterios |
|---|---|---|
| Promotores/gestores | 6–8 | Mayores de edad, alfabetizados, manejan smartphone Android, autorizan participación |
| Niños tamizados | 30–45 (10–15 por ranchería) | 6–59 meses, con tutor presente que consiente |
| Tutores | Uno por niño | Representante legal o cuidador principal |
| Observadores | 2–3 estudiantes | Capacitados en los instrumentos |

**Exclusión de niños:** enfermedad aguda grave en el momento (se refiere, no se
tamiza), malformación que impida medir talla, tutor que no consiente.
**Nunca** se excluye a un niño por su estado nutricional.

---

## 4. Variables e instrumentos

| Variable | Tipo | Instrumento | Momento |
|---|---|---|---|
| Tarea completada sin ayuda | Sí/No | F2 Observación de tareas | Cada jornada observada |
| Tiempo por tamizaje | Minutos (mediana) | F2 | Cada tamizaje observado |
| Errores recuperables / críticos | Conteo | F2 | Cada jornada |
| Usabilidad percibida | Puntaje 0–100 (SUS) | F3 SUS adaptado | Fin de capacitación y semana 4 |
| Comprensión del semáforo | Escala 1–4 | F4 Entrevista breve | Semana 4 |
| Consistencia del cálculo | Diferencia de Z | F6 Planilla de verificación | 20 % de los tamizajes |
| Persistencia | 0 pérdidas | Revisión del historial | Semana 6 |
| Sincronización (si se usa cuenta institucional) | Registros faltantes/duplicados | Firestore vs. SQLite | Semana 6 |
| Incidencias | Texto | F5 Bitácora | Permanente |
| Contexto del sitio | Texto | F1 Ficha de ranchería | Antes de la semana 1 |

Instrumentos completos en [`INSTRUMENTOS/`](INSTRUMENTOS/README.md).

---

## 5. Criterios de éxito (propuestos)

Se considera **piloto exitoso** si se cumplen **todos** los criterios de la
columna "Umbral". Son propuestas para discutir con Uniguajira; no están
validados.

| # | Indicador | Umbral | Fuente |
|---|---|---|---|
| C1 | Tareas completadas sin ayuda | **≥ 90 %** | F2 |
| C2 | Tiempo mediano por tamizaje | **≤ 5 min** en semana 1; **≤ 3 min** en semana 4 | F2 |
| C3 | SUS | **≥ 70** (media) y ningún promotor < 50 | F3 |
| C4 | Explican correctamente el color a la familia | **≥ 80 %** de observaciones | F4 |
| C5 | Consistencia del Z con la planilla | diferencia **≤ 0.01** en **≥ 98 %** | F6 |
| C6 | Persistencia de datos | **0 pérdidas** en el 100 % de verificaciones | historial |
| C7 | Incidentes críticos | **0** (pérdida de datos, caso ROJO no referido) | F5 |
| C8 | Uso autónomo a los 7 días | **≥ 80 %** de promotores siguen usándola | bitácora |
| C9 | Sincronización tras recuperar red (solo cuenta institucional) | **100 %** de los registros en Firestore en ≤ 24 h, **0 duplicados** | Firestore + SQLite |

**Criterio de fracaso (stop):** cualquier incidente crítico, o C6 < 100 %, o C1
< 70 %, o C9 con duplicados/pérdidas. Ante eso se detiene el piloto, se corrige y se repite la capacitación.

> **C5 no mide validez clínica.** Compara la app contra la *misma* tabla DEMO
> aplicada a mano. Sirve para detectar errores de implementación (interpolación,
> redondeo, bordes), no para afirmar que el resultado sea clínicamente correcto.

---

## 6. Procedimiento y cronograma

| Semana | Actividad | Producto |
|---|---|---|
| −4 | Aprobación del protocolo y del consentimiento; selección de R1–R3 | Actas y avales |
| −3 | Validación de la guía wayuunaiki con 2 hablantes; compra de materiales | Guía aprobada |
| −2 | Prueba del APK en los teléfonos reales; carga de 3 casos de prueba y borrado | Acta de instalación |
| −1 | Convocatoria comunitaria; consentimientos impresos | Lista de participantes |
| 0 | Taller de 4 h + evaluación práctica | Promotores certificados |
| 1–2 | Jornadas observadas (2 por ranchería) | F1, F2, F6 |
| 3–4 | Operación con acompañamiento remoto; SUS final | F3, F4 |
| 5–6 | Operación autónoma; verificación de persistencia | Historial + F5 |
| 7 | Análisis y devolución a las comunidades | Informe preliminar |
| 8 | Informe final y decisión go/no-go | Informe + plan de mejoras |

Cada jornada: llegada, presentación con la autoridad, consentimientos, tamizajes,
cierre con la familia, respaldo de datos (si el protocolo de custodia lo permite)
y salida. **Nunca** se deja un dispositivo con datos sin responsable.

---

## 7. Ética y protección de datos

### 7.1 Marco

- **Resolución 8430 de 1993** (investigación en salud): estudio de **riesgo
  mínimo**, con menores de edad y consentimiento del representante legal.
- **Ley 1581 de 2012** y **Decreto 1377 de 2013**: datos de niños son
  **datos sensibles** y su tratamiento requiere autorización expresa del
  representante legal.
- **Ley 1098 de 2016** (Código de la Infancia): interés superior del niño.
- Aprobación por el comité de ética que designe Uniguajira.

### 7.2 Reglas de operación

1. **Consentimiento informado escrito** del tutor, leído en voz alta y en
   wayuunaiki si hace falta; firma o huella + testigo.
2. **Autorización comunitaria** previa (acta con la autoridad tradicional).
3. **La app no reemplaza la atención**: todo ROJO se refiere el mismo día por el
   canal definido (ver §8).
4. **Minimización**: solo se registran los datos que la app pide. No se toman
   fotografías del niño ni de la familia sin autorización específica.
5. **Custodia del dispositivo**: PIN/biometría activos, sin cuentas personales
   ni apps de mensajería con historial del proyecto. **La sincronización con
   Firestore debe decidirse antes del piloto** (§7.3, R-07): o se usa la cuenta
   demo (todo local), o se usa una cuenta institucional con consentimiento
   explícito para la nube.
6. **Anonimización para análisis**: el CSV se exporta y se eliminan `nombres` y
   `apellidos`; `id_infante` se reemplaza por un código `R1-001`. La tabla de
   correspondencia la custodia solo la coordinación, en un archivo aparte.
7. **Retención**: datos crudos hasta el cierre del informe; luego se eliminan del
   dispositivo y se conserva solo el dataset anonimizado.
8. **Derechos**: el tutor puede pedir acceso, corrección o supresión en cualquier
   momento, sin afectar la atención.

### 7.3 Riesgos de privacidad conocidos (declararlos, no ocultarlos)

| # | Riesgo | Mitigación en el piloto |
|---|---|---|
| R-01 | SQLite **sin cifrar** en el teléfono | PIN, dispositivo bajo custodia, no se presta, borrado al cierre |
| R-02 | Login con clave en texto plano (sin seguridad real) | Se documenta; el control es físico, no lógico |
| R-03 | El **SMS de alerta incluye el nombre completo** del niño y la ranchería, y viaja sin cifrar | Antes del piloto: enviar solo iniciales o código (cambio pendiente en `construirMensaje`), o restringir el canal a un número institucional |
| R-04 | El intent `sms:?body=` **no fija destinatario**: el promotor elige | Capacitar: solo al número institucional definido; nunca a contactos personales |
| R-05 | Pérdida/robo del teléfono | Registro de dispositivos, PIN, borrado remoto si el fabricante lo permite, denuncia |
| R-06 | Exportación CSV con nombres a WhatsApp/correo | Solo al equipo; se anonimiza antes de compartir |
| R-07 | **Datos de menores en Google Cloud (Firestore)** desde la v0.5.0: nombres, documento, medidas y coordenadas | Consentimiento explícito para la nube; cuenta institucional (no personal); evaluar con jurídica el acuerdo de encargado del tratamiento con Google; región `us-east1` declarada; opción de operar con la cuenta demo (sin nube) |
| R-08 | **Alertas ROJAS legibles por cualquier usuario autenticado** (`alertas_criticas`) | Limitar el alta de cuentas a la coordinación; revisar reglas antes del piloto; no compartir credenciales |
| R-09 | **Reglas de Firestore** mal desplegadas o cuenta comprometida → fuga entre promotores | Probar reglas en el emulador, desplegar con `firebase deploy --only firestore:rules`, rotar contraseñas y revisar accesos |

> **R-03 y R-04 son decisiones de producto pendientes.** No se resuelven en este
> protocolo: se marcan como condición previa al piloto y se documentan en el
> informe de hallazgos.

---

## 8. Manejo de casos ROJO

1. El promotor explica el resultado a la familia con la guía.
2. Se activa el canal definido con la Secretaría (brigada, PMA o Baylor).
3. Se registra la referencia en la bitácora (F5): fecha, hora, canal, respuesta.
4. **Si el canal falla**, se escala por teléfono a la coordinación y se deja
   constancia. Un ROJO no referido es un **incidente crítico** (§5).
5. La app no emite diagnóstico: el mensaje dice "clasificación" y "acción".

---

## 9. Plan de análisis

- **Cuantitativo:** porcentajes de C1, C4, C6–C8; medianas y rangos de C2;
  media y desviación de C3; distribución de diferencias de Z (C5) con histograma
  y casos fuera de tolerancia.
- **Cualitativo:** codificación temática de F4 y F5 (barreras, estrategias de
  uso, comprensión del semáforo, contexto).
- **Triangulación:** cada hallazgo cuantitativo se contrasta con la bitácora.
- **Producto:** informe con (a) resultados por indicador, (b) lista priorizada de
  mejoras (impacto × esfuerzo), (c) decisión go/no-go y condiciones.

**Tamaño de muestra:** descriptivo, sin cálculo de potencia. 30–45 tamizajes
permiten detectar problemas de uso; no permiten inferencia poblacional y el
informe debe decirlo.

---

## 10. Riesgos operativos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Lluvia/camino intransitable | Alta | Medio | Fechas flexibles, 2 visitas por ranchería |
| Batería insuficiente | Alta | Alto | Power bank, carga previa, modo ahorro |
| Teléfono incompatible (Android < 7) | Media | Medio | Verificación previa; APK `armeabi-v7a` |
| Resistencia al registro digital | Media | Alto | Autoridad comunitaria, demostración, opción de registrar en papel y transcribir |
| Pérdida de datos | Baja | Crítico | Verificación diaria del historial; respaldo manual del CSV |
| Sesgo del observador | Media | Medio | Dos observadores en la primera jornada; guion fijo |

---

## 11. Productos del piloto

1. Informe de validación (8–12 páginas) con los 8 indicadores.
2. Dataset **anonimizado** de tamizajes (CSV) y matriz de observaciones.
3. Lista priorizada de mejoras para la app (incluye R-03/R-04).
4. Guía de usuario corregida y guía wayuunaiki validada.
5. Acta de decisión **go/no-go** para escalar a más rancherías.

---

## 12. Anexos

- [`INSTRUMENTOS/`](INSTRUMENTOS/README.md) — F1 a F6 y plantillas CSV.
- [`GUIA_USUARIO.md`](GUIA_USUARIO.md) — guía del promotor.
- [`CONSENTIMIENTO_INFORMADO.md`](CONSENTIMIENTO_INFORMADO.md) — texto legal.
- [`CAPACITACION.md`](CAPACITACION.md) — taller y certificación.
