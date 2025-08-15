import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'blocs/app_bloc.dart';
import 'core/services/app_settings.dart';
import 'core/services/supabase_service.dart';
import 'core/services/cart_service.dart';
import 'core/services/customer_session.dart';
import 'screens/index.dart';
import 'core/routes/index.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auto_translator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase
  await SupabaseService.instance.initialize();

  // Initialize cart session
  await CartService.initializeCartSession();

  // Initialize auto translator cache
  await AutoTranslator.instance.initialize();

  // Load guest user data if available
  await CustomerSession.instance.loadGuestUser();
  // Restore logged-in customer if present
  await CustomerSession.instance.loadCurrentCustomer();

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
            title: 'Candy App',
            home: const SplashScreen(),
            locale: Locale(appSettings.currentLanguage),
            supportedLocales: const [Locale('ar'), Locale('en'), Locale('ur')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightFor(appSettings.currentLanguage),
            darkTheme: AppTheme.darkFor(appSettings.currentLanguage),
            themeMode: appSettings.currentTheme,
            builder: (context, child) {
              final defaultStyle = const TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w700,
              );
              return DefaultTextStyle.merge(
                style: defaultStyle,
                child: Directionality(
                  textDirection: _getTextDirection(appSettings.currentLanguage),
                  child: child!,
                ),
              );
            },
            routes: AppRoutes.getRoutes(),
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
}
