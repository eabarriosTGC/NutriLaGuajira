# Evidencias de ejecución — Sprint 3: Reportes (CSV/PDF), Alertas SMS y Zonas en riesgo

Capturas tomadas con la app **instalada y ejecutándose** en un emulador Android
(perfil Pixel, **1080 × 2400 px**, **Android 16 / API 36**), en **modo avión**.
Los reportes y la cola de alertas son **100 % locales**.

> **Nota de alcance.** Las capturas `11`–`15` son del **Sprint 3**. Talla/Edad y
> Peso/Edad se incorporaron después (Sprint 4 técnico, tabla **DEMO**); sus
> capturas se agregarán en el cierre del Sprint 4.

> **Nota metodológica.**
> - Los archivos se generan en el sandbox de la app (`<documentos>/exports/`) y
>   solo salen si el usuario pulsa "Compartir". La ruta se muestra **relativa**
>   (`exports/…`) para no exponer la ruta absoluta.
> - La posición GPS de los datos de ejemplo se simuló con
>   `adb emu geo fix -72.98765 11.24712`; en un equipo real la toma el GPS.
> - Para el estado `Fallida` de la captura 14 se usó `pm disable-user` sobre
>   Google Messages (ver más abajo): es un fallo **real**, no un mockup.

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`11_reporte_filtros.png`](11_reporte_filtros.png) | Pantalla **Reportes**: filtros de fecha, comunidad/ranchería y estado, con **Generar CSV** y **Generar PDF**. |
| [`12_reporte_csv_generado.png`](12_reporte_csv_generado.png) | Diálogo del CSV: ruta relativa (`exports/…`), **Compartir / Abrir / Cerrar**. |
| [`13_reporte_pdf_preview.png`](13_reporte_pdf_preview.png) | Vista previa del **PDF** (`printing`/`PdfPreview`): encabezado, resumen por semáforo, tabla de casos ROJO con coordenadas y pie con la nota de T/E y P/E. |
| [`14_alertas_pendientes.png`](14_alertas_pendientes.png) | Pantalla **Alertas SMS** con los **3 estados**: `Enviada` (verde), `Fallida` (rojo, con Reintentar) y `Pendiente` (gris, con Enviar). |
| [`14b_alertas_error_intent.png`](14b_alertas_error_intent.png) | Soporte: SnackBar real con `ACTIVITY_NOT_FOUND` para el intent `sms:?body=…` cuando no hay app de SMS. |
| [`15_zonas_riesgo.png`](15_zonas_riesgo.png) | **Zonas en riesgo**: 3 rancherías ordenadas por criticidad — Bahía Honda (6 rojos), Siapana (1 amarillo) y El Cardón (1 verde) — con chips por color y último caso. |

## Mapeo a requerimientos (honesto)

| Requerimiento | % | Evidencia | Observación |
|---|---|---|---|
| **RF-09** — reporte consolidado filtrable (CSV/PDF) | ~80 % | `11`, `12`, `13`, `15` | CSV y PDF completos con filtros y consolidado por ranchería. Talla/Edad y Peso/Edad ya se calculan (tabla DEMO, informativos); falta la tabla OMS oficial (Gate 1). |
| **RF-10** — alerta SMS / sincronización diferida | ~60 % | `14`, `14b` | Cola local + intent de SMS (`sms:?body=`, sin destinatario ni `SEND_SMS`). El enrutamiento automático y la sincronización por API quedan para Sprint 4. |
| **RNF-01** — offline | 100 % | `11`–`15` | Reportes y cola funcionan en modo avión. |
| **RNF-02** — rendimiento | 100 % | tests | 500 registros generan PDF en < 5 s (umbral holgado). |
| **RNF-05** — validación de rangos | 100 % | tests | `ReporteFiltros.validar()` rechaza `fecha_fin < fecha_inicio`. |
| **RNF-06** — seguridad local | 100 % | `12`, `13` | Archivos en el sandbox; la UI muestra ruta relativa. |

## Cómo se generaron los datos de las capturas (real, no mockup)

- **13 (PDF)**: se registró una evaluación ROJA con GPS desde la UI; el PDF
  resume 5 evaluaciones (1 verde, 1 amarillo, 3 rojos) y la tabla de rojos
  muestra `11.24712, -72.98765`.
- **14 (alertas)**: se registraron 3 evaluaciones ROJA → 3 alertas `Pendiente`.
  1) se envió la primera y Google Messages se abrió → `Enviada`;
  2) se deshabilitó Google Messages (`pm disable-user`), se intentó la segunda
  → `ACTIVITY_NOT_FOUND` → `Fallida` (ver `14b`), y se volvió a habilitar;
  3) la tercera quedó `Pendiente`.
- **15 (zonas)**: con las evaluaciones semilla (José verde en El Cardón,
  Yuliana amarilla en Siapana, Andrés rojo en Bahía Honda) más las ROJA
  registradas desde la UI, el consolidado queda ordenado por criticidad:
  Bahía Honda (6 rojos), Siapana (1 amarillo), El Cardón (1 verde). El orden lo
  calcula la app (`rojos DESC, amarillos DESC, total DESC`).

## Deudas técnicas conocidas

1. **Talla/Edad y Peso/Edad**: **implementados** con una tabla **DEMO (LMS)**
   (`assets/who_edad_demo.csv`) a partir del Sprint 4 técnico. Falta reemplazar
   esa tabla por la OMS oficial (**Gate 1** del roadmap). Las capturas `11`–`15`
   son del Sprint 3, anteriores a esta funcionalidad.
2. **Sincronización API real**: no implementada. `SincronizacionStrategy` es la
   interfaz preparada; hoy la única implementación es `SmsIntentStrategy`.
   → **Sprint 4**.
3. **SMS sin destinatario**: por diseño, hasta que exista una API o una
   configuración de centros de salud. El brigadista elige el destinatario en su
   app de mensajes. No se usa `SEND_SMS` ni `SharedPreferences`.
4. **`historial_screen` con `setState` que devuelve un `Future`**: detectado en
   el Bloque D (mismo patrón que corregimos en Alertas). No se corrigió por la
   regla de no refactorizar Sprint 1/2; queda como deuda de mantenimiento.
5. **Guion largo `—` del PDF**: Helvetica cubre Latin-1 (tildes/ñ) pero no
   U+2014; el pie usa `-`. Embeber una TTF con soporte Unicode es opcional para
   Sprint 4. Las coordenadas ausentes se muestran como `N/D`.

## Cómo reproducir

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter run -d emulator-5554   # o instalar el APK de debug

# Reportes: login demo -> "Reportes"
#   ajustar filtros -> "Generar CSV" / "Generar PDF" -> "Vista previa"
# Alertas:  login demo -> "Alertas SMS" -> "Enviar" / "Reintentar"
# Zonas:    login demo -> "Zonas en riesgo" -> tocar una ranchería
```

Las capturas se tomaron con `adb exec-out screencap -p` con la app en ejecución.
