# NutriLaGuajira

Plataforma móvil **offline-first** para el control y la alerta temprana de
desnutrición infantil en comunidades rurales dispersas de La Guajira, Colombia.

Proyecto académico — Escuela de Ingeniería de Sistemas. Metodología Scrum
(3 sprints).

## Avance 1 (entregado)

> **NutriLaGuajira – Avance 1: Tamizaje rápido y semáforo nutricional offline**

Prototipo funcional en **Flutter + SQLite** que permite iniciar sesión
localmente, registrar infantes y tutores, capturar peso/talla/MUAC/edema,
calcular el Z-score Peso/Talla con una tabla de referencia **DEMO**, mostrar un
semáforo (verde / amarillo / rojo), guardar todo en el dispositivo y consultar
el historial. Funciona 100 % sin internet.

GPS, reportes PDF/CSV, SMS y sincronización quedan para el próximo sprint y
aparecen deshabilitados en la interfaz.

### Entregables

Todo está en la carpeta [`entrega_avance1_nutrilaguajira/`](entrega_avance1_nutrilaguajira):

- `README.md` — descripción, requisitos, cómo ejecutar, cálculo y limitaciones
- `informe_avance1.md` — informe del avance
- `demo_script.md` — guion de exposición de 3 minutos
- `screenshots/` — capturas de la app funcionando
- `assets/who_referencia_demo.csv` — tabla de referencia DEMO
- `nutrilaguajira/` — proyecto Flutter completo
- `app-debug.apk` — APK de depuración (también adjunto en la sección *Releases*)

### Probar el APK (para el equipo)

Guía paso a paso en **[`COMO_PROBAR.md`](COMO_PROBAR.md)**: instalación,
credenciales, los valores exactos de cada caso (verde / amarillo / rojo),
validaciones, prueba de persistencia y plantilla para reportar hallazgos.

Descarga directa del APK:
<https://github.com/eabarriosTGC/NutriLaGuajira/releases/download/v0.1.0-avance1/app-debug.apk>

Requiere **Android 7.0 (API 24) o superior**. Es un APK universal de 166 MB
(incluye arm64, armv7 y x86_64), firmado con la clave de *debug*: si Play
Protect avisa, es esperado → "Instalar de todas formas".

### Inicio rápido

```bash
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter pub get
flutter test      # 45 pruebas automatizadas
flutter run       # con un dispositivo o emulador Android conectado
```

Credenciales demo: usuario `promotor`, contraseña `demo123`.

### Aviso

Prototipo académico. **No sustituye diagnóstico médico.** Las tablas de
referencia están en modo demostración; la validación clínica final usará las
tablas OMS completas y la Resolución 2465 de 2016 / Resolución 115 de 2026.

Licencia: MIT.
