# Evidencias de ejecución — Sprint 3 (Reportes, Alertas y Zonas en riesgo)

Documento de apoyo para la sección **6.2 Evidencias de ejecución** del plan de
trabajo. Las capturas están en
[`screenshots/sprint3_reportes/`](screenshots/sprint3_reportes/README.md).

Todas las capturas se tomaron con el **APK instalado y ejecutándose** en un
emulador Android (1080 × 2400, Android 16 / API 36), en **modo avión** donde
aplica. La posición GPS de los datos de ejemplo se simuló con
`adb emu geo fix` (11.24712, -72.98765); en un equipo real la toma el GPS.

| Objetivo | % Cumplimiento | Evidencia | Observación |
|---|---|---|---|
| **Objetivo General del plan de trabajo** (implementar y desplegar NutriLaGuajira en rancherías durante 2026-2). | ~35 % | Sprint 3 entrega el módulo de **reportes (CSV/PDF) + alertas SMS + zonas en riesgo**, listo para validación en campo. Capturas [`11`](screenshots/sprint3_reportes/11_reporte_filtros.png)–[`15`](screenshots/sprint3_reportes/15_zonas_riesgo.png); 85 pruebas automatizadas. | La validación en rancherías reales con promotores comunitarios se ejecuta en **2026-2** (fase de implementación del plan), no en este sprint. |
| **Objetivo Específico 1** (validar la app con promotores). | ~20 % | Sanity checks en emulador (capturas reales), 85 tests verdes, `flutter analyze` sin issues. | La validación con usuarios reales y en condiciones de campo (luminosidad, conectividad) queda para 2026-2. |
| **Objetivo Específico 2** (capacitar a gestores comunitarios y estudiantes). | 0 % | — | Se ejecuta en **2026-2** con talleres presenciales y guía rápida en español/wayuunaiki. |
| **Objetivo Específico 3** (articular los reportes con brigadas y autoridades de salud). | ~40 % | Reportes CSV/PDF y alertas SMS funcionales (capturas [`11`](screenshots/sprint3_reportes/11_reporte_filtros.png)–[`14`](screenshots/sprint3_reportes/14_alertas_pendientes.png)); vista consolidada por ranchería ([`15`](screenshots/sprint3_reportes/15_zonas_riesgo.png)). | La articulación formal con PMA, Fundación Baylor y la Secretaría de Salud se concreta en 2026-2. |

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
| *(cierre)* | Zonas en riesgo, limpieza del menú y documentación. |

## Deudas técnicas conocidas

Ver el detalle en
[`screenshots/sprint3_reportes/README.md`](screenshots/sprint3_reportes/README.md#deudas-técnicas-conocidas):
T/E y P/E (Sprint 4), sincronización API (Sprint 4), SMS sin destinatario por
diseño, `historial_screen` con `setState` que devuelve un `Future` (deuda de
mantenimiento) y guion largo del PDF sustituido por `-`.
