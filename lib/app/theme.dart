import 'package:flutter/material.dart';

class RoadWiseTheme {
  static const Color _navy = Color(0xFF0B1732);
  static const Color _navySurface = Color(0xFF10213C);
  static const Color _navyRaised = Color(0xFF172B49);
  static const Color _orange = Color(0xFFFFA352);
  static const Color _orangeLight = Color(0xFFFFC38C);
  static const Color _textSecondary = Color(0xFFCCE9F1);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _orange,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFFB95C18),
      secondary: const Color(0xFF8D4B19),
      surface: const Color(0xFFFFFBF7),
    );
    return _buildTheme(scheme, isDark: false);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _orange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _orange,
      onPrimary: _navy,
      secondary: _orangeLight,
      onSecondary: _navy,
      surface: _navy,
      onSurface: Colors.white,
      onSurfaceVariant: _textSecondary,
      surfaceContainerLowest: const Color(0xFF09142B),
      surfaceContainerLow: _navySurface,
      surfaceContainer: _navyRaised,
      surfaceContainerHigh: const Color(0xFF1D3658),
      surfaceContainerHighest: const Color(0xFF244166),
    );
    return _buildTheme(scheme, isDark: true);
  }

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    required bool isDark,
  }) {
    final background = isDark ? _navy : const Color(0xFFFFF8F1);
    final surface = isDark ? _navySurface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE8D7C7);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _navyRaised : const Color(0xFFFFF1E5),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.primary,
        suffixIconColor: scheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.65)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _navyRaised : const Color(0xFFFFF1E5),
        selectedColor: scheme.primary.withValues(alpha: isDark ? 0.28 : 0.18),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: scheme.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: isDark ? _navySurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      dividerColor: borderColor,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _navyRaised : const Color(0xFF34271F),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
