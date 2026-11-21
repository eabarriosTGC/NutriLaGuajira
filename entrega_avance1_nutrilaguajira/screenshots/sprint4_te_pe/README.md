# Evidencias — Sprint 4 técnico (T/E, P/E, PDF con TTF)

Capturas de la app **instalada y ejecutándose** en un emulador Android
(1080 × 2400 px, Android 16 / API 36), en **modo avión**. La evaluación de
ejemplo es un varón de 26 meses, 8.80 kg, 85.0 cm y MUAC 12.0 cm (ROJO).

> **Nota metodológica.**
> - La **captura 16** es una página de PDF renderizada con `pdftoppm` a partir del
>   PDF real que genera `ReportePdfService` (no es un mockup).
> - En las capturas 17–18 no se capturó GPS (la fila dice "No capturada"); cuando
>   se usa, la posición se simula con `adb emu geo fix`.
> - La TTF es **Roboto** (Apache 2.0) empaquetada en `assets/fonts/`; sin red ni
>   Google Fonts.
> - Las tablas T/E y P/E son **DEMO (LMS)**; el reemplazo por la OMS oficial es
>   un gate post-Sprint 4 (ver abajo).

## Índice de capturas

| Archivo | Qué muestra |
|---|---|
| [`16_pdf_ttf.png`](16_pdf_ttf.png) | **PDF con TTF local**: nombre `Andrés—«Wayuu» Jusayú ¿¡?`, columnas **Z P/T, Z T/E, Z P/E**, coordenadas y pie con em-dash (`—`) y la nota de fuente DEMO. |
| [`17_resultado_te_pe.png`](17_resultado_te_pe.png) | **Resultado** ROJO con **Z P/T −2.27**, **Z Talla/Edad −1.16** y **Z Peso/Edad −2.59**, más la nota de que T/E y P/E son informativos. |
| [`18_detalle_te_pe.png`](18_detalle_te_pe.png) | **Detalle** del tamizaje con las filas **Z Talla/Edad** y **Z Peso/Edad** y la trazabilidad de los criterios T/E y P/E. |

## Mapeo honesto al Sprint 4 técnico

| Ítem | Estado | Evidencia |
|---|---|---|
| T/E y P/E con tablas LMS | **Implementado con tabla DEMO** (no oficial) | `17`, `18` |
| `historial_screen` corregido | **100 %** (deuda cerrada) | 2 tests (ver repo) |
| TTF local para el PDF | **100 %** (Roboto Apache 2.0) | `16` |
| Calidad | **101/101 tests**, `flutter analyze` 0 issues, `dart format` limpio | — |

## Deudas que salen del Sprint 4

- **T/E y P/E con tablas DEMO** → el reemplazo por la tabla OMS oficial (mismo
  formato LMS) es el **Gate 1** del
  [`ROADMAP_INTEROPERABILIDAD.md`](../ROADMAP_INTEROPERABILIDAD.md) (post-Sprint 4).
  No requiere tocar código: se reemplaza el CSV.
- **Sincronización API** → sigue bloqueada por los Gates 1–3 del roadmap.
- **Enrutamiento SMS a centros de salud** → fase institucional.

## Cómo reproducir

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter run -d emulator-5554   # o instalar el APK de debug

# 16: login demo -> Reportes -> Generar PDF -> Vista previa (o el PDF de ejemplo)
# 17: login demo -> Nuevo tamizaje -> Andrés -> 8.8 / 85 / 12 -> Calcular
# 18: desde el resultado -> Ver historial -> tocar el tamizaje recién creado
```

Las capturas 17–18 se tomaron con `adb exec-out screencap -p` con la app en
ejecución; la 16 se renderizó con `pdftoppm`.
