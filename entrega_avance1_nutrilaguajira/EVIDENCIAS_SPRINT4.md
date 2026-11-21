# Evidencias de ejecución — Sprint 4 técnico (post-entrega)

Documento de apoyo para la sección 6.2 del plan de trabajo.

> **Importante (honestidad de alcance).** El plan de trabajo **ya fue entregado**
> con los porcentajes **35 / 20 / 0 / 40** (Sprint 3). Este **Sprint 4 técnico es
> post-entrega** y mejora la calidad del producto; **no cambia los porcentajes del
> plan entregado**, los complementa. La fase de implementación en campo sigue
> programada para **2027-1**.

Las capturas están en
[`screenshots/sprint4_te_pe/`](screenshots/sprint4_te_pe/README.md).

## 6.1 Resumen del avance post-entrega (Sprint 4 técnico)

El plan de trabajo se entregó con un **35 % de preparación técnica**. El Sprint 4
técnico cierra tres deudas del producto:

1. **Talla/Edad y Peso/Edad** con tablas **LMS (DEMO)** y migración de esquema v4.
2. **Corrección del bug de `historial_screen`** (`setState` que devolvía un
   `Future`).
3. **TTF local para el PDF** (Roboto, Apache 2.0), con em-dash, `«»`, `¿¡`,
   tildes y ñ.

El producto queda listo para la fase de implementación en campo (2027-1). El
avance del plan de trabajo sigue siendo **35 % técnico + 65 % campo**: el Sprint 4
técnico **no** cambia los porcentajes del plan, porque las actividades de campo se
ejecutan en 2027-1. El Sprint 4 técnico **eleva la calidad del producto**, no el
porcentaje del plan.

**Calidad:** **101/101 tests** verdes, `flutter analyze` 0 issues, `dart format`
sin cambios pendientes.

## 6.2 Evidencias de ejecución (Sprint 4 técnico)

| Objetivo | % Cumplimiento | Evidencia | Observación |
|---|---|---|---|
| **T/E y P/E con tablas LMS** | **100 % (DEMO)** / 40 % (oficial) | Motor + migración v4 + UI + CSV + PDF + 13 tests. Capturas [`17`](screenshots/sprint4_te_pe/17_resultado_te_pe.png) y [`18`](screenshots/sprint4_te_pe/18_detalle_te_pe.png). | Implementado con tabla **DEMO**. El reemplazo por la OMS oficial es un gate post-Sprint 4. |
| **Corregir `historial_screen`** | **100 %** | Fix de `setState` + 2 tests (refresco y estado vacío). | Deuda cerrada. |
| **TTF local para el PDF** | **100 %** | Roboto Apache 2.0 + captura [`16`](screenshots/sprint4_te_pe/16_pdf_ttf.png). | Em-dash, `«»`, `¿¡`, tildes y ñ soportados. |
| **Tests y calidad** | **100 %** | 101/101 tests verdes, `flutter analyze` 0 issues, `dart format` limpio. | — |

## Deudas que salen del Sprint 4

- **T/E y P/E con tablas DEMO** → reemplazo por la tabla OMS oficial (mismo
  formato LMS) = **Gate 1** del
  [`ROADMAP_INTEROPERABILIDAD.md`](ROADMAP_INTEROPERABILIDAD.md) (post-Sprint 4).
- **Sincronización API** → sigue bloqueada por los Gates 1–3.
- **Enrutamiento SMS a centros de salud** → fase institucional.

## Commits del Sprint 4

| Commit | Contenido |
|---|---|
| `fa91707` | T/E y P/E con tablas LMS (DEMO) y migración v4. |
| `e7f9ef9` | T/E y P/E en UI, CSV y PDF. |
| `86d14be` | Docs: DEMO y gate de reemplazo oficial. |
| `a35633b` | Fix de `historial_screen` (`setState`). |
| `d11d14e` | TTF local (Roboto) y em-dash en el PDF. |
| `6ea5323` | Docs: historial corregido y PDF con TTF. |
| `ff7b10d` | Test: estado vacío de historial. |
| `d506cf1` | Cerrar set sprint4_te_pe con capturas 16–18 y README. |
| `79af917` | EVIDENCIAS_SPRINT4.md con tabla de cierre. |
| `4badfec` | ESTADO.md: Sprint 4 técnico COMPLETO. |
| `518cc91` | Verificación final de coherencia. |
