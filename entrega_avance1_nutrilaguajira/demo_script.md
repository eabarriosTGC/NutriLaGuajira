# Guion de exposición — 3 minutos

**Avance 1: Tamizaje rápido y semáforo nutricional offline**

Antes de empezar: tener la app ya instalada y con la base sembrada
(si es la primera vez que se abre, la semilla se crea sola).
Duración objetivo: 2:50. Ensayar una vez con cronómetro.

---

## 0:00 – 0:20 · Presentación y problema

> "Este es NutriLaGuajira, el avance 1 del proyecto: una aplicación móvil que
> funciona **sin internet** para hacer tamizaje nutricional rápido en
> comunidades rurales dispersas de La Guajira.
> El problema es concreto: en rancherías sin señal, el promotor de salud no
> tiene forma de calcular el estado nutricional de un niño en el momento de la
> visita. Esta app lo resuelve con una base de datos local en el teléfono."

Mostrar: pantalla de login.
Señalar el pie de pantalla: *"Funciona sin internet · datos en el dispositivo"*.

**Frase de evidencia:** "El teléfono está en modo avión" (si se puede mostrar).

---

## 0:20 – 0:35 · Login local

1. Tocar **"Usar credenciales demo"** (rellena `promotor` / `demo123`).
2. Tocar **"Ingresar"**.

> "El login es local: las credenciales están en una tabla SQLite del
> dispositivo. No hay servidor, no hay red. La sesión vive en memoria."

---

## 0:35 – 0:55 · Menú principal

> "El menú tiene las tres funciones de este avance: nuevo tamizaje, historial y
> acerca de. Arriba se ven los contadores reales: 3 infantes y 4 tamizajes que
> ya están guardados en el teléfono."

Señalar los chips grises:

> "GPS, reportes y SMS aparecen **bloqueados** a propósito: son del próximo
> sprint. Preferimos mostrar honestamente lo que no está implementado antes que
> simularlo."

---

## 0:55 – 1:30 · Nuevo tamizaje (el flujo completo)

1. Tocar **"Nuevo tamizaje"**.
2. Tocar **"Registrar nuevo infante"**.
3. Llenar rápido:
   - Nombres: `Ana Lucía`
   - Apellidos: `Epieyú Pushaina`
   - Documento: `TI-2024`
   - Fecha de nacimiento: elegir una fecha de hace **~18 meses**
     (en el selector, retroceder 1 año y medio)
   - Sexo: **Femenino**
   - Tutor: `Rosa Pushaina`
   - Comunidad / ranchería: `Ranchería Monte Verde`
4. Tocar **"Guardar infante"**.

> "La edad se calcula automáticamente desde la fecha de nacimiento. No se
> escribe: se deriva."

5. En el formulario de evaluación, escribir:
   - Peso: `8,7` (con coma, para mostrar que acepta coma decimal)
   - Talla: `80`
   - MUAC: `12,2`
   - Edema bilateral: **dejar en No**
6. Señalar la tarjeta de fecha:

> "La fecha y hora no se piden: se toman del dispositivo al guardar, porque el
> registro es offline."

---

## 1:30 – 2:00 · El semáforo (momento clave)

7. Tocar **"Calcular semáforo y guardar"**.

> "Amarillo. El motor calculó: con 80 cm y sexo femenino, la mediana de la tabla
> es 9.90 kg y la desviación estándar 1.00 kg. Este niño pesa 8.70, así que el
> Z es −1.20. Ese valor cae entre −2 y −1: riesgo de desnutrición, amarillo."

8. Abrir **"Cómo se calculó"** (desplegable).

> "La app no da un color, da la trazabilidad: qué mediana y qué DE usó, si el
> valor vino exacto de la tabla o fue interpolado, y qué aportó el MUAC."

9. Señalar la línea verde: **"Guardado localmente · fecha y hora"**.

---

## 2:00 – 2:20 · El caso que más importa: edema

10. Tocar **"Nuevo tamizaje"** → elegir **"Andres David Jusayu Gonzalez"**.
11. Escribir: Peso `12`, Talla `86`, MUAC `12,4`, y activar **Edema bilateral**.
12. Tocar **"Calcular semáforo y guardar"**.

> "Acá está el detalle clínico importante: este niño tiene un Z de **+0.43**,
> o sea, estaría verde. Pero tiene edema bilateral, y el edema es un criterio
> de gravedad **independiente del Z**: la app lo fuerza a ROJO. Un tamizaje que
> solo mirara el peso lo habría dejado pasar."

---

## 2:20 – 2:45 · Historial y persistencia

13. Tocar **"Ver historial"**.

> "El historial ordena por fecha descendente, con el nombre del infante, la
> comunidad y el chip de color. Se ve el mismo niño con dos tamizajes: uno rojo
> por Z y otro rojo por edema."

14. Tocar una evaluación para el detalle (medidas, criterios, recomendación).
15. **Cerrar la app por completo** (recientes → deslizar) y **volver a abrirla**.

> "Cierro la app entera. La vuelvo a abrir: el historial sigue ahí. Los datos
> están en SQLite, en el teléfono, no en la nube."

---

## 2:45 – 3:00 · Cierre con el disclaimer

16. Ir a **"Acerca de"**.

> "Para cerrar, el límite del avance: la tabla de referencia está en **modo
> demostración**. No es validación clínica. La versión final va con las tablas
> OMS completas y la Resolución 2465 de 2016 / 115 de 2026. Este prototipo
> **no sustituye el diagnóstico médico**: calcula, clasifica y guarda, pero
> deriva al profesional."

> "En el próximo sprint: GPS, reportes georreferenciados y alertas por SMS."

---

## Preguntas previsibles (y respuesta corta)

| Pregunta | Respuesta |
|---|---|
| ¿Y si el niño tiene 6 meses o menos? | El MUAC se ignora: la app lo dice en el criterio y clasifica solo por Z. |
| ¿Qué pasa si el Z y el MUAC no coinciden? | Se conserva el criterio **más grave**, por seguridad. |
| ¿La tabla es la de la OMS? | No. Es una tabla de demostración de 28 filas, marcada DEMO en el archivo y en la app. Se reemplaza por el CSV completo sin tocar el motor. |
| ¿Qué pasa si no hay internet? | Nada: no hay ninguna llamada de red. Todo es SQLite local. |
| ¿Se pierden los datos si cierro la app? | No. Está demostrado en la prueba manual y en `db_persistencia_test.dart`. |
| ¿Por qué hay 4 evaluaciones si hay 3 infantes? | Para mostrar que un mismo infante acumula historial (dos tamizajes del tercer niño). |
| ¿Cómo protegen los datos de menores? | Todo queda en el dispositivo. La sincronización futura requerirá consentimiento y medidas de protección. |

---

## Checklist de último minuto (5 minutos antes de exponer)

- [ ] App instalada con la base sembrada (3 infantes, 4 tamizajes).
- [ ] Batería del teléfono > 50 % y pantalla con brillo alto.
- [ ] Modo avión activo (para demostrar el offline).
- [ ] Tener a mano los valores a escribir: `8,7 / 80 / 12,2` y `12 / 86 / 12,4`.
- [ ] Saber cerrar la app de verdad (no solo volver al inicio).
- [ ] Si el proyector falla: mostrar `screenshots/` en el portátil.
