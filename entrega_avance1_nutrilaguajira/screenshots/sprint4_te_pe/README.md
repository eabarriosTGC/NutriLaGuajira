# Evidencias — Sprint 4 (T/E, P/E y PDF con TTF)

Set **en construcción**. El cierre (índice completo, mapeo a objetivos y
`EVIDENCIAS_SPRINT4.md`) se completa en el Bloque 3 del Sprint 4.

## Capturas

| Archivo | Qué muestra |
|---|---|
| [`16_pdf_ttf.png`](16_pdf_ttf.png) | PDF generado por la app con la **TTF local (Roboto)**: nombre `Andrés—«Wayuu» Jusayú ¿¡?`, columnas **Z P/T, Z T/E, Z P/E**, coordenadas y pie con em-dash (`—`) y la nota de fuente DEMO. Las tildes/ñ también se renderizan correctamente. |

> El PDF se generó con `ReportePdfService` (el mismo que usa la app) y se
> renderizó con `pdftoppm`; no es un mockup. La TTF es Roboto (Apache 2.0)
> empaquetada en `assets/fonts/`, sin red ni Google Fonts.
