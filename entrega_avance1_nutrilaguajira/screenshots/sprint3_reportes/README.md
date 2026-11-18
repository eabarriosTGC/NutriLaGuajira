# Evidencias de ejecución — Sprint 3: Reportes (CSV/PDF) y Alertas SMS

Capturas tomadas con la app **instalada y ejecutándose** en un emulador Android
(perfil Pixel, **1080 × 2400 px**, **Android 16 / API 36**), en **modo avión**.
Los reportes CSV/PDF y la cola de alertas son **100 % locales**.

> **Nota metodológica.** Los archivos se generan dentro del sandbox de la app
> (`<documentos>/exports/`) y solo salen del dispositivo si el usuario pulsa
> "Compartir". En las capturas la ruta se muestra **relativa** a documentos
> (`exports/…`) para no exponer la ruta absoluta del sandbox.
>
> La posición GPS de los datos de ejemplo se simuló con
> `adb emu geo fix -72.98765 11.24712` (en un equipo real la toma el GPS).

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`11_reporte_filtros.png`](11_reporte_filtros.png) | Pantalla **Reportes**: filtros de fecha, comunidad/ranchería y estado, con **Generar CSV** y **Generar PDF**. |
| [`12_reporte_csv_generado.png`](12_reporte_csv_generado.png) | Diálogo del CSV: ruta relativa (`exports/…`), **Compartir / Abrir / Cerrar**. |
| [`13_reporte_pdf_preview.png`](13_reporte_pdf_preview.png) | Vista previa del **PDF** (`printing`/`PdfPreview`): encabezado, resumen por semáforo, tabla de casos ROJO con coordenadas y pie con la nota de T/E y P/E. |
| [`14_alertas_pendientes.png`](14_alertas_pendientes.png) | Pantalla **Alertas SMS** con los **3 estados**: `Enviada` (verde), `Fallida` (rojo, con Reintentar) y `Pendiente` (gris, con Enviar). |
| [`14b_alertas_error_intent.png`](14b_alertas_error_intent.png) | Evidencia de soporte: el SnackBar real muestra `ACTIVITY_NOT_FOUND` para el intent `sms:?body=…` cuando no hay app de SMS disponible. |

La captura **15 (zonas en riesgo)** se agregará en el siguiente bloque.

## Mapeo a requerimientos

| Requerimiento | Estado | Evidencia |
|---|---|---|
| **RF-09** — Reporte consolidado filtrable (CSV/PDF) | **CSV + PDF implementados**. Pendiente Sprint 4: Talla/Edad y Peso/Edad (solo hay Peso/Talla). | `11`, `12`, `13` |
| **RF-10** — Alerta por SMS / sincronización diferida | **Cola local + envío por intent de SMS** (`sms:?body=`, sin destinatario ni `SEND_SMS`). Enrutamiento automático a centros de salud vía API queda para Sprint 4 (`SincronizacionStrategy` preparada). | `14`, `14b` |
| **RNF-01** — Offline | Reportes y cola de alertas 100 % locales (modo avión). | `11`–`14` |
| **RNF-02** — Rendimiento | 500 registros generan PDF en < 5 s (test con umbral holgado). | tests |
| **RNF-05** — Validación de rangos | `ReporteFiltros.validar()` rechaza `fecha_fin < fecha_inicio`. | tests |
| **RNF-06** — Seguridad local | Archivos en el sandbox; la UI muestra solo la ruta relativa. | `12`, `13` |

## Notas técnicas

- **PDF**: fuente Helvetica (Latin-1) → tildes/ñ correctas. El guion largo `—`
  (U+2014) no está en Latin-1, así que el pie usa `-` y las coordenadas ausentes
  se muestran como `N/D` para no dejar glifos faltantes.
- **Alertas**: al guardar una evaluación **ROJO** se encola una alerta
  (`alertas_pendientes`, esquema v3). El envío abre la app de SMS del sistema con
  `sms:?body=<mensaje>` (sin destinatario) usando `url_launcher`
  (`LaunchMode.externalApplication`). **No se usa `SEND_SMS`.**
- **Cómo se generaron los 3 estados de la captura 14** (dato real, no mockup):
  1. Se registraron 3 evaluaciones ROJA en la app → 3 alertas `Pendiente`.
  2. Se envió la primera: Google Messages estaba disponible y el intent se
     lanzó → `Enviada` (con `fecha_envio`).
  3. Para la `Fallida`, se deshabilitó temporalmente Google Messages
     (`pm disable-user`), se intentó el envío → `ACTIVITY_NOT_FOUND` → `Fallida`
     (ver `14b`), y se volvió a habilitar.
  4. La tercera se dejó `Pendiente`.
- **Limitación del emulador**: Google Messages abre en modo *onboarding* (sin
  cuenta), por lo que el cuerpo prellenado no siempre se ve en el compositor;
  el intent y el `body` sí son correctos (se ven en el URI del error de `14b`).
  En un equipo con app de SMS configurada, el brigadista elige el destinatario.
- **Ruta futura**: `SincronizacionStrategy` es la interfaz para una
  `ApiStrategy` de sincronización web (Sprint 4).

## Cómo reproducir

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter run -d emulator-5554   # o instalar el APK de debug

# Reportes: login demo -> "Reportes CSV/PDF"
# Alertas:  login demo -> "Alertas SMS"
```

Las capturas se tomaron con `adb exec-out screencap -p` con la app en ejecución.
