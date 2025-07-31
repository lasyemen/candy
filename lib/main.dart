import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'blocs/app_bloc.dart';
import 'core/services/app_settings.dart';
import 'screens/index.dart';
import 'core/constants/design_system.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppBloc()),
        ChangeNotifierProvider(create: (_) => AppSettings()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, appSettings, child) {
          return MaterialApp(
            title: 'تطبيق كاندي',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: appSettings.currentTheme,
            home: const MainScreen(),
            locale: Locale(appSettings.currentLanguage),
            supportedLocales: const [Locale('ar'), Locale('en'), Locale('ur')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Directionality(
                textDirection: _getTextDirection(appSettings.currentLanguage),
                child: child!,
              );
            },
            routes: {
              '/main': (context) => const MainScreen(),
              '/delivery-location': (context) => const DeliveryLocationScreen(),
              '/payment-tracking': (context) {
                final deliveryData =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                return PaymentTrackingScreen(deliveryData: deliveryData);
              },
            },
          );
        },
      ),
    );
  }

  TextDirection _getTextDirection(String language) {
    switch (language) {
      case 'ar':
        return TextDirection.rtl;
      case 'ur':
        return TextDirection.rtl;
      case 'en':
      default:
        return TextDirection.ltr;
    }
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        onPrimary: Colors.white,
        secondary: Color(0xFF0EA5E9), // Sky Blue (Water Drop)
        onSecondary: Colors.white,
        tertiary: Color(0xFF8B5CF6), // Purple Accent
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1F2937),
        background: Color(0xFFF0F9FF), // Soft Blue Background
        onBackground: Color(0xFF1F2937),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFFE5E7EB),
        outlineVariant: Color(0xFFF3F4F6),
        surfaceVariant: Color(0xFFF3F4F6),
        onSurfaceVariant: Color(0xFF6B7280),
        inverseSurface: Color(0xFF1F2937),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFF7DD3FC),
        shadow: Color(0x1A000000),
        scrim: Color(0x52000000),
        surfaceTint: Color(0xFF6B46C1), // Purple surface tint
      ),
      fontFamily: 'Rubik',
      textTheme: const TextTheme(
        displayLarge: DesignSystem.displayLarge,
        displayMedium: DesignSystem.displayMedium,
        displaySmall: DesignSystem.displaySmall,
        headlineLarge: DesignSystem.headlineLarge,
        headlineMedium: DesignSystem.headlineMedium,
        headlineSmall: DesignSystem.headlineSmall,
        titleLarge: DesignSystem.titleLarge,
        titleMedium: DesignSystem.titleMedium,
        titleSmall: DesignSystem.titleSmall,
        bodyLarge: DesignSystem.bodyLarge,
        bodyMedium: DesignSystem.bodyMedium,
        bodySmall: DesignSystem.bodySmall,
        labelLarge: DesignSystem.labelLarge,
        labelMedium: DesignSystem.labelMedium,
        labelSmall: DesignSystem.labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
          size: 24,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: DesignSystem.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: DesignSystem.primary, width: 1.5),
          foregroundColor: DesignSystem.primary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: DesignSystem.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF6B46C1),
            width: 2,
          ), // Deep Purple
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DesignSystem.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        unselectedItemColor: Color(0xFF9CA3AF),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        disabledColor: const Color(0xFFE5E7EB),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        linearTrackColor: Color(0xFFE5E7EB),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        onPrimary: Colors.white,
        secondary: Color(0xFF0EA5E9), // Sky Blue (Water Drop)
        onSecondary: Colors.white,
        tertiary: Color(0xFF8B5CF6), // Purple Accent
        onTertiary: Colors.white,
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        background: Color(0xFF0F172A),
        onBackground: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFF334155),
        outlineVariant: Color(0xFF475569),
        surfaceVariant: Color(0xFF334155),
        onSurfaceVariant: Color(0xFF94A3B8),
        inverseSurface: Colors.white,
        onInverseSurface: Color(0xFF1F2937),
        inversePrimary: Color(0xFF7DD3FC),
        shadow: Color(0x1A000000),
        scrim: Color(0x52000000),
        surfaceTint: Color(0xFF6B46C1), // Purple surface tint
      ),
      fontFamily: 'Rubik',
      textTheme: TextTheme(
        displayLarge: DesignSystem.displayLarge.copyWith(color: Colors.white),
        displayMedium: DesignSystem.displayMedium.copyWith(color: Colors.white),
        displaySmall: DesignSystem.displaySmall.copyWith(color: Colors.white),
        headlineLarge: DesignSystem.headlineLarge.copyWith(color: Colors.white),
        headlineMedium: DesignSystem.headlineMedium.copyWith(
          color: Colors.white,
        ),
        headlineSmall: DesignSystem.headlineSmall.copyWith(color: Colors.white),
        titleLarge: DesignSystem.titleLarge.copyWith(color: Colors.white),
        titleMedium: DesignSystem.titleMedium.copyWith(color: Colors.white),
        titleSmall: DesignSystem.titleSmall.copyWith(color: Colors.white),
        bodyLarge: DesignSystem.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: DesignSystem.bodyMedium.copyWith(color: Colors.white),
        bodySmall: DesignSystem.bodySmall.copyWith(
          color: const Color(0xFFCBD5E1),
        ),
        labelLarge: DesignSystem.labelLarge.copyWith(color: Colors.white),
        labelMedium: DesignSystem.labelMedium.copyWith(color: Colors.white),
        labelSmall: DesignSystem.labelSmall.copyWith(
          color: const Color(0xFFCBD5E1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: DesignSystem.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: DesignSystem.primary, width: 1.5),
          foregroundColor: DesignSystem.primary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: DesignSystem.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(0xFF6B46C1),
            width: 2,
          ), // Deep Purple
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DesignSystem.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF334155),
        selectedColor: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        disabledColor: const Color(0xFF334155),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Color(0xFF6B46C1), // Deep Purple (CANDY Brand)
        linearTrackColor: const Color(0xFF334155),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF334155),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
