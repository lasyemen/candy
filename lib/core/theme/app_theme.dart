import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Rubik',
    primarySwatch: Colors.purple,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Rubik'),
      bodyMedium: TextStyle(fontFamily: 'Rubik'),
      bodySmall: TextStyle(fontFamily: 'Rubik'),
      titleLarge: TextStyle(fontFamily: 'Rubik'),
      titleMedium: TextStyle(fontFamily: 'Rubik'),
      titleSmall: TextStyle(fontFamily: 'Rubik'),
      labelLarge: TextStyle(fontFamily: 'Rubik'),
      labelMedium: TextStyle(fontFamily: 'Rubik'),
      labelSmall: TextStyle(fontFamily: 'Rubik'),
    ),
  );

  static ThemeData get dark {
    const background = Colors.black; // pitch black
    const surface = Colors.black; // pitch black surfaces
    const onSurface = Colors.white70;

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Rubik',
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B46C1),
        secondary: Color(0xFF3B82F6),
        background: background,
        surface: surface,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(color: surface, elevation: 0),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: surface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: surface,
        titleTextStyle: TextStyle(
          fontFamily: 'Rubik',
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Rubik',
          color: onSurface,
          fontSize: 14,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        bodyMedium: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        bodySmall: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        titleLarge: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        titleMedium: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        titleSmall: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        labelLarge: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        labelMedium: TextStyle(fontFamily: 'Rubik', color: Colors.white),
        labelSmall: TextStyle(fontFamily: 'Rubik', color: Colors.white),
      ),
    );
  }
}
