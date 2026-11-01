import 'package:flutter/material.dart';

/// Tema Material 3 de NutriLaGuajira.
///
/// Decision de diseño: se prefirio un tema claro por defecto porque la app se
/// usa en campo, muchas veces a plena luz del dia; el tema oscuro queda
/// disponible si el sistema lo pide. Se usa alto contraste y textos grandes
/// para favorecer la legibilidad de promotores y familias.
ThemeData construirTema(Brightness brillo) {
  final esquema = ColorScheme.fromSeed(
    seedColor: const Color(0xFF00695C),
    brightness: brillo,
    contrastLevel: 0.6,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    brightness: brillo,
    scaffoldBackgroundColor: brillo == Brightness.light
        ? const Color(0xFFF6F8F7)
        : null,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: esquema.primary,
      foregroundColor: esquema.onPrimary,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: esquema.onPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brillo == Brightness.light ? Colors.white : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: esquema.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: esquema.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      // El color debe declararse explicitamente: un titleTextStyle sin color
      // deja el texto con el color por defecto (casi blanco) y el nombre del
      // infante se vuelve ilegible sobre la tarjeta clara.
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: esquema.onSurface,
      ),
    ),
  );
}
