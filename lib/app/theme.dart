import 'package:flutter/material.dart';


//to maintain the theme of the whole app
class RoadWiseTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    );
  }
}