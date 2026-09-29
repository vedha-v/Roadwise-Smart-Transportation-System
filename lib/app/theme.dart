import 'package:flutter/material.dart';

// Theme settings for the whole RoadWise app.
class RoadWiseTheme {
  static const Color _roadWiseGreen = Color(0xFF5F806B);
  static const Color _roadWiseBackground = Color(0xFFF8F7F2);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _roadWiseGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _roadWiseBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _roadWiseBackground,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFF0F0F8),
        indicatorColor: _roadWiseGreen.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: _roadWiseGreen,
              );
            }

            return const IconThemeData(
              color: Color(0xFF17201B),
            );
          },
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _roadWiseGreen,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
    );
  }
}
