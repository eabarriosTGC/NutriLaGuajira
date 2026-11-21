# NutriLaGuajira — Roadmap de interoperabilidad

> **Estado: BORRADOR / HOJA DE RUTA.** Este documento describe *qué* haría falta
> para que NutriLaGuajira pase de ser una app aislada a un **nodo de captura e
> interoperabilidad**. **No es una especificación técnica cerrada** y **no
> autoriza a escribir código** de interoperabilidad: eso solo ocurre cuando se
> cumplan los *gates* de la sección 3.
>
> ⚠️ **Aviso de verificación normativa.** Las fechas, resoluciones y plazos que se
> citan en este documento (Ley 2015 de 2020, Resolución 866 de 2021,
> obligatoriedad del RDA, Guía de Implementación IHCE) **deben verificarse contra
> la fuente oficial del Ministerio de Salud y Protección Social** antes de
> incluirlos en un documento académico o en una propuesta institucional. Si la
> fecha de obligatoriedad no es exacta, el argumento de urgencia se debilita y
> un evaluador puede detectarlo.

---

## 1. Tesis en una página

Hoy NutriLaGuajira resuelve bien el problema de **captura en campo sin
conectividad**: mide, calcula el Z Peso/Talla, semaforiza y guarda en SQLite. Eso
es valioso, pero no resuelve la **fragmentación entre entidades**: el PMA, la
Fundación Baylor, Acción contra el Hambre, la Secretaría de Salud Departamental y
el SIVIGILA (evento 113) mantienen registros separados.

El siguiente salto **no es añadir más funciones a la app**. Es **cambiar su rol
arquitectónico**:

- **Antes:** una app aislada que compite (sin querer) con los sistemas de cada
  entidad y acumula sus propios datos.
- **Después:** un **nodo de captura e interoperabilidad** que sigue funcionando
  offline y, cuando hay red, entrega datos **estandarizados** a los sistemas que
  los necesitan, sin reemplazarlos.

El estándar técnico de destino es **HL7 FHIR Release 4** y el mecanismo nacional
es el **Resumen Digital de Atención (RDA)** sobre la Historia Clínica Electrónica
Interoperable (IHCE). El marco regulatorio existe; lo que falta para este
proyecto es: **terminología validada, un socio con endpoint de prueba,
consentimiento extendido y gobernanza**. Por eso este roadmap empieza por
**gates institucionales**, no por código.

---

## 2. Estado real del repo (a la fecha de este documento)

| Pieza | Estado | Dónde / nota |
|---|---|---|
| `SincronizacionStrategy` | ✅ existe | `lib/services/sincronizacion_strategy.dart` |
| `SmsIntentStrategy` | ✅ existe | `lib/services/sms_intent_strategy.dart` (canal de emergencia) |
| `ApiStrategy` | ⚠️ **TODO** | solo el `TODO(sprint4)`; no implementado |
| `EvaluacionReporte` | ✅ existe | `lib/data/models/evaluacion_reporte.dart` (DTO aplanado) |
| Outbox local | ✅ parcial | `evaluaciones.sincronizado` (hoy siempre 0) + patrón de `alertas_pendientes` |
| Backend / nodo consolidador | ❌ no existe | fuera del APK |
| Mapeo FHIR | ❌ no existe | este roadmap lo propone, no lo implementa |
| Terminología validada | ❌ no existe | CIE-10/11, LOINC/UCUM, perfiles IHCE |
| Consentimiento extendido | ❌ no existe | el actual cubre la app, no el intercambio |
| Gobernanza multi-actor | ❌ no existe | quién opera el nodo y quién ve qué |

**Calidad actual del producto:** `flutter test` 85/85, `flutter analyze` 0
issues, `dart format` limpio. La app funciona 100 % offline.

---

## 3. Gates explícitos

> **Regla dura:** si un gate no está cumplido, **no se escribe código** de esa
> fase. Se puede documentar, negociar y diseñar, pero no implementar.

### Gate 1 — Terminología validada
**Desbloquea:** esqueleto de `FhirMapperService` + tests unitarios (sin envío).

Criterios de salida:
- Códigos y catálogos aprobados para `Condition` (CIE-10/11 y catálogos del
  Minsalud) y para `Observation` de crecimiento (LOINC/UCUM).
- Perfiles y cardinalidades alineados con la **Guía de Implementación IHCE**.
- Decisión documentada sobre identificadores (documento del infante, código de
  ranchería, idempotencia).

Evidencia requerida: documento de mapeo revisado y aprobado por un referente
clínico/epidemiológico.

### Gate 2 — Socio con endpoint de prueba
**Desbloquea:** `ApiStrategy` real + cola/outbox + pruebas de integración en
sandbox.

Criterios de salida:
- Una entidad (Uniguajira, Secretaría de Salud, PMA, Baylor u otra) provee un
  **endpoint sandbox** y credenciales.
- Acuerdo de uso de datos de prueba y responsable técnico del lado del socio.

Evidencia requerida: endpoint documentado, entorno sandbox y acta de acuerdo.

### Gate 3 — Consentimiento extendido aprobado
**Desbloquea:** envío real de datos (producción).

Criterios de salida:
- Consentimiento informado que cubra el **intercambio con terceros** (Ley 1581 de
  2012), con minimización, finalidad y retención.
- Revisión ética/jurídica y acta de aprobación.

Evidencia requerida: formato aprobado + acta.

---

## 4. Fases (cada una atada a su gate)

### Fase 1 — Alinear el modelo al estándar (post Gate 1)
- **Objetivo:** hablar el idioma del ecosistema sin romper la base local.
- **Entregables:** `FhirMapperService` (esqueleto) que transforme
  `EvaluacionReporte` a un `Bundle` FHIR tipo `document`
  (`Composition` + `Patient` + `Observation` + `Condition` + `Location`);
  pruebas unitarias de estructura.
- **No incluye:** envío, backend, endpoint real.
- **Criterio de salida:** mapper validado contra terminología (Gate 1) y tests en
  verde. Sin conformidad IHCE declarada.

### Fase 2 — Puente de sincronización (post Gate 2)
- **Objetivo:** enviar `Bundle` cuando el promotor recupera conectividad.
- **Entregables:** `ApiStrategy` sobre `SincronizacionStrategy`; outbox con
  idempotencia (UUID por evaluación), reintentos y marca `sincronizado=1`;
  `SmsIntentStrategy` como *fallback*.
- **No incluye:** envío a producción; solo sandbox.
- **Criterio de salida:** integración en sandbox con el socio, sin pérdida ni
  duplicados en pruebas controladas.

### Fase 3 — Gobernanza multi-actor (post Gate 3 y acuerdo institucional)
- **Objetivo:** que las entidades confíen y compartan.
- **Entregables:** acuerdo de gobernanza (dueño del dato primario, qué ve cada
  actor, base legal, quién opera el nodo), política de retención y auditoría.
- **No incluye:** cambios de código por sí sola.
- **Criterio de salida:** acuerdo firmado; recién entonces se habilita el envío
  real.

---

## 5. Mapeo FHIR propuesto

> **Sujeto a validación contra la Guía de Implementación IHCE y la terminología
> del Minsalud.** Este mapeo es una **hipótesis de trabajo**, no una
> especificación conforme. Los códigos, perfiles, cardinalidades y extensiones
> deben validarse antes de implementarse (Gate 1).

| Dato actual de NutriLaGuajira | Recurso FHIR equivalente | Observación |
|---|---|---|
| `ninos` (infante) | `Patient` | Fecha de nacimiento, sexo, identificador |
| `evaluaciones` (medición) | `Observation` (perfil de crecimiento) | Peso, talla, MUAC, Z-score; unidades UCUM |
| Clasificación ROJO/AMARILLO/VERDE | `Condition` | Código CIE-10/11 y catálogo del Minsalud |
| Ubicación GPS | `Location` o extensión en `Observation` | Georreferenciación de la ranchería |
| Ranchería / comunidad | `Organization` o `Location` | Agregación por zona |

El envío se plantea como un **`Bundle` de tipo `document`** con una `Composition`
como recurso principal, siguiendo el mecanismo del RDA. La app **no** cambiaría su
modelo local: el mapper es una capa de servicios que se ejecuta al sincronizar.

---

## 6. Riesgos y dependencias institucionales

- **Terminología y conformidad:** “FHIR válido” no equivale a “conforme a la guía
  IHCE”. Sin Gate 1 el código sería *vaporware*.
- **Consentimiento y protección de datos:** la Ley 1581 de 2012 exige finalidad,
  minimización y seguridad; el consentimiento actual no cubre terceros.
- **Gobernanza:** quién opera el nodo (Uniguajira, Secretaría o consorcio) y qué
  ve cada actor es una decisión política, no técnica.
- **SIVIGILA evento 113:** la Secretaría ya opera un aplicativo para el registro
  diario; hay que integrarse, no competir.
- **Conectividad intermitente** en La Guajira: el modo offline debe seguir siendo
  la norma, no la excepción.
- **Heterogeneidad de capacidades** entre prestadores y regiones.
- **Riesgo político:** percepción de que la app reemplaza sistemas existentes.
  Debe presentarse como **bien público digital** y *middleware*, no como
  competidor.
- **Riesgo de “vaporware”:** código que pasa tests pero no es interoperable. Es
  exactamente lo que estos gates buscan evitar.

---

## 7. Qué NO hace este roadmap

- ❌ No implementa un backend ni un nodo consolidador.
- ❌ No define ni configura un endpoint real.
- ❌ No envía datos a ninguna entidad.
- ❌ No crea `FhirMapperService`, `ApiStrategy` ni tests de FHIR.
- ❌ No agrega dependencias (`http`, `uuid`, etc.).
- ❌ No declara conformidad con la IHCE ni con el RDA.
- ❌ No sustituye la validación con la Secretaría de Salud ni con el Minsalud.
- ❌ No cambia el modelo local ni el funcionamiento offline de la app.

---

## 8. Deudas que se mantienen

Estas deudas son independientes de la interoperabilidad y **sí** pueden abordarse
en el Sprint 4 técnico:

- **Talla/Edad y Peso/Edad** (tablas OMS por edad + motor + migración).
- **`historial_screen`**: `setState` con callback que devuelve un `Future` (deuda
  de mantenimiento detectada en el Sprint 3).
- **TTF opcional para el PDF** (hoy Helvetica cubre Latin-1; el guion largo
  U+2014 se sustituye por `-`).
- **Editar / borrar evaluaciones** (hoy solo inserción y lectura).
- **APK de distribución** (keystore + `--release` + `--split-per-abi`).
- **Validación en campo y capacitación** (2026-2).

La **sincronización API** y el **enrutamiento SMS a centros de salud** no son
deudas técnicas del Sprint 4: son **fase institucional post-Sprint 4** y dependen
de los Gates 2 y 3.

---

## 9. Definición de “roadmap cumplido”

El roadmap se considerará ejecutado cuando existan, en este orden:

1. Gate 1 aprobado (terminología) y mapper validado.
2. Gate 2 aprobado (endpoint sandbox) e integración sin pérdida/duplicados.
3. Gate 3 aprobado (consentimiento) y acuerdo de gobernanza firmado.
4. Envío controlado a producción con auditoría y retención definidas.

Hasta entonces, el estado de la interoperabilidad es **BLOQUEADO** y **no se
escribe código** de FHIR/`ApiStrategy`.

---

## 10. Referencias a verificar contra fuente oficial

- **Ley 2015 de 2020** (Historia Clínica Electrónica Interoperable).
- **Resolución 866 de 2021** (conjunto de datos clínicos para el intercambio).
- **Resumen Digital de Atención (RDA)** y su manual/Guía de Implementación IHCE.
- **HL7 FHIR Release 4**.
- **Ley 1581 de 2012** (protección de datos personales).
- **SIVIGILA, evento 113** (desnutrición aguda) y el aplicativo de la Secretaría.

> Todas las fechas y plazos citados en este documento quedan **pendientes de
> verificación** contra la fuente oficial del Ministerio de Salud y Protección
> Social antes de su uso en documentos académicos.
