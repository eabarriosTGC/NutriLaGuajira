# Instrumentos de campo (F1–F6)

Formularios imprimibles y plantillas CSV para el piloto de 2027-1. Todos están
en **borrador**: se prueban en la capacitación y se ajustan antes de la primera
jornada.

| Instrumento | Uso | Formato |
|---|---|---|
| F1 — Ficha de ranchería | Contexto del sitio (se llena una vez) | Markdown |
| F2 — Observación de tareas | Tiempos, errores y ayuda por tamizaje | Markdown + [`observacion_tareas.csv`](observacion_tareas.csv) |
| F3 — Usabilidad (SUS adaptado) | Puntaje 0–100 por promotor | Markdown + [`satisfaccion_sus.csv`](satisfaccion_sus.csv) |
| F4 — Entrevista breve | Comprensión del semáforo y aceptabilidad | Markdown |
| F5 — Bitácora de incidentes | Todo lo que salga mal o sorprenda | Markdown + [`incidentes.csv`](incidentes.csv) |
| F6 — Verificación del cálculo | Consistencia del Z contra planilla | Markdown |

Datos de tamizajes anonimizados: [`registro_tamizajes.csv`](registro_tamizajes.csv).

> **Regla de oro:** los CSV de campo **no llevan nombres**. Se usa un código
> (`R1-001`) y la tabla de correspondencia se guarda aparte, solo con la
> coordinación.

---

## F1 — Ficha de ranchería

| Campo | Valor |
|---|---|
| Código | R__ |
| Nombre de la ranchería | |
| Municipio (Manaure / Uribia) | |
| Autoridad tradicional (nombre y cargo) | |
| Fecha de autorización comunitaria | |
| Coordenadas (si se conocen) | |
| N.º estimado de niños de 6–59 meses | |
| ¿Hay señal celular? (ninguna / intermitente / buena) | |
| Fuente de agua y alimentos disponibles | |
| Distancia y tiempo desde el casco urbano | |
| Medio de transporte | |
| Canal de referencia para casos ROJO (nombre, teléfono) | |
| Promotor asignado | |
| Observaciones | |

---

## F2 — Observación de tareas

Una fila por **tamizaje observado**. Registrar en el momento, no al final.

| Campo | Cómo se llena |
|---|---|
| Código del niño | `R1-001` |
| Promotor | Código del promotor (`P1`…) |
| Caso planificado | verde / amarillo / rojo-Z / rojo-edema / real |
| ¿Completó sin ayuda? | S / N (ayuda = cualquier intervención del observador) |
| Tiempo total | Minutos y segundos, desde "Nuevo tamizaje" hasta ver el resultado |
| Errores recuperables | Unidades, campos vacíos, navegación (conteo) |
| Errores críticos | Edema no marcado, ROJO no enviado, dato inventado (conteo) |
| Momento del error | Login / registro / medición / cálculo / resultado / alerta |
| Notas | Texto corto y concreto |

**Definiciones para no discutir en campo:**

- **Ayuda:** el observador señala dónde tocar, dice un valor o corrige un dato.
- **Error recuperable:** el promotor lo detecta y lo corrige solo.
- **Error crítico:** cambia el resultado o impide referir un ROJO.

---

## F3 — Usabilidad (SUS adaptado, 10 ítems)

Instrucción: "Marque qué tanto está de acuerdo, de 1 (nada) a 5 (totalmente)."

| # | Ítem | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| 1 | Me gustaría usar esta app con frecuencia en mi trabajo. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | La app es innecesariamente complicada. *(inverso)* | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | Me pareció fácil de usar. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | Necesitaría apoyo de una persona técnica para usarla. *(inverso)* | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | Las funciones están bien integradas. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 6 | Hay demasiada inconsistencia en la app. *(inverso)* | ☐ | ☐ | ☐ | ☐ | ☐ |
| 7 | Creo que la mayoría aprendería a usarla rápido. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 8 | La app es muy incómoda de usar. *(inverso)* | ☐ | ☐ | ☐ | ☐ | ☐ |
| 9 | Me sentí seguro usando la app. | ☐ | ☐ | ☐ | ☐ | ☐ |
| 10 | Necesité aprender muchas cosas antes de usarla. *(inverso)* | ☐ | ☐ | ☐ | ☐ | ☐ |

**Cálculo:** ítems impares → (puntaje − 1); pares → (5 − puntaje). Suma × 2.5.
Rango 0–100. **Umbral del piloto: media ≥ 70** y ningún promotor < 50.

---

## F4 — Entrevista breve (semana 4, 10 min)

1. Con tus palabras, ¿qué significa **verde**, **amarillo** y **rojo**?
2. ¿Qué haces cuando sale **rojo**? ¿A quién avisas?
3. ¿Qué parte de la app te resultó más difícil? ¿Por qué?
4. ¿Qué cambiarías para usarla en la ranchería?
5. ¿Le explicarías el resultado a una familia? ¿Cómo?
6. ¿Qué harías si no hay batería o el teléfono se apaga?
7. ¿Confiarías en el resultado? ¿Por qué sí o por qué no?
8. ¿Hay algo que la app dé por hecho y en la ranchería no sea así?

El observador **no sugiere respuestas**. Se anota textual lo que dice la persona
y se marca si menciona espontáneamente: tablas DEMO, que no diagnostica, el
nombre en el SMS, el riesgo de perder el teléfono.

---

## F5 — Bitácora de incidentes

| Campo | Contenido |
|---|---|
| ID | `INC-001` |
| Fecha y hora | |
| Ranchería | R__ |
| Tipo | técnico / datos / ético / logístico / clínico |
| Descripción | Qué pasó, sin nombres |
| Impacto | En el niño / en el dato / en el piloto |
| Acción inmediata | Qué se hizo |
| ¿Se resolvió? | S / N / pendiente |
| Responsable | |

**Incidentes críticos (parada inmediata):** pérdida de datos, ROJO no referido,
envío de datos a un destinatario equivocado, acceso de terceros al teléfono.

---

## F6 — Verificación del cálculo

Se repite en el **20 %** de los tamizajes (elegidos al azar). El observador
recalcula a mano con la misma tabla y compara.

| Campo | Valor |
|---|---|
| Código del niño | `R1-00_` |
| Peso / talla / MUAC / edema | |
| Z P/T mostrado por la app | |
| Mediana y DE leídas en la tabla (talla inferior/superior) | |
| Z P/T recalculado a mano | |
| Diferencia | |
| ¿Dentro de ±0.01? | S / N |
| Z T/E y Z P/E mostrados | |
| ¿Coinciden con los criterios de la pantalla? | S / N |

**Fórmula de verificación:**

```
factor  = (talla − talla_inf) / (talla_sup − talla_inf)
mediana = mediana_inf + (mediana_sup − mediana_inf) × factor
DE      = DE_inf + (DE_sup − DE_inf) × factor
Z       = (peso − mediana) / DE
```

Si hay discrepancia > 0.01, se fotografía la pantalla (sin nombres) y se reporta
como incidente **técnico**.

---

## Plantillas CSV

| Archivo | Filas | Columnas |
|---|---|---|
| [`registro_tamizajes.csv`](registro_tamizajes.csv) | Un tamizaje | código, ranchería, edad, medidas, Z, clasificación |
| [`observacion_tareas.csv`](observacion_tareas.csv) | Un tamizaje observado | tiempos, ayuda, errores |
| [`satisfaccion_sus.csv`](satisfaccion_sus.csv) | Un promotor | 10 ítems y puntaje |
| [`incidentes.csv`](incidentes.csv) | Un incidente | tipo, impacto, acción |

Los CSV se abren en Excel/LibreOffice. Codificación **UTF-8**. Para el análisis
se concatenan y se elimina cualquier columna que identifique a una persona.
