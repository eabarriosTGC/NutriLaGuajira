# Evidencias de ejecución — Sprint 2 (georreferenciación GPS)

Documento de apoyo para la sección **6.2 Evidencias de ejecución** del plan de
trabajo. Las capturas están en
[`screenshots/sprint2_gps/`](screenshots/sprint2_gps/README.md).

Todas las capturas se tomaron con el **APK instalado y ejecutándose** en un
emulador Android (1080 × 2400, Android 16 / API 36), en **modo avión**. La
posición GPS se simuló con `adb emu geo fix` (11.24712, -72.98765); en un equipo
real se toma del GPS del dispositivo.

| Objetivo | % Cumplimiento | Evidencia (capturas) | Observación |
|---|---|---|---|
| **Objetivo General:** plataforma móvil offline-first con cálculo antropométrico automatizado y reportes georreferenciados. | 70 % | APK funcional en emulador; repositorio GitHub con el código; capturas [`02`](screenshots/sprint2_gps/02_menu.png), [`07`](screenshots/sprint2_gps/07_resultado_gps.png), [`09`](screenshots/sprint2_gps/09_detalle_gps.png). | La app funciona offline y guarda en SQLite. Pendiente: validación en campo (conectividad y luminosidad reales) y reportes PDF/CSV. |
| **Objetivo Específico 1:** interfaz de usuario y algoritmos de cálculo antropométrico. | 90 % | [`04`](screenshots/sprint2_gps/04_evaluacion_formulario.png), [`05`](screenshots/sprint2_gps/05_evaluacion_sin_gps.png), [`07`](screenshots/sprint2_gps/07_resultado_gps.png), [`09`](screenshots/sprint2_gps/09_detalle_gps.png); pruebas en `test/nutricion_service_test.dart` y `test/evaluacion_form_widget_test.dart`. | Formulario, semaforización y trazabilidad del Z-score verificadas con casos teóricos. Pendiente: mediciones reales de promotores. |
| **Objetivo Específico 2:** arquitectura de persistencia local (SQLite). | 100 % | [`02`](screenshots/sprint2_gps/02_menu.png) (contador 5 tamizajes), [`08`](screenshots/sprint2_gps/08_historial.png); pruebas en `test/db_persistencia_test.dart` (incluye migración v1→v2 y persistencia tras cerrar/reabrir). | Completado. La base almacena infantes, tamizajes y **coordenadas GPS** de forma local. |
| **Objetivo Específico 3:** módulo de georreferenciación GPS y reportes. | 60 % | [`04`](screenshots/sprint2_gps/04_evaluacion_formulario.png), [`05`](screenshots/sprint2_gps/05_evaluacion_sin_gps.png), [`06`](screenshots/sprint2_gps/06_evaluacion_gps_capturado.png), [`07`](screenshots/sprint2_gps/07_resultado_gps.png), [`09`](screenshots/sprint2_gps/09_detalle_gps.png). | **Captura de GPS integrada, guardada y mostrada** en resultado y detalle. Pendiente: exportación **PDF/CSV** y envío diferido de **SMS** al recuperar señal. |

## Qué demuestra cada bloque

1. **Captura de coordenadas** (`04`→`05`→`06`): el formulario incluye la tarjeta
   "Ubicación de la ranchería"; al pulsar "Obtener ubicación" pasa de
   *"Sin coordenadas"* a *"Latitud 11.24712 · Longitud -72.98765"*.
2. **Persistencia** (`06`→`07`→`08`): al guardar, el tamizaje aparece en el
   historial y el contador del menú sube a 5.
3. **Visualización** (`07` y `09`): la ubicación queda registrada y se muestra
   en el resultado y en el detalle del tamizaje.
4. **Alcance declarado** (`02` y `10`): los módulos no implementados (PDF/CSV,
   SMS, sincronización) se muestran como "próximo sprint".

## Cómo reproducir

```bash
# 1) Compilar e instalar (emulador x86_64)
cd entrega_avance1_nutrilaguajira/nutrilaguajira
flutter build apk --debug --target-platform android-x64
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 2) Conceder ubicación y fijar una posición simulada
adb shell pm grant co.edu.uniguajira.nutrilaguajira android.permission.ACCESS_FINE_LOCATION
adb shell pm grant co.edu.uniguajira.nutrilaguajira android.permission.ACCESS_COARSE_LOCATION
adb emu geo fix -72.98765 11.24712

# 3) Abrir la app y, en el formulario de evaluación, pulsar "Obtener ubicación"
adb shell am start -n co.edu.uniguajira.nutrilaguajira/.MainActivity
```

> Las capturas se generaron con `adb exec-out screencap -p` mientras la app
> estaba en ejecución (no son mockups ni renders).
