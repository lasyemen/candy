import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'blocs/app_bloc.dart';
import 'core/services/app_settings.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
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

  // Start the app immediately to avoid blocking on long initializations.
  runApp(const MyApp());

  // Run initialization tasks in the background so the UI shows immediately.
  (() async {
    try {
      await SupabaseService.instance.initialize();
      print('background init: Supabase initialized');
    } catch (e) {
      print('background init: Supabase failed: $e');
    }

    try {
      // Initialize Firebase Messaging and local notifications (fire-and-forget)
      NotificationService.instance.init();
      print('background init: NotificationService started');
    } catch (e) {
      print('background init: NotificationService failed: $e');
    }

    try {
      await CartService.initializeCartSession();
      print('background init: Cart session initialized');
    } catch (e) {
      print('background init: Cart session failed: $e');
    }

    try {
      await AutoTranslator.instance.initialize();
      print('background init: AutoTranslator initialized');
    } catch (e) {
      print('background init: AutoTranslator failed: $e');
    }

    try {
      await CustomerSession.instance.loadGuestUser();
      await CustomerSession.instance.loadCurrentCustomer();
      print('background init: Customer session restored');
    } catch (e) {
      print('background init: Customer session failed: $e');
    }
  })();
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
