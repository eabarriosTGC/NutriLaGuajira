# Capturas de pantalla — Avance 1

Todas las capturas se tomaron con la app instalada en un emulador Android
(Pixel, 1080 x 2400 px, Android 16 / API 36) en **modo avión**: sin ninguna
conexión de red.

Estado de la base al momento de las capturas: **4 infantes** (3 semilla +
1 registrado en vivo durante la demo) y **8 tamizajes** (4 semilla + 4
registrados en vivo).

| Archivo | Qué muestra |
|---|---|
| `01_login.png` | Pantalla de login local vacía, con el aviso "Funciona sin internet". |
| `01b_login_credenciales.png` | Login con las credenciales demo cargadas (`promotor` / `demo123`). |
| `02_menu.png` | Menú principal con contadores (4 infantes / 8 tamizajes) y los chips bloqueados de "próximo sprint". |
| `03_seleccion_infante.png` | Selección del infante a tamizar (lista semilla de 3 infantes). |
| `04_registro_infante.png` | Formulario de registro de infante completo, con la edad calculada (17 meses). |
| `05_evaluacion_llena.png` | Formulario de evaluación con peso, talla y MUAC (acepta coma decimal) y la fecha/hora automática. |
| `05b_evaluacion_edema.png` | Evaluación con el interruptor de **edema bilateral** activado. |
| `06_resultado_amarillo.png` | Resultado **AMARILLO**: Z = −1.20, recomendación y "Guardado localmente". |
| `07_resultado_verde.png` | Resultado **VERDE**: Z = +0.32. |
| `08_resultado_rojo_edema.png` | Resultado **ROJO** con Z = +0.43 y edema: prueba de que el edema fuerza ROJO. |
| `09_historial.png` | Historial ordenado por fecha descendente, con barra y chip de color. |
| `10_detalle_evaluacion.png` | Detalle con la trazabilidad del cálculo (mediana 11.52, DE 1.12, interpolado, Z, MUAC, edema). |
| `11_acerca_de.png` | Pantalla "Acerca de" con el aviso académico y las limitaciones. |
| `12_login_tras_cierre.png` | Login tras cerrar la app por completo (prueba de persistencia). |
| `13_historial_tras_reinicio.png` | Las **8 evaluaciones siguen ahí** después de cerrar y reabrir la app. |

## Notas para la exposición

- El par `12` / `13` es la evidencia de persistencia: la app se cerró con
  `force-stop` (no solo se minimizó) y al reabrir el historial está intacto.
- En `09` y `13` aparecen varios tamizajes del mismo infante: es el
  comportamiento esperado (un infante acumula historial de visitas).
- La fila "Yuliana Andrea · Z 0.63 · VERDE" corresponde a un tamizaje real
  hecho durante las pruebas manuales; no forma parte de los datos semilla.
