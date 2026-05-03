import 'package:flutter/material.dart';

import 'dashboard_tokens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E6CF6)),
    );
    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        surfaceTintColor: base.colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outline.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
      ),
      textTheme: _textThemeNoUnderline(base.textTheme),
      extensions: const [DashboardTokens.light],
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E6CF6),
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: base.colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: base.colorScheme.surface,
        surfaceTintColor: base.colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
      ),
      textTheme: _textThemeNoUnderline(base.textTheme),
      extensions: const [DashboardTokens.dark],
    );
  }

  static TextTheme _textThemeNoUnderline(TextTheme t) {
    TextStyle? clean(TextStyle? s) =>
        s?.copyWith(decoration: TextDecoration.none, decorationThickness: 0);
    return t.copyWith(
      displayLarge: clean(t.displayLarge),
      displayMedium: clean(t.displayMedium),
      displaySmall: clean(t.displaySmall),
      headlineLarge: clean(t.headlineLarge),
      headlineMedium: clean(t.headlineMedium),
      headlineSmall: clean(t.headlineSmall),
      titleLarge: clean(t.titleLarge),
      titleMedium: clean(t.titleMedium),
      titleSmall: clean(t.titleSmall),
      bodyLarge: clean(t.bodyLarge),
      bodyMedium: clean(t.bodyMedium),
      bodySmall: clean(t.bodySmall),
      labelLarge: clean(t.labelLarge),
      labelMedium: clean(t.labelMedium),
      labelSmall: clean(t.labelSmall),
    );
  }
}
