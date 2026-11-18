# Evidencias de ejecución — Sprint 3 (Reportes, Alertas y Zonas en riesgo)

Documento de apoyo para los apartados **6.1 Resumen general del avance** y
**6.2 Evidencias de ejecución** del plan de trabajo. Las capturas están en
[`screenshots/sprint3_reportes/`](screenshots/sprint3_reportes/README.md).

Todas las capturas se tomaron con el **APK instalado y ejecutándose** en un
emulador Android (1080 × 2400, Android 16 / API 36), en **modo avión** donde
aplica. La posición GPS de los datos de ejemplo se simuló con
`adb emu geo fix` (11.24712, -72.98765); en un equipo real la toma el GPS.

---

## 6.1 Resumen general del avance

Al cierre del Sprint 3, el **producto técnico de NutriLaGuajira está listo para
la fase de implementación en campo** prevista para 2026-2. De las 8 actividades
del cronograma del plan de trabajo (apartado 5), **ninguna se ha ejecutado
todavía**: todas están programadas para el semestre 2026-2, tal como establece
el propio plan. Lo que sí está completo es la **preparación técnica** que
habilita esas actividades:

- **Sprint 1 (completo):** login, registro de infantes/tutores, formulario
  antropométrico, persistencia local SQLite/Room, historial.
- **Sprint 2 (completo):** cálculo Z-score Peso/Talla, semáforo visual, captura
  GPS con alta precisión y fallback offline, detalle georreferenciado.
- **Sprint 3 (completo):** reportes CSV/PDF con filtros, alertas SMS con cola
  local y reintento, zonas en riesgo consolidadas por ranchería.

El **35 % reportado para el Objetivo General** corresponde a la preparación
técnica verificable (producto funcional + tests + evidencias), **no** a la
ejecución en campo. El 65 % restante son las actividades 1–8 del cronograma:
validación en rancherías, capacitación de gestores y articulación
interinstitucional, todas en 2026-2.

**Calidad actual:** 85/85 tests verdes, `flutter analyze` 0 issues,
`dart format` sin cambios pendientes.

---

## 6.2 Evidencias de ejecución

| Objetivo | % Cumplimiento | Evidencia | Observación |
|---|---|---|---|
| **Objetivo General del plan de trabajo** (implementar y desplegar NutriLaGuajira en rancherías durante 2026-2). | ~35 % *(preparación técnica)* | Sprint 3 entrega el módulo de **reportes (CSV/PDF) + alertas SMS + zonas en riesgo**, listo para validación en campo. Capturas [`11`](screenshots/sprint3_reportes/11_reporte_filtros.png)–[`15`](screenshots/sprint3_reportes/15_zonas_riesgo.png); 85 pruebas automatizadas. | El 35 % es **preparación técnica verificable**. El 65 % restante son las actividades del cronograma (validación en rancherías, capacitación, articulación) que se ejecutan en **2026-2**. |
| **Objetivo Específico 1** (validar la app con promotores en 3 rancherías piloto). | ~20 % | Sanity checks en emulador (capturas reales), 85 tests verdes, `flutter analyze` sin issues. | La validación con usuarios reales y en condiciones de campo (luminosidad, conectividad) queda para 2026-2 (actividades 4 y 6 del cronograma). |
| **Objetivo Específico 2** (capacitar a gestores comunitarios y estudiantes). | 0 % | — | Se ejecuta en **2026-2** con talleres presenciales (actividades 3 y 5) y guía rápida en español/wayuunaiki. |
| **Objetivo Específico 3** (articular los reportes con brigadas y autoridades de salud). | ~40 % | Reportes CSV/PDF y alertas SMS funcionales (capturas [`11`](screenshots/sprint3_reportes/11_reporte_filtros.png)–[`14`](screenshots/sprint3_reportes/14_alertas_pendientes.png)); vista consolidada por ranchería ([`15`](screenshots/sprint3_reportes/15_zonas_riesgo.png)). | La articulación formal con PMA, Fundación Baylor y la Secretaría de Salud se concreta en 2026-2 (actividades 1 y 8 del cronograma). |

## Estado del producto al cierre del Sprint 3

**Módulos funcionales**

- Login local y registro de infantes/tutores.
- Evaluación antropométrica con Z-score **Peso/Talla** y semáforo.
- Captura **opcional de GPS** (lat/lng) y su visualización en resultado/detalle.
- Historial de tamizajes.
- **Reportes CSV** (filtros por fecha/comunidad/estado, BOM UTF-8, RFC 4180).
- **Reportes PDF** (encabezado, resumen por semáforo, casos críticos con
  coordenadas, pie con nota T/E y P/E).
- **Alertas SMS** (cola local, intent `sms:?body=`, reintento; sin `SEND_SMS`).
- **Zonas en riesgo** (consolidado por ranchería ordenado por criticidad, con
  detalle de casos ROJO y copia de coordenadas).

**Módulos pendientes (Sprint 4 / 2026-2)**

- Talla/Edad y Peso/Edad (requieren tablas OMS por edad + motor + migración).
- Sincronización por API (`SincronizacionStrategy` ya es la interfaz; solo existe
  `SmsIntentStrategy`).
- Validación en campo y capacitación (2026-2).
- Fuente TTF opcional para el PDF (hoy Helvetica cubre Latin-1; el guion largo
  U+2014 no y se sustituye por `-`).

**Calidad**

- `flutter test`: **85/85** (100 % verdes).
- `flutter analyze`: **0 issues**.
- `dart format --set-exit-if-changed`: **sin cambios pendientes**.

**Commits del Sprint 3**

| Commit | Contenido |
|---|---|
| `7bebbd3` | CSV con filtros, BOM UTF-8 y escape RFC 4180. |
| `012811c` | Pantalla de reportes + CSV + compartir/abrir. |
| `09553c5` | Exportación PDF (encabezado, resumen y casos críticos). |
| `3476dfb` | Tabla v3, `AlertaService`, `SincronizacionStrategy` y SMS intent. |
| `5e919b1` | Pantalla de alertas pendientes con reintento. |
| `f735570` | Zonas en riesgo: consolidado por ranchería y detalle de casos ROJO. |
| `79afa4d` | Menú definitivo: accesos a Reportes, Alertas y Zonas en riesgo. |
| `17f6c11` | Documentación de cierre: README del set, este archivo y `ESTADO.md`. |

## Deudas técnicas conocidas

Ver el detalle en
[`screenshots/sprint3_reportes/README.md`](screenshots/sprint3_reportes/README.md#deudas-técnicas-conocidas):
T/E y P/E (Sprint 4), sincronización API (Sprint 4), SMS sin destinatario por
diseño, `historial_screen` con `setState` que devuelve un `Future` (deuda de
mantenimiento) y guion largo del PDF sustituido por `-`.
