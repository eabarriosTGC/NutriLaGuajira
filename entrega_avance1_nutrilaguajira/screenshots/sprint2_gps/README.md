# Evidencias de ejecución — Sprint 2: georreferenciación GPS

Capturas tomadas con la app **instalada y ejecutándose** en un emulador Android
(perfil Pixel, **1080 × 2400 px**, **Android 16 / API 36**), en **modo avión**
(sin conexión de red). Corresponden a la implementación del **módulo de captura
de coordenadas GPS de la ranchería** (Objetivo Específico 3).

> **Nota metodológica (honestidad de la evidencia).** En el emulador la posición
> se simuló con `adb emu geo fix -72.98765 11.24712` (latitud **11.24712**,
> longitud **-72.98765**, coordenadas del departamento de La Guajira). En un
> dispositivo real la app obtiene la posición del GPS del equipo. La captura es
> **opcional y explícita**: el promotor pulsa "Obtener ubicación"; si no hay
> señal o se niega el permiso, el tamizaje se guarda igualmente sin coordenadas.

Estado de la base al momento de las capturas: **3 infantes** (semilla) y
**5 tamizajes** (4 de la semilla + 1 registrado en vivo con GPS).

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`01_login.png`](01_login.png) | Login local con las credenciales demo (`promotor` / `demo123`) y el aviso "Funciona sin internet". |
| [`02_menu.png`](02_menu.png) | Menú principal: **3 infantes / 5 tamizajes**. El chip muestra "Reportes PDF/CSV: próximo sprint" (el GPS ya no aparece como pendiente). |
| [`03_seleccion_infante.png`](03_seleccion_infante.png) | Selección del infante a tamizar (lista semilla). |
| [`04_evaluacion_formulario.png`](04_evaluacion_formulario.png) | Formulario de evaluación antropométrica (peso, talla, MUAC, edema) con la nueva tarjeta **"Ubicación de la ranchería"**. |
| [`05_evaluacion_sin_gps.png`](05_evaluacion_sin_gps.png) | Medidas cargadas (9.5 kg · 75 cm · 13.5 cm) y la ubicación todavía **"Sin coordenadas"**, con el botón "Obtener ubicación". |
| [`06_evaluacion_gps_capturado.png`](06_evaluacion_gps_capturado.png) | Tras pulsar **"Obtener ubicación"**: **Latitud 11.24712 · Longitud -72.98765**. El botón cambia a "Actualizar ubicación". |
| [`07_resultado_gps.png`](07_resultado_gps.png) | Resultado **VERDE** (Z = +0.32) con la fila **Ubicación 11.24712, -72.98765** y "Guardado localmente". |
| [`08_historial.png`](08_historial.png) | Historial con los 5 tamizajes (VERDE / AMARILLO / ROJO), el nuevo incluido, ordenados por fecha. |
| [`09_detalle_gps.png`](09_detalle_gps.png) | Detalle del tamizaje con la fila **Ubicación** y la trazabilidad del cálculo (mediana, DE, Z, MUAC). |
| [`10_acerca_de.png`](10_acerca_de.png) | "Acerca de": incluye "Ubicación GPS opcional de la ranchería" y deja PDF/CSV y SMS como próximo sprint. |

## Correspondencia con la tabla 6.2 (Evidencias de ejecución)

| Objetivo | Evidencia en este folder | Observación |
|---|---|---|
| **Objetivo Específico 1** (UI + cálculo antropométrico) | `03`, `04`, `05`, `06`, `07`, `09` | Formulario, semaforización y trazabilidad del Z-score. |
| **Objetivo Específico 2** (persistencia local SQLite) | `02`, `08` | Los 5 tamizajes siguen en la base local; el contador del menú lo refleja. |
| **Objetivo Específico 3** (georreferenciación GPS) | `04`, `05`, `06`, `07`, `09` | Captura de coordenadas, su guardado en SQLite y su visualización en resultado y detalle. |

## Alcance real de esta entrega (para no sobreafirmar)

- **Implementado y evidenciado:** captura **opcional** de GPS, persistencia de
  `lat`/`lng` en `evaluaciones` (esquema v2 con migración), y despliegue de las
  coordenadas en el resultado y el detalle.
- **Pendiente (no evidenciado aquí):** exportación **PDF/CSV**, envío diferido de
  **SMS** y sincronización. La app los muestra como "próximo sprint".
- El cálculo del semáforo usa la **tabla DEMO** (no las tablas OMS completas).
