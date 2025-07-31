import 'package:flutter/material.dart';
import 'platform_ui_standards.dart';

/// Design System - نظام التصميم
/// Standard UI components with gradient colors and platform-specific styling
class DesignSystem {
  // Brand Colors - ألوان العلامة التجارية

  /// Primary Blue - اللون الأزرق الأساسي
  static const Color primaryBlue = Color(0xFF0EA5E9);

  /// Secondary Blue - اللون الأزرق الثانوي
  static const Color secondaryBlue = Color(0xFF0284C7);

  /// Light Blue - اللون الأزرق الفاتح
  static const Color lightBlue = Color(0xFF7DD3FC);

  /// Dark Blue - اللون الأزرق الغامق
  static const Color darkBlue = Color(0xFF0369A1);

  /// Cyan - اللون السماوي
  static const Color cyan = Color(0xFF06B6D4);

  /// Bright Cyan - اللون السماوي الساطع
  static const Color brightCyan = Color(0xFF00D4FF);

  // Main Brand Gradients - التدرجات الرئيسية للعلامة التجارية

  /// Primary Gradient - التدرج الأساسي
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 179, 58, 255),

      Color.fromARGB(255, 23, 6, 212),
    ], // Purple to Blue with smooth transitions
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Secondary Gradient - التدرج الثانوي
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 23, 6, 212), // Blue
      Color.fromARGB(255, 179, 58, 255), // Purple
    ], // Blue to Purple with smooth transitions
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Accent Gradient - التدرج المميز
  static const LinearGradient accentGradient = LinearGradient(
    colors: [cyan, brightCyan, lightBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.5, 1.0],
  );

  /// Success Gradient - تدرج النجاح
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning Gradient - تدرج التحذير
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error Gradient - تدرج الخطأ
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Standard UI Colors - ألوان واجهة المستخدم القياسية

  /// Primary Color - اللون الأساسي
  static const Color primary = Color(0xFF6B46C1); // Deep Purple (CANDY Brand)

  /// Secondary Color - اللون الثانوي
  static const Color secondary = cyan;

  /// Surface Color - لون السطح
  static const Color surface = Color(0xFFFFFFFF);

  /// Background Color - لون الخلفية
  static const Color background = Color(0xFFF8FAFC);

  /// Error Color - لون الخطأ
  static const Color error = Color(0xFFEF4444);

  /// Success Color - لون النجاح
  static const Color success = Color(0xFF10B981);

  /// Warning Color - لون التحذير
  static const Color warning = Color(0xFFF59E0B);

  /// Info Color - لون المعلومات
  static const Color info = Color(0xFF0EA5E9);

  // Text Colors - ألوان النصوص

  /// Primary Text - النص الأساسي
  static const Color textPrimary = Color(0xFF1F2937);

  /// Secondary Text - النص الثانوي
  static const Color textSecondary = Color(0xFF6B7280);

  /// Tertiary Text - النص الثالثي
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Inverse Text - النص المعكوس
  static const Color textInverse = Color(0xFFFFFFFF);

  // Dark Mode Colors - ألوان الوضع المظلم

  /// Dark Surface - السطح المظلم
  static const Color darkSurface = Color(0xFF1E293B);

  /// Dark Background - الخلفية المظلمة
  static const Color darkBackground = Color(0xFF0F172A);

  /// Dark Text Primary - النص الأساسي المظلم
  static const Color darkTextPrimary = Color(0xFFF7FAFC);

  /// Dark Text Secondary - النص الثانوي المظلم
  static const Color darkTextSecondary = Color(0xFFB8C2CC);

  // Interactive Colors - ألوان التفاعل

  /// Button Primary - الزر الأساسي
  static const Color buttonPrimary = primaryBlue;

  /// Button Secondary - الزر الثانوي
  static const Color buttonSecondary = cyan;

  /// Button Disabled - الزر المعطل
  static const Color buttonDisabled = Color(0xFFD1D5DB);

  /// Link Color - لون الروابط
  static const Color link = primaryBlue;

  // Border Colors - ألوان الحدود

  /// Border Primary - الحد الأساسي
  static const Color borderPrimary = Color(0xFFE5E7EB);

  /// Border Secondary - الحد الثانوي
  static const Color borderSecondary = Color(0xFFF3F4F6);

  /// Border Focus - الحد عند التركيز
  static const Color borderFocus = primaryBlue;

  // Shadow Colors - ألوان الظلال

  /// Shadow Light - الظل الفاتح
  static const Color shadowLight = Color(0x0A000000);

  /// Shadow Medium - الظل المتوسط
  static const Color shadowMedium = Color(0x1A000000);

  /// Shadow Heavy - الظل الثقيل
  static const Color shadowHeavy = Color(0x33000000);

  // Typography - الطباعة

  /// Display Large - العرض الكبير
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display Medium - العرض المتوسط
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.25,
  );

  /// Display Small - العرض الصغير
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Headline Large - العنوان الرئيسي الكبير
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Headline Medium - العنوان الرئيسي المتوسط
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Headline Small - العنوان الرئيسي الصغير
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Title Large - العنوان الكبير
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Title Medium - العنوان المتوسط
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Title Small - العنوان الصغير
  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
  );

  /// Body Large - النص الكبير
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Body Medium - النص المتوسط
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Body Small - النص الصغير
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0.4,
  );

  /// Label Large - التسمية الكبيرة
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label Medium - التسمية المتوسطة
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Label Small - التسمية الصغيرة
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Button Styles - أنماط الأزرار

  /// Primary Button Style - نمط الزر الأساسي
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    padding: PlatformUIStandards.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('button'),
    ),
  );

  /// Secondary Button Style - نمط الزر الثانوي
  static ButtonStyle get secondaryButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: BorderSide(color: primary, width: 1.5),
    padding: PlatformUIStandards.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('button'),
    ),
  );

  /// Text Button Style - نمط زر النص
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primary,
    padding: PlatformUIStandards.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('button'),
    ),
  );

  /// Gradient Button Style - نمط الزر المتدرج
  static ButtonStyle get gradientButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    padding: PlatformUIStandards.buttonPadding,
    shape: RoundedRectangleBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('button'),
    ),
  );

  // Card Styles - أنماط البطاقات

  /// Primary Card Style - نمط البطاقة الأساسية
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: surface,
    borderRadius: PlatformUIStandards.getBorderRadius('card'),
    boxShadow: getBrandShadow('light'),
  );

  /// Gradient Card Style - نمط البطاقة المتدرجة
  static BoxDecoration get gradientCardDecoration => BoxDecoration(
    borderRadius: PlatformUIStandards.getBorderRadius('card'),
    gradient: primaryGradient,
    boxShadow: getBrandShadow('medium'),
  );

  /// Glass Card Style - نمط البطاقة الزجاجية
  static BoxDecoration get glassCardDecoration =>
      getBrandGlassDecoration(borderRadius: PlatformUIStandards.cardRadius);

  // Input Styles - أنماط الحقول

  /// Primary Input Style - نمط الحقل الأساسي
  static InputDecoration get primaryInputDecoration => InputDecoration(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: borderPrimary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: error, width: 2),
    ),
    contentPadding: PlatformUIStandards.paddingM,
  );

  /// Gradient Input Style - نمط الحقل المتدرج
  static InputDecoration get gradientInputDecoration => InputDecoration(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: borderPrimary),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: borderPrimary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: PlatformUIStandards.getBorderRadius('small'),
      borderSide: BorderSide(color: error, width: 2),
    ),
    contentPadding: PlatformUIStandards.paddingM,
  );

  // Dialog Styles - أنماط الحوارات

  /// Primary Dialog Style - نمط الحوار الأساسي
  static BoxDecoration get primaryDialogDecoration => BoxDecoration(
    color: surface,
    borderRadius: PlatformUIStandards.getBorderRadius('dialog'),
    boxShadow: getBrandShadow('heavy'),
  );

  /// Gradient Dialog Style - نمط الحوار المتدرج
  static BoxDecoration get gradientDialogDecoration => BoxDecoration(
    borderRadius: PlatformUIStandards.getBorderRadius('dialog'),
    gradient: primaryGradient,
    boxShadow: getBrandShadow('heavy'),
  );

  // Bottom Sheet Styles - أنماط الأوراق السفلية

  /// Primary Bottom Sheet Style - نمط الورقة السفلية الأساسية
  static BoxDecoration get primaryBottomSheetDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(PlatformUIStandards.bottomSheetRadius),
    ),
    boxShadow: getBrandShadow('heavy'),
  );

  /// Gradient Bottom Sheet Style - نمط الورقة السفلية المتدرجة
  static BoxDecoration get gradientBottomSheetDecoration => BoxDecoration(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(PlatformUIStandards.bottomSheetRadius),
    ),
    gradient: primaryGradient,
    boxShadow: getBrandShadow('heavy'),
  );

  // Navigation Styles - أنماط التنقل

  /// Primary Navigation Style - نمط التنقل الأساسي
  static BoxDecoration get primaryNavigationDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(PlatformUIStandards.largeRadius),
    ),
    boxShadow: getBrandShadow('medium'),
  );

  /// Gradient Navigation Style - نمط التنقل المتدرج
  static BoxDecoration get gradientNavigationDecoration => BoxDecoration(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(PlatformUIStandards.largeRadius),
    ),
    gradient: primaryGradient,
    boxShadow: getBrandShadow('medium'),
  );

  // Brand Utility Methods - طرق مساعدة للعلامة التجارية

  /// Get Brand Gradient by Type - الحصول على التدرج حسب النوع
  static LinearGradient getBrandGradient(String type) {
    switch (type.toLowerCase()) {
      case 'primary':
        return primaryGradient;
      case 'secondary':
        return secondaryGradient;
      case 'accent':
        return accentGradient;
      case 'success':
        return successGradient;
      case 'warning':
        return warningGradient;
      case 'error':
        return errorGradient;
      default:
        return primaryGradient;
    }
  }

  /// Get Brand Shadow by Type - الحصول على الظل حسب النوع
  static List<BoxShadow> getBrandShadow(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return [
          BoxShadow(
            color: shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 'medium':
        return [
          BoxShadow(
            color: shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case 'heavy':
        return [
          BoxShadow(
            color: shadowHeavy,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }

  /// Get Brand Glass Decoration - الحصول على التأثير الزجاجي
  static BoxDecoration getBrandGlassDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = 16.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surface.withOpacity(0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? borderPrimary, width: 1.0),
      boxShadow: shadows ?? getBrandShadow('medium'),
    );
  }

  /// Get Platform-Specific Colors - الحصول على ألوان خاصة بالمنصة
  static Color getPlatformColor(
    BuildContext context, {
    Color? light,
    Color? dark,
  }) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return dark ?? darkSurface;
    } else {
      return light ?? surface;
    }
  }

  /// Get Platform-Specific Text Color - الحصول على لون النص حسب المنصة
  static Color getPlatformTextColor(
    BuildContext context, {
    Color? light,
    Color? dark,
  }) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return dark ?? darkTextPrimary;
    } else {
      return light ?? textPrimary;
    }
  }

  // Utility Methods - الطرق المساعدة

  /// Get Gradient Container - الحصول على حاوية متدرجة
  static Widget getGradientContainer({
    required Widget child,
    LinearGradient? gradient,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      padding: padding ?? PlatformUIStandards.paddingM,
      decoration: BoxDecoration(
        gradient: gradient ?? primaryGradient,
        borderRadius:
            borderRadius ?? PlatformUIStandards.getBorderRadius('card'),
        boxShadow: boxShadow ?? getBrandShadow('medium'),
      ),
      child: child,
    );
  }

  /// Get Glass Container - الحصول على حاوية زجاجية
  static Widget getGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: padding ?? PlatformUIStandards.paddingM,
      decoration: getBrandGlassDecoration(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderRadius: borderRadius?.topLeft.x ?? PlatformUIStandards.cardRadius,
      ),
      child: child,
    );
  }

  /// Get Platform-Specific Container - الحصول على حاوية خاصة بالمنصة
  static Widget getPlatformContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? lightColor,
    Color? darkColor,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          padding: padding ?? PlatformUIStandards.paddingM,
          decoration: BoxDecoration(
            color: getPlatformColor(
              context,
              light: lightColor,
              dark: darkColor,
            ),
            borderRadius:
                borderRadius ?? PlatformUIStandards.getBorderRadius('card'),
          ),
          child: child,
        );
      },
    );
  }
}
