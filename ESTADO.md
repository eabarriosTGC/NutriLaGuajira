# Estado del proyecto — NutriLaGuajira

Documento de traspaso para retomar el trabajo sin reconstruir contexto.
Última actualización: **avance 1 entregado**.

---

## 1. Dónde estamos

| Dato | Valor |
|---|---|
| Repo | https://github.com/eabarriosTGC/NutriLaGuajira (público, MIT) |
| Rama | `main` |
| Último commit del avance | `b852040` (docs: guía COMO_PROBAR.md) |
| Tag / release | `v0.1.0-avance1` con `app-debug.apk` adjunto |
| Estado | **Avance 1 cerrado y verificado**: `flutter analyze` limpio, 45/45 tests, prueba en emulador con capturas |

Alcance entregado: login local, registro de infantes/tutores, evaluación
antropométrica, Z-score Peso/Talla con tabla DEMO, semáforo, SQLite offline,
historial y detalle. GPS, reportes PDF/CSV, SMS y sincronización **no** están
implementados (aparecen deshabilitados en el menú).

---

## 2. Cómo retomar

```bash
git clone https://github.com/eabarriosTGC/NutriLaGuajira.git
cd NutriLaGuajira/entrega_avance1_nutrilaguajira/nutrilaguajira

flutter pub get
flutter test        # debe dar 45/45 antes de tocar nada
flutter analyze     # debe estar limpio
dart format --output=none --set-exit-if-changed lib test tool

flutter run         # dispositivo/emulador Android
```

Para publicar una versión nueva del APK:

```bash
flutter build apk --debug
cp build/app/outputs/flutter-apk/app-debug.apk ../../app-debug.apk
gh release upload <tag> ../../app-debug.apk --clobber
```

El APK **no** se commitea (pesa ~166 MB y está en `.gitignore`): va como asset
del release.

---

## 3. Mapa del código (dónde tocar cada cosa)

```
lib/
  main.dart                 arranque, tema, locale es, pantalla de carga
  app_services.dart         localizador de dependencias + Sesion en memoria
  data/
    db_nutrilaguajira.dart  esquema, semilla, carga del CSV a SQLite
    repositorio.dart        consultas (login, infantes, evaluaciones)
    models/                 Nino, Usuario, Evaluacion, ReferenciaWho
  services/
    nutricion_service.dart  MOTOR de cálculo (puro: sin Flutter ni SQLite)
    validadores.dart        reglas de formulario (rangos, fecha, edad)
    edad.dart               meses cumplidos
    fechas.dart             formato dd/MM/yyyy (intl)
    referencias_csv.dart    parser del CSV (Dart puro)
    referencias_loader.dart acceso al asset
  screens/                  login, home, seleccion, nino_form, evaluacion_form,
                            resultado, historial, detalle, acerca_de
  theme/                    tema Material 3 + colores del semáforo
  widgets/componentes.dart  botones, chips, PanelVacio, FilaDato
test/                       45 pruebas (motor, validadores, widget, SQLite real)
tool/calcular_demo.dart     recalcula los casos semilla con el motor real
```

---

## 4. Reglas del dominio que NO se deben romper

1. **Z se clasifica con el valor redondeado a 2 decimales** (lo mismo que se
   muestra). Si se clasifica con el valor crudo, `-2.0000000000000009` cae en la
   categoría siguiente aunque en pantalla se lea `-2.00`.
2. **Edema bilateral ⇒ ROJO**, sin importar el Z.
3. **MUAC solo aplica desde los 6 meses**; en menores se ignora y se informa.
4. Si Z y MUAC discrepan, **gana el criterio más grave**.
5. La tabla de referencia es **dato, no lógica**: vive en `who_referencia_demo`
   y el motor se construye leyéndola. Reemplazarla no toca el cálculo.
6. **La semilla se calcula con el motor**, nunca con colores escritos a mano.
7. Los textos de la interfaz van **en español con tildes**.

---

## 5. Pendientes (orden propuesto para el Sprint 2)

| # | Tarea | Notas de arranque |
|---|---|---|
| 1 | **GPS y coordenadas de la ranchería** | nueva columna `lat`/`lng` en `evaluaciones` → subir `versionEsquema` a 2 y migrar en `onUpgrade`; permisos en `AndroidManifest`; pedido en runtime |
| 2 | **Reportes PDF/CSV** | generar desde `historial()`; CSV con `intl`; PDF con paquete local (evitar servicios externos); botón en detalle |
| 3 | **Alertas por SMS** | sin backend: `intent` de SMS con texto prellenado (no envío silencioso); requiere consentimiento explícito |
| 4 | **Sincronización offline-first** | `sincronizado` ya existe en el esquema (siempre 0); definir backend, resolución de conflictos y cifrado antes de mover datos de menores |
| 5 | Tablas OMS completas | reemplazar `assets/who_referencia_demo.csv` + migración que repueble la tabla; revisar Resolución 2465/2016 y 115/2026 |
| 6 | Peso/Edad y Talla/Edad | el motor hoy solo calcula Peso/Talla |
| 7 | Editar / borrar evaluaciones | hoy solo hay inserción y lectura |
| 8 | APK de distribución | hoy es *debug* (166 MB, clave de debug); para entregar de verdad, keystore + `--release` + `--split-per-abi` |

### Deudas menores conocidas

- La BD del emulador de pruebas quedó con **8 tamizajes** (4 semilla + 4 de la
  demo en vivo), incluido un registro extra de Yuliana que no está en la semilla.
  No afecta al código: es solo estado del dispositivo.
- Falta agregar al compañero como colaborador de GitHub si va a hacer commits
  (el repo es público para leer/probar, no para escribir).
- No hay cifrado local: los datos de menores están en SQLite en claro. Es
  aceptable para un prototipo académico, no para producción.

---

## 6. Cómo se verificó (repetir antes de cada entrega)

1. `flutter analyze` → sin observaciones.
2. `flutter test` → 45/45.
3. `dart format --set-exit-if-changed` → sin cambios pendientes.
4. Emulador: login → registrar infante → evaluación → semáforo → cerrar app →
   reabrir → historial intacto.
5. Clonar el repo en `/tmp` y correr `flutter test` desde el clon (confirma que
   no hay archivos que existan solo en la máquina local).

Evidencia visual en `screenshots/` (índice en `screenshots/README.md`).

---

## 7. Defectos ya corregidos (no reintroducir)

1. `ListTileThemeData.titleTextStyle` sin `color` → nombre del infante invisible.
2. Evaluación recién creada sin `ninoNombre`/`comunidad` → "Comunidad —" en el
   resultado.
3. Borde Z = −2 con error de coma flotante → clasificaba ROJO mostrando −2.00.
4. "La talla es obligatorio" → concordancia de género en validadores.
5. Date picker en inglés → `flutter_localizations` con `locale: es`.
6. Tildes faltantes en textos visibles y en la semilla.

---

## 8. Contacto y equipo

- Autor del repo: `eabarriosTGC` (LinuxeroGuajiro).
- Compañero de equipo: **pendiente** de agregar como colaborador / de registrar
  los hallazgos que reporte desde `COMO_PROBAR.md`.
