# Evidencias de ejecución — Sprint 3: Reportes (CSV/PDF)

Capturas tomadas con la app **instalada y ejecutándose** en un emulador Android
(perfil Pixel, **1080 × 2400 px**, **Android 16 / API 36**), en **modo avión**.
Los reportes CSV y PDF son **100 % locales**: no requieren red para generarse.

> **Nota metodológica.** Los archivos se generan dentro del sandbox de la app
> (`<documentos>/exports/`) y solo salen del dispositivo si el usuario pulsa
> "Compartir". En las capturas la ruta se muestra **relativa** a documentos
> (`exports/…`) para no exponer la ruta absoluta del sandbox.
>
> La posición GPS usada en los datos de ejemplo se simuló con
> `adb emu geo fix -72.98765 11.24712` (en un equipo real la toma el GPS).

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`11_reporte_filtros.png`](11_reporte_filtros.png) | Pantalla **Reportes**: filtros de fecha inicial/final, comunidad/ranchería y estado nutricional, con los botones **Generar CSV** y **Generar PDF**. |
| [`12_reporte_csv_generado.png`](12_reporte_csv_generado.png) | Diálogo tras generar el CSV: ruta relativa (`exports/…`) y botones **Compartir**, **Abrir** y **Cerrar**. |
| [`13_reporte_pdf_preview.png`](13_reporte_pdf_preview.png) | Vista previa del **PDF** (`printing`/`PdfPreview`): encabezado, resumen con contadores por semáforo, tabla de casos críticos (rojo) con coordenadas y pie con la nota de T/E y P/E. |

Las capturas **14 (alertas)** y **15 (zonas en riesgo)** se agregarán en los
siguientes bloques del Sprint 3.

## Mapeo a requerimientos

| Requerimiento | Estado en este bloque | Evidencia |
|---|---|---|
| **RF-09** — Reporte consolidado filtrable por fecha/comunidad/estado (CSV/PDF) | **CSV + PDF implementados** con filtros. Pendiente Sprint 4: Talla/Edad y Peso/Edad (solo hay Peso/Talla). | `11`, `12`, `13` |
| **RNF-01** — Offline | Generación 100 % local (modo avión). | `11`, `12`, `13` |
| **RNF-02** — Rendimiento | 500 registros generan PDF en < 5 s (test con umbral holgado). | tests |
| **RNF-05** — Validación de rangos | `ReporteFiltros.validar()` rechaza `fecha_fin < fecha_inicio`. | tests |
| **RNF-06** — Seguridad local | Archivos en el sandbox; la UI muestra solo la ruta relativa. | `12`, `13` |

## Notas técnicas

- **Fuente del PDF**: Helvetica incorporada de `pdf`, que cubre **Latin-1**
  (tildes, ñ, ¿, ·). El guion largo `—` (U+2014) **no** está en Latin-1, así que
  el pie usa `-` para evitar un glifo faltante. Ver `13` para confirmar tildes.
- **Vista previa**: `printing` (`PdfPreview`) muestra el PDF en la app y permite
  imprimir/compartir. El diálogo también ofrece Compartir (`share_plus`) y Abrir
  (`open_filex`).
- **Limitación honesta**: el PDF y el CSV incluyen `z_talla_edad`/`z_peso_edad`
  vacías porque T/E y P/E no se calculan en esta versión (solo Peso/Talla). El
  pie del PDF lo declara explícitamente.

## Cómo reproducir

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter run -d emulator-5554   # o instalar el APK de debug

# En la app: login demo -> menú -> "Reportes CSV/PDF"
# 1) ajustar filtros  2) "Generar CSV" o "Generar PDF"
```

Las capturas se tomaron con `adb exec-out screencap -p` con la app en ejecución.
