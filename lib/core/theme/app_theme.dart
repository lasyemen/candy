import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightFor(String language) => ThemeData(
    brightness: Brightness.light,
    fontFamily: language == 'en' ? 'Inter' : 'Rubik',
    primarySwatch: Colors.purple,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontSize: 18,
        fontWeight: language == 'ar' ? FontWeight.w900 : FontWeight.bold,
        color: Colors.black87,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      titleMedium: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      titleSmall: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      labelLarge: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      labelMedium: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
      labelSmall: TextStyle(
        fontFamily: language == 'en' ? 'Inter' : 'Rubik',
        fontWeight: language == 'ar' ? FontWeight.w900 : null,
        color: Colors.black87,
      ),
    ),
  );

  static ThemeData darkFor(String language) {
    const background = Colors.black; // pitch black
    const surface = Colors.black; // pitch black surfaces
    const onSurface = Colors.white70;

    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: language == 'en' ? 'Inter' : 'Rubik',
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
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontSize: 18,
          fontWeight: language == 'ar' ? FontWeight.w900 : FontWeight.bold,
          color: Colors.white,
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(color: surface, elevation: 0),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: surface,
        titleTextStyle: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 18,
          fontWeight: language == 'ar' ? FontWeight.w900 : FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w900 : null,
          color: onSurface,
          fontSize: 14,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w700 : null,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w700 : null,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w700 : null,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w900 : null,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w900 : null,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w900 : null,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w800 : null,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w800 : null,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontFamily: language == 'en' ? 'Inter' : 'Rubik',
          fontWeight: language == 'ar' ? FontWeight.w800 : null,
          color: Colors.white,
        ),
      ),
    );
  }
}
