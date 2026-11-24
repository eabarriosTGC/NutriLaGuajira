# Consentimiento informado — piloto NutriLaGuajira 2027-1

**Versión:** 0.2 (borrador; incorpora la sincronización con Cloud Firestore)
**Fecha:** 2026-11-21
**Responsable del tratamiento:** Universidad de La Guajira (Uniguajira) —
proyecto NutriLaGuajira. *El nombre del investigador principal y los datos de
contacto se completan al ser aprobado.*
**Marco:** Ley 1581 de 2012 · Decreto 1377 de 2013 · Resolución 8430 de 1993 ·
Ley 1098 de 2016.

> **Este texto no está aprobado todavía.** No puede usarse en campo hasta que lo
> revise el comité de ética de Uniguajira y la oficina jurídica. Los espacios
> entre corchetes se completan antes de imprimir.

---

## 1. Invitación

Usted está invitado a autorizar la participación de **su hijo, hija o niño bajo
su cuidado** en un piloto del proyecto **NutriLaGuajira**, una aplicación para
teléfono que ayuda a los promotores de salud a medir el estado nutricional de
niños menores de 5 años **sin necesidad de internet**.

Antes de decidir, lea o escuche esta información. Si algo no entiende, pregunte.
Tómese el tiempo que necesite. **Puede decir que no**, y eso no afecta la
atención que recibe el niño.

---

## 2. ¿Para qué se hace?

Queremos saber si la aplicación es **fácil de usar, útil y segura** en la
ranchería, y si el promotor puede explicar el resultado a la familia. No
estamos probando un medicamento ni un tratamiento. La aplicación **no
diagnostica**: mide, calcula y avisa.

---

## 3. ¿Qué pasará si usted acepta?

1. El promotor le hará unas preguntas sobre el niño (nombre, fecha de
   nacimiento, sexo, ranchería, tutor) y las registrará en el teléfono.
2. Medirá **peso, talla y perímetro del brazo**, y revisará si hay **hinchazón
   en los pies (edema)**. Son medidas externas, no dolorosas; toma unos 5
   minutos.
3. La aplicación mostrará un **color** (verde, amarillo o rojo) y una
   recomendación.
4. Si el color es **rojo**, el promotor **avisará el mismo día** al puesto o
   brigada de salud por el canal acordado.
5. Es posible que un estudiante **observe** la actividad para tomar notas sobre
   el uso de la app. No toma fotos del niño sin un permiso aparte.

**Frecuencia:** una o dos visitas durante el piloto (aproximadamente 6 semanas).
**Duración de cada visita:** 5–10 minutos por niño.

---

## 4. ¿Qué datos se recogen y para qué?

| Dato | ¿Obligatorio? | Para qué |
|---|---|---|
| Nombres y apellidos del niño | Sí | Identificarlo en el historial y en la alerta |
| Documento de identidad | Opcional | Evitar duplicados; si no lo tiene, se deja vacío |
| Fecha de nacimiento, sexo | Sí | Calcular la edad en meses y el Z |
| Nombre del tutor y ranchería | Sí | Contacto y consolidación por zona |
| Peso, talla, perímetro del brazo, edema | Sí | Calcular el estado nutricional |
| Coordenadas GPS | **Opcional** | Ubicar la ranchería en los reportes de zona |
| Color y clasificación | Sí | Historial, reportes y alertas |
| Observaciones del estudiante | Sí (anonimizadas) | Evaluar la usabilidad de la app |

**No se recogen** datos de salud distintos de los anteriores, ni imágenes, ni
datos de otros miembros de la familia.

---

## 5. ¿Qué riesgos tiene?

- **Molestia mínima:** medir puede incomodar al niño unos segundos.
- **Privacidad local:** los datos quedan **en el teléfono del promotor**, en una
  base de datos **sin cifrar**. El teléfono se protege con PIN y queda bajo
  custodia del promotor. Existe el riesgo de pérdida o robo del equipo; si
  ocurre, se informa y se toman las medidas del caso.
- **Privacidad en la nube:** si se usa una cuenta de Firebase, los datos se
  envían a **Google Cloud (Firestore, `us-east1`)**. Un acceso indebido a esa
  cuenta o un error de reglas podría exponer los datos de varios niños. Las
  reglas limitan cada promotor a su carpeta, pero las **alertas ROJAS** son
  legibles por cualquier usuario autenticado del proyecto.
- **Alerta por mensaje de texto:** el mensaje de alerta **incluye el nombre del
  niño y la ranchería** y viaja **sin cifrar**. Se envía **solo al número
  institucional** definido por el proyecto, nunca a contactos personales.
- **Estigma:** hablar de desnutrición puede incomodar a la familia. El promotor
  explicará el resultado con respeto y sin exponer al niño frente a otros.
- **Resultado inexacto:** la app usa **tablas de referencia académicas (DEMO)**,
  no las tablas oficiales. Por eso **no sustituye** una valoración clínica y
  cualquier caso rojo se remite a salud.

**Riesgo global:** mínimo, según la Resolución 8430 de 1993.

---

## 6. ¿Qué beneficios tiene?

- Para el niño: **detección temprana** y remisión oportuna si hay riesgo.
- Para la familia: información clara sobre el estado nutricional y qué hacer.
- Para la comunidad: datos para pedir brigadas y apoyos.
- No hay pago ni compensación económica por participar.

---

## 7. Confidencialidad y tratamiento de los datos

- **Responsable:** Uniguajira — proyecto NutriLaGuajira.
- **Finalidad:** exclusivamente el piloto, la evaluación de la aplicación y la
  elaboración de informes académicos.
- **Acceso:** el promotor (en el teléfono), la coordinación del proyecto y el
  equipo de análisis.
- **Anonimización:** para los análisis se eliminan nombres y apellidos y se usa
  un código (`R1-001`). La lista que relaciona el código con el nombre queda
  solo en poder de la coordinación, en un archivo separado.
- **Conservación:** los datos permanecen hasta el cierre del informe; después se
  borran del teléfono y se conserva solo el archivo anonimizado.
- **Seguridad:** PIN en el dispositivo, sin cuentas personales en el teléfono y
  sin aplicaciones de mensajería con historial del proyecto.
- **Nube:** si se usa una cuenta institucional de Firebase, los datos se
  sincronizan a **Google Cloud (Cloud Firestore)**, ver §8. Con la cuenta demo
  local no se envía nada.
- **Datos de menores:** son **datos sensibles**; su tratamiento requiere su
  autorización expresa como representante legal.

---

## 8. ¿Se comparten datos con terceros?

**Sí, con un proveedor de nube, y solo si se usa una cuenta institucional.**

| Aspecto | Detalle |
|---|---|
| Proveedor | **Google LLC — Cloud Firestore** (encargado del tratamiento) |
| Ubicación | región **`us-east1`** (Estados Unidos) |
| Qué se envía | nombres y apellidos, documento (si se registró), fecha de nacimiento, sexo, tutor, ranchería, peso, talla, MUAC, edema, Z-scores, clasificación, coordenadas (si se capturaron) |
| Qué **no** se envía | PDF, imágenes, audios, datos de otros familiares |
| Cuándo | al guardar y al recuperar conexión, si la sesión es de Firebase Auth |
| Quién puede leerlo | el promotor dueño de la cuenta y, para las **alertas ROJAS**, cualquier usuario autenticado del proyecto (panel central) |

- La **cuenta demo** (`promotor` / `demo123`) no sincroniza: los datos quedan
  solo en el teléfono.
- Google cifra los datos en tránsito y en reposo, pero **los campos se guardan
  legibles** para el personal autorizado. No es un almacenamiento cifrado de
  extremo a extremo.
- Usted puede **negar** la sincronización: en ese caso el piloto se hace con la
  cuenta demo y los datos no salen del dispositivo.

Si en una fase posterior se habilita la **interoperabilidad institucional**
(FHIR/API con la Secretaría, Gates 2 y 3 del
[roadmap](../ROADMAP_INTEROPERABILIDAD.md)), se pedirá **una nueva autorización**
que indicará **a quién** se transfiere y **para qué**:

| Posible destinatario | Finalidad prevista |
|---|---|
| Secretaría de Salud de La Guajira | Vigilancia nutricional y brigadas |
| PMA / Baylor | Articulación de apoyos alimentarios |
| Uniguajira | Análisis académico |

Usted podrá **negar** esa transferencia sin que afecte su participación en este
piloto.

---

## 9. Sus derechos

Como titular (o representante legal) usted puede, en cualquier momento y **sin
costo**:

1. **Conocer** qué datos hay del niño.
2. **Actualizar o rectificar** datos incorrectos.
3. **Pedir la supresión** de los datos.
4. **Revocar** esta autorización.
5. **Presentar quejas** ante la Superintendencia de Industria y Comercio (SIC).

Para ejercerlos: [correo y teléfono de la coordinación]. La solicitud se atiende
en los plazos de la Ley 1581.

---

## 10. Asentimiento del niño

Los niños de 6 a 59 meses **no pueden dar asentimiento** por su edad. Por eso la
autorización la da el representante legal, y el promotor explica el
procedimiento a la familia en un lenguaje sencillo (y en wayuunaiki cuando
corresponda). Si en el futuro el piloto incluyera niños mayores de 6 años, se
pedirá también su asentimiento.

---

## 11. Contacto

| Rol | Nombre | Teléfono / correo |
|---|---|---|
| Investigador principal | [ ] | [ ] |
| Coordinación del piloto | [ ] | [ ] |
| Comité de ética Uniguajira | [ ] | [ ] |
| Enlace comunitario | [ ] | [ ] |

---

## 12. Declaración y firmas

Yo, ______________________________________, identificado(a) con documento
_____________ , en calidad de **padre, madre o representante legal** del niño o
niña ______________________________________, declaro que:

- [ ] Leí o me leyeron esta información y **entendí** el objetivo, el
      procedimiento, los riesgos y los beneficios.
- [ ] Entiendo que la app usa **tablas DEMO**, que **no diagnostica** y que un
      resultado rojo se remite a salud.
- [ ] Entiendo que los datos quedan **en el teléfono** y, si se usa una cuenta
      institucional, **también se copian a Google Cloud (Firestore)**.
- [ ] Entiendo que el mensaje de alerta **incluye el nombre del niño** y se
      envía al número institucional.
- [ ] **Autorizo** la sincronización con Google Cloud (Firestore) descrita en
      §8. *(Si no autoriza, se usa la cuenta demo local y no se envía nada.)*
- [ ] Entiendo que puedo **negar o retirar** la autorización en cualquier
      momento, sin afectar la atención.
- [ ] **Autorizo** el tratamiento de los datos descrito (Ley 1581 de 2012).
- [ ] **Autorizo** la observación por parte de estudiantes, sin imágenes.
- [ ] **No autorizo** el tamizaje con la app (marque si aplica).
- [ ] **No autorizo** la sincronización con la nube (marque si aplica). En ese
      caso se registra solo en el teléfono.

| | Nombre | Documento | Firma / huella | Fecha |
|---|---|---|---|---|
| Representante legal | | | | |
| Testigo | | | | |
| Quien toma el consentimiento | | | | |

**Lugar:** ______________________ **Ranchería:** ______________

> Se entrega **una copia** al representante legal y se conserva otra en el
> archivo del proyecto.

---

## 13. Versión oral corta (para leer en voz alta)

> "Estamos probando una aplicación que mide el peso y la talla de los niños sin
> internet. Si usted acepta, medimos al niño, la app muestra un color y le
> decimos qué hacer. Si el color es rojo, avisamos hoy al puesto de salud. Los
> datos quedan en este teléfono y, si usamos la cuenta de la universidad,
> también se guardan en un servidor de Google; usted puede decir que no. Puede
> pedir que los borren cuando quiera. La app no es un diagnóstico y usa tablas
> de práctica. ¿Tiene preguntas? ¿Acepta?"

*(Traducción al wayuunaiki: ver
[`GUIA_USUARIO_WAYUUNAIKI.md`](GUIA_USUARIO_WAYUUNAIKI.md) — pendiente de
validación con hablantes nativos. No se usa esta versión oral sin esa
validación.)*

---

## 14. Control de versiones

| Versión | Fecha | Cambio | Aprobó |
|---|---|---|---|
| 0.1 | 2026-11-21 | Borrador inicial | — |
| 0.2 | 2026-11-24 | Declara la sincronización con Cloud Firestore (§5, §7, §8, §12, §13) | — |
| | | Revisión jurídica | |
| | | Aprobación comité de ética | |
