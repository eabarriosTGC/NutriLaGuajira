# Evidencias de ejecución — Sprint 3: Reportes (CSV)

Capturas tomadas con la app **instalada y ejecutándose** en un emulador Android
(perfil Pixel, **1080 × 2400 px**, **Android 16 / API 36**), en **modo avión**.
El reporte CSV es **100 % local**: no requiere red ni GPS para generarse.

> **Nota metodológica.** El CSV se genera dentro del sandbox de la app
> (`<documentos>/exports/`) y solo sale del dispositivo si el usuario pulsa
> "Compartir". En la captura `12` la ruta se muestra **relativa** a documentos
> (`exports/…`) para no exponer la ruta absoluta del sandbox.

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`11_reporte_filtros.png`](11_reporte_filtros.png) | Pantalla **Reportes**: filtros de fecha inicial/final, comunidad/ranchería y estado nutricional, con el botón **Generar CSV**. |
| [`12_reporte_csv_generado.png`](12_reporte_csv_generado.png) | Diálogo tras generar el CSV: ruta relativa (`exports/…`) y botones **Compartir**, **Abrir** y **Cerrar**. |

Las capturas **13 (PDF)**, **14 (alertas)** y **15 (zonas en riesgo)** se
agregarán en los siguientes bloques del Sprint 3.

## Mapeo a requerimientos

| Requerimiento | Estado en este bloque | Evidencia |
|---|---|---|
| **RF-09** — Reporte consolidado filtrable por fecha/comunidad/estado (CSV/PDF) | **Parcial**: CSV implementado con filtros, BOM UTF-8 y escape RFC 4180. PDF queda para el Bloque C. | `11`, `12` |
| **RNF-01** — Offline | La generación del CSV es 100 % local (modo avión). | `11`, `12` |
| **RNF-05** — Validación de rangos | `ReporteFiltros.validar()` rechaza `fecha_fin < fecha_inicio`; no se genera archivo. | tests |
| **RNF-06** — Seguridad local | Archivo en el sandbox de la app; la UI muestra solo la ruta relativa. | `12` |

## Límites conocidos (honestidad)

- El CSV incluye las columnas `z_talla_edad` y `z_peso_edad`, pero salen
  **vacías**: Talla/Edad y Peso/Edad **no se calculan** en esta versión (solo
  Peso/Talla). Marcado como `TODO(sprint4)` en el código.
- **PDF** aún no existe en este bloque (se implementa en el Bloque C).
- El SMS/sincronización diferida corresponde al Bloque D.

## Cómo reproducir

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter run -d emulator-5554   # o instalar el APK de debug

# En la app: login demo -> menú -> "Reportes CSV · PDF próximo bloque"
# 1) ajustar filtros  2) "Generar CSV"
```

Las capturas se tomaron con `adb exec-out screencap -p` con la app en ejecución.
