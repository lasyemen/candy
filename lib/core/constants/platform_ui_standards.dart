import 'package:flutter/material.dart';
import 'dart:io';

/// Platform UI Standards - معايير واجهة المستخدم للمنصات
/// iOS and Android specific UI standards like radius, spacing, etc.
class PlatformUIStandards {
  // Platform Detection - اكتشاف المنصة
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;

  // Border Radius Standards - معايير نصف قطر الحدود

  /// Small Border Radius - نصف قطر الحدود الصغير
  static double get smallRadius => isIOS ? 8.0 : 4.0;

  /// Medium Border Radius - نصف قطر الحدود المتوسط
  static double get mediumRadius => isIOS ? 12.0 : 8.0;

  /// Large Border Radius - نصف قطر الحدود الكبير
  static double get largeRadius => isIOS ? 16.0 : 12.0;

  /// Extra Large Border Radius - نصف قطر الحدود الكبير جداً
  static double get extraLargeRadius => isIOS ? 24.0 : 16.0;

  /// Button Border Radius - نصف قطر حدود الزر
  static double get buttonRadius => isIOS ? 8.0 : 4.0;

  /// Card Border Radius - نصف قطر حدود البطاقة
  static double get cardRadius => isIOS ? 12.0 : 8.0;

  /// Dialog Border Radius - نصف قطر حدود الحوار
  static double get dialogRadius => isIOS ? 16.0 : 12.0;

  /// Bottom Sheet Border Radius - نصف قطر حدود الورقة السفلية
  static double get bottomSheetRadius => isIOS ? 20.0 : 16.0;

  // Spacing Standards - معايير المسافات

  /// Extra Small Spacing - المسافة الصغيرة جداً
  static double get spacingXS => isIOS ? 4.0 : 4.0;

  /// Small Spacing - المسافة الصغيرة
  static double get spacingS => isIOS ? 8.0 : 8.0;

  /// Medium Spacing - المسافة المتوسطة
  static double get spacingM => isIOS ? 16.0 : 16.0;

  /// Large Spacing - المسافة الكبيرة
  static double get spacingL => isIOS ? 24.0 : 24.0;

  /// Extra Large Spacing - المسافة الكبيرة جداً
  static double get spacingXL => isIOS ? 32.0 : 32.0;

  /// Double Extra Large Spacing - المسافة الكبيرة جداً مضاعفة
  static double get spacingXXL => isIOS ? 48.0 : 48.0;

  // Padding Standards - معايير الحشو

  /// Small Padding - الحشو الصغير
  static EdgeInsets get paddingS => EdgeInsets.all(spacingS);

  /// Medium Padding - الحشو المتوسط
  static EdgeInsets get paddingM => EdgeInsets.all(spacingM);

  /// Large Padding - الحشو الكبير
  static EdgeInsets get paddingL => EdgeInsets.all(spacingL);

  /// Horizontal Padding - الحشو الأفقي
  static EdgeInsets get paddingHorizontal =>
      EdgeInsets.symmetric(horizontal: spacingM);

  /// Vertical Padding - الحشو العمودي
  static EdgeInsets get paddingVertical =>
      EdgeInsets.symmetric(vertical: spacingM);

  /// Button Padding - حشو الزر
  static EdgeInsets get buttonPadding => EdgeInsets.symmetric(
    horizontal: isIOS ? 24.0 : 16.0,
    vertical: isIOS ? 12.0 : 8.0,
  );

  /// Card Padding - حشو البطاقة
  static EdgeInsets get cardPadding => EdgeInsets.all(isIOS ? 16.0 : 12.0);

  // Margin Standards - معايير الهوامش

  /// Small Margin - الهامش الصغير
  static EdgeInsets get marginS => EdgeInsets.all(spacingS);

  /// Medium Margin - الهامش المتوسط
  static EdgeInsets get marginM => EdgeInsets.all(spacingM);

  /// Large Margin - الهامش الكبير
  static EdgeInsets get marginL => EdgeInsets.all(spacingL);

  /// Horizontal Margin - الهامش الأفقي
  static EdgeInsets get marginHorizontal =>
      EdgeInsets.symmetric(horizontal: spacingM);

  /// Vertical Margin - الهامش العمودي
  static EdgeInsets get marginVertical =>
      EdgeInsets.symmetric(vertical: spacingM);

  // Icon Sizes - أحجام الأيقونات

  /// Small Icon - الأيقونة الصغيرة
  static double get iconSizeS => isIOS ? 16.0 : 16.0;

  /// Medium Icon - الأيقونة المتوسطة
  static double get iconSizeM => isIOS ? 24.0 : 24.0;

  /// Large Icon - الأيقونة الكبيرة
  static double get iconSizeL => isIOS ? 32.0 : 32.0;

  /// Extra Large Icon - الأيقونة الكبيرة جداً
  static double get iconSizeXL => isIOS ? 48.0 : 48.0;

  // Elevation Standards - معايير الارتفاع

  /// Light Elevation - الارتفاع الخفيف
  static double get elevationLight => isIOS ? 0.0 : 2.0;

  /// Medium Elevation - الارتفاع المتوسط
  static double get elevationMedium => isIOS ? 0.0 : 4.0;

  /// Heavy Elevation - الارتفاع الثقيل
  static double get elevationHeavy => isIOS ? 0.0 : 8.0;

  // Animation Durations - مدة الرسوم المتحركة

  /// Fast Animation - الرسوم المتحركة السريعة
  static Duration get animationFast =>
      Duration(milliseconds: isIOS ? 200 : 150);

  /// Medium Animation - الرسوم المتحركة المتوسطة
  static Duration get animationMedium =>
      Duration(milliseconds: isIOS ? 300 : 250);

  /// Slow Animation - الرسوم المتحركة البطيئة
  static Duration get animationSlow =>
      Duration(milliseconds: isIOS ? 500 : 400);

  // Font Sizes - أحجام الخطوط

  /// Caption Font Size - حجم خط التسمية
  static double get fontSizeCaption => isIOS ? 12.0 : 12.0;

  /// Body Font Size - حجم خط النص
  static double get fontSizeBody => isIOS ? 16.0 : 14.0;

  /// Title Font Size - حجم خط العنوان
  static double get fontSizeTitle => isIOS ? 20.0 : 18.0;

  /// Headline Font Size - حجم خط العنوان الرئيسي
  static double get fontSizeHeadline => isIOS ? 24.0 : 20.0;

  /// Display Font Size - حجم خط العرض
  static double get fontSizeDisplay => isIOS ? 32.0 : 28.0;

  // Line Heights - ارتفاعات الأسطر

  /// Compact Line Height - ارتفاع السطر المضغوط
  static double get lineHeightCompact => isIOS ? 1.2 : 1.2;

  /// Normal Line Height - ارتفاع السطر العادي
  static double get lineHeightNormal => isIOS ? 1.4 : 1.4;

  /// Relaxed Line Height - ارتفاع السطر المريح
  static double get lineHeightRelaxed => isIOS ? 1.6 : 1.6;

  // Component Heights - ارتفاعات المكونات

  /// Button Height - ارتفاع الزر
  static double get buttonHeight => isIOS ? 44.0 : 48.0;

  /// Input Field Height - ارتفاع حقل الإدخال
  static double get inputFieldHeight => isIOS ? 44.0 : 48.0;

  /// App Bar Height - ارتفاع شريط التطبيق
  static double get appBarHeight => isIOS ? 44.0 : 56.0;

  /// Bottom Navigation Height - ارتفاع التنقل السفلي
  static double get bottomNavigationHeight => isIOS ? 83.0 : 56.0;

  // Utility Methods - الطرق المساعدة

  /// Get Platform-Specific Border Radius - الحصول على نصف قطر الحدود حسب المنصة
  static BorderRadius getBorderRadius(String type) {
    switch (type.toLowerCase()) {
      case 'small':
        return BorderRadius.circular(smallRadius);
      case 'medium':
        return BorderRadius.circular(mediumRadius);
      case 'large':
        return BorderRadius.circular(largeRadius);
      case 'extraLarge':
        return BorderRadius.circular(extraLargeRadius);
      case 'button':
        return BorderRadius.circular(buttonRadius);
      case 'card':
        return BorderRadius.circular(cardRadius);
      case 'dialog':
        return BorderRadius.circular(dialogRadius);
      case 'bottomSheet':
        return BorderRadius.circular(bottomSheetRadius);
      default:
        return BorderRadius.circular(mediumRadius);
    }
  }

  /// Get Platform-Specific Spacing - الحصول على المسافة حسب المنصة
  static double getSpacing(String type) {
    switch (type.toLowerCase()) {
      case 'xs':
        return spacingXS;
      case 's':
        return spacingS;
      case 'm':
        return spacingM;
      case 'l':
        return spacingL;
      case 'xl':
        return spacingXL;
      case 'xxl':
        return spacingXXL;
      default:
        return spacingM;
    }
  }

  /// Get Platform-Specific Icon Size - الحصول على حجم الأيقونة حسب المنصة
  static double getIconSize(String type) {
    switch (type.toLowerCase()) {
      case 's':
        return iconSizeS;
      case 'm':
        return iconSizeM;
      case 'l':
        return iconSizeL;
      case 'xl':
        return iconSizeXL;
      default:
        return iconSizeM;
    }
  }

  /// Get Platform-Specific Elevation - الحصول على الارتفاع حسب المنصة
  static double getElevation(String type) {
    switch (type.toLowerCase()) {
      case 'light':
        return elevationLight;
      case 'medium':
        return elevationMedium;
      case 'heavy':
        return elevationHeavy;
      default:
        return elevationMedium;
    }
  }

  /// Get Platform-Specific Animation Duration - الحصول على مدة الرسوم المتحركة حسب المنصة
  static Duration getAnimationDuration(String type) {
    switch (type.toLowerCase()) {
      case 'fast':
        return animationFast;
      case 'medium':
        return animationMedium;
      case 'slow':
        return animationSlow;
      default:
        return animationMedium;
    }
  }

  /// Get Platform-Specific Font Size - الحصول على حجم الخط حسب المنصة
  static double getFontSize(String type) {
    switch (type.toLowerCase()) {
      case 'caption':
        return fontSizeCaption;
      case 'body':
        return fontSizeBody;
      case 'title':
        return fontSizeTitle;
      case 'headline':
        return fontSizeHeadline;
      case 'display':
        return fontSizeDisplay;
      default:
        return fontSizeBody;
    }
  }

  /// Get Platform-Specific Line Height - الحصول على ارتفاع السطر حسب المنصة
  static double getLineHeight(String type) {
    switch (type.toLowerCase()) {
      case 'compact':
        return lineHeightCompact;
      case 'normal':
        return lineHeightNormal;
      case 'relaxed':
        return lineHeightRelaxed;
      default:
        return lineHeightNormal;
    }
  }

  /// Get Platform-Specific Component Height - الحصول على ارتفاع المكون حسب المنصة
  static double getComponentHeight(String type) {
    switch (type.toLowerCase()) {
      case 'button':
        return buttonHeight;
      case 'input':
        return inputFieldHeight;
      case 'appBar':
        return appBarHeight;
      case 'bottomNav':
        return bottomNavigationHeight;
      default:
        return buttonHeight;
    }
  }
}
