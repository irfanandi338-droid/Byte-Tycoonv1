import 'package:flutter/material.dart';

/// Dark futuristic technology theme. Premium, clean, minimal glow.
class AppTheme {
  static const Color background = Color(0xFF080B12);
  static const Color panel = Color(0xFF111827);
  static const Color panelLight = Color(0xFF1B2536);
  static const Color border = Color(0xFF26314A);
  static const Color red = Color(0xFFE53935);
  static const Color gold = Color(0xFFFDD835);
  static const Color blue = Color(0xFF1E88E5);
  static const Color purple = Color(0xFF8E24AA);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color textPrimary = Color(0xFFE8EEF7);
  static const Color textSecondary = Color(0xFF8A97AC);
  static const Color green = Color(0xFF43A047);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
      surface: panel,
    );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: scheme.copyWith(
        surface: panel,
        primary: cyan,
        secondary: purple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: cyan.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: textSecondary),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? cyan : textSecondary, size: 22);
        }),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: panelLight,
        contentTextStyle: TextStyle(color: textPrimary),
      ),
      dividerColor: border,
      fontFamily: 'Roboto',
    );
  }

  static BoxDecoration panelDecoration({Color? accent}) => BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent ?? border),
      );
}
