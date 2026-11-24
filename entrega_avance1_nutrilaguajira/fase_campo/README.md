# Fase de campo 2027-1 — validación, capacitación y ética

Documentos de trabajo para ejecutar la **implementación en campo** del plan
(65 % restante). No son un sprint de código: son los materiales que permiten
llevar la app a 3 rancherías piloto con promotores y estudiantes de Uniguajira.

> **Estado: BORRADOR v0.1 (2026-11-21), para revisión con Uniguajira y la
> Secretaría de Salud.** Ningún documento de esta carpeta ha sido validado aún
> por la institución, por el comité de ética ni por hablantes nativos de
> wayuunaiki. Los umbrales, el cronograma y los textos de consentimiento son
> **propuestas** que deben aprobarse antes de usarse.
>
> **Actualización 2026-11-24 — cambio de alcance técnico.** La app ahora
> incorpora **sincronización con Cloud Firestore** (login con Firebase Auth,
> subida de infantes, evaluaciones y alertas ROJAS). Esto **contradice la versión
> anterior de estos documentos**, que asumía que los datos no salían del
> teléfono. Los textos afectados (`CONSENTIMIENTO_INFORMADO.md` §7–8,
> `PROTOCOLO_VALIDACION.md` §7, `GUIA_USUARIO.md` §9) ya se actualizaron para
> declararlo, pero **el tratamiento en la nube exige aprobación del comité de
> ética y un acuerdo de tratamiento de datos con Google antes del piloto**.

## Contenido

| Documento | Para qué sirve | Quién lo usa |
|---|---|---|
| [`PROTOCOLO_VALIDACION.md`](PROTOCOLO_VALIDACION.md) | Diseño del piloto en 3 rancherías, criterios de éxito, cronograma, ética y plan de análisis. | Coordinación del proyecto, Uniguajira, Secretaría |
| [`GUIA_USUARIO.md`](GUIA_USUARIO.md) | Guía rápida del promotor (español): instalar, tamizar, leer el semáforo, reportar. | Promotores y gestores comunitarios |
| [`GUIA_USUARIO_WAYUUNAIKI.md`](GUIA_USUARIO_WAYUUNAIKI.md) | Plantilla bilingüe español/wayuunaiki para la explicación oral. **Traducción pendiente de validación.** | Promotores wayuuhablantes, facilitadores |
| [`CAPACITACION.md`](CAPACITACION.md) | Taller de 4 horas: agenda, ejercicios, evaluación y certificación. | Facilitadores, estudiantes |
| [`CONSENTIMIENTO_INFORMADO.md`](CONSENTIMIENTO_INFORMADO.md) | Consentimiento del tutor y asentimiento, con Ley 1581 y transferencia a terceros. | Promotores, comité de ética |
| [`INSTRUMENTOS/`](INSTRUMENTOS/README.md) | Formularios de campo y plantillas CSV para registrar los datos del piloto. | Observadores y coordinación |

## Lo que estos documentos NO son

- **No son validación clínica.** La app usa tablas **DEMO**; el piloto mide
  usabilidad, factibilidad y consistencia interna del cálculo, no validez
  diagnóstica. El reemplazo por las tablas OMS oficiales es el **Gate 1** del
  [`ROADMAP_INTEROPERABILIDAD.md`](../ROADMAP_INTEROPERABILIDAD.md).
- **No sustituyen la atención en salud.** Un caso ROJO se refiere a la
  Secretaría/PMA por los canales existentes; la app solo tamiza y alerta.
- **Sí hay nube, y hay que gobernarla.** La versión actual sincroniza con
  **Cloud Firestore** (proyecto `nutrilaguajira`, región `us-east1`) cuando se
  inicia sesión con una cuenta de **Firebase Auth**; la cuenta demo local
  (`promotor` / `demo123`) no sincroniza. Enviar datos de menores a Google exige
  consentimiento explícito, acuerdo de tratamiento (encargado del tratamiento) y
  aprobación del comité de ética. La **interoperabilidad institucional (FHIR/API
  con la Secretaría)** sigue bloqueada por los Gates 1–3 del
  [`ROADMAP_INTEROPERABILIDAD.md`](../ROADMAP_INTEROPERABILIDAD.md); Firestore es
  un canal propio, no interoperabilidad.

## Orden de trabajo sugerido

1. **Semana −4:** aprobar el protocolo y el consentimiento con Uniguajira y la
   Secretaría; definir las 3 rancherías (criterios en el protocolo §3).
2. **Semana −2:** validar la guía en wayuunaiki con 2 hablantes nativos;
   imprimir materiales; probar el APK `v0.4.0-sprint4` en los teléfonos reales.
3. **Semana 0:** taller de capacitación (4 h) y consentimientos firmados.
4. **Semanas 1–6:** operación acompañada y observación en las 3 rancherías.
5. **Semanas 7–8:** análisis, informe y decisión **go/no-go** para escalar.

## Responsables (a designar)

| Rol | Responsabilidad |
|---|---|
| Coordinación técnica | Versión del APK instalada, respaldo de datos, incidentes técnicos |
| Coordinación académica (Uniguajira) | Protocolo, ética, análisis y publicación |
| Enlace comunitario | Autorización de la comunidad, convocatoria, logística |
| Enlace institucional (Secretaría/PMA/Baylor) | Referencia de casos ROJO y brigadas |
| Observadores (estudiantes) | Instrumentos, tiempos, bitácora |

Ningún nombre está asignado todavía: se completa en la reunión de arranque.
