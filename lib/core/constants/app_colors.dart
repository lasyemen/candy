import 'package:flutter/material.dart';

class AppColors {
  // 2025 CANDY Brand Color Palette - Purple & Blue Theme
  static const Color primary = Color(0xFF6B46C1); // Deep Purple (CANDY Brand)
  static const Color primaryLight = Color(0xFF8B5CF6); // Light Purple
  static const Color primaryDark = Color(0xFF4C1D95); // Dark Purple
  static const Color primaryVibrant = Color(0xFF7C3AED); // Vibrant Purple

  // Secondary Water Colors - Blue & Cyan Theme
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue (Water Drop)
  static const Color secondaryLight = Color(0xFF7DD3FC); // Light Sky Blue
  static const Color secondaryDark = Color(0xFF0369A1); // Deep Sky Blue
  static const Color secondaryVibrant = Color(
    0xFF06B6D4,
  ); // Cyan (Water Essence)

  // Accent Colors - Mountain & Lightning Theme
  static const Color accent = Color(0xFF8B5CF6); // Purple Accent
  static const Color accentLight = Color(0xFFA78BFA); // Light Purple
  static const Color accentDark = Color(0xFF6D28D9); // Dark Purple
  static const Color accentVibrant = Color(0xFF7C3AED); // Vibrant Purple

  // 2025 Glassmorphism Colors
  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBackgroundDark = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x1A0EA5E9);
  static const Color glassBorderDark = Color(0x1AFFFFFF);
  static const Color glassShadow = Color(0x0A000000);
  static const Color glassShadowDark = Color(0x0AFFFFFF);

  // Background Colors - Soft & Calming
  static const Color background = Color(0xFFF0F9FF); // Soft Blue
  static const Color backgroundVariant = Color(0xFFE0F2FE); // Lighter Blue
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceVariant = Color(0xFFF8FAFC); // Soft White

  // Text Colors - Enhanced Contrast
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textInverse = Color(0xFFFFFFFF); // White

  // Status Colors - Meaningful & Accessible
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFF34D399); // Emerald 400
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFCD34D); // Amber 400
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFF87171); // Red 400
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFF60A5FA); // Blue 400

  // Water Tracking Colors - CANDY Water Theme
  static const Color waterBlue = Color(0xFF0EA5E9); // Sky Blue (Water Drop)
  static const Color waterLight = Color(0xFF7DD3FC); // Light Sky Blue
  static const Color waterDark = Color(0xFF0369A1); // Deep Sky Blue
  static const Color waterAccent = Color(0xFF06B6D4); // Cyan (Water Essence)
  static const Color waterVibrant = Color(0xFF00D4FF); // Bright Cyan

  // Rating Colors - CANDY Purple Theme
  static const Color rating = Color(0xFF8B5CF6); // Purple Rating
  static const Color ratingLight = Color(0xFFA78BFA); // Light Purple
  static const Color ratingVibrant = Color(0xFF7C3AED); // Vibrant Purple

  // 2025 Advanced Shadow System
  static const Color shadowLight = Color(0x0A0EA5E9);
  static const Color shadowMedium = Color(0x1A0EA5E9);
  static const Color shadowDark = Color(0x330EA5E9);
  static const Color shadowVibrant = Color(0x1A06B6D4);

  // 2025 CANDY Dynamic Gradients - Purple & Blue Theme
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVibrant, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [waterBlue, waterVibrant, waterAccent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.7, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, primaryVibrant, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentVibrant, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // 2025 Radial Gradients for Depth
  static const RadialGradient primaryRadial = RadialGradient(
    colors: [primaryLight, primary, primaryDark],
    center: Alignment.center,
    radius: 1.0,
  );

  static const RadialGradient waterRadial = RadialGradient(
    colors: [waterLight, waterBlue, waterDark],
    center: Alignment.center,
    radius: 1.0,
  );

  // 2025 Conic Gradients for Dynamic Effects
  static const SweepGradient primarySweep = SweepGradient(
    colors: [primary, primaryVibrant, secondaryVibrant, primary],
    center: Alignment.center,
    startAngle: 0.0,
    endAngle: 2 * 3.14159,
  );

  // Card Colors - Enhanced Glassmorphism
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundGlass = Color(0xCCFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardBorderGlass = Color(0x1A0EA5E9);
  static const Color cardShadow = Color(0x0A0EA5E9);

  // Button Colors - Enhanced States
  static const Color buttonPrimary = Color(0xFF0EA5E9);
  static const Color buttonPrimaryHover = Color(0xFF0284C7);
  static const Color buttonSecondary = Color(0xFF10B981);
  static const Color buttonSecondaryHover = Color(0xFF059669);
  static const Color buttonAccent = Color(0xFFF59E0B);
  static const Color buttonAccentHover = Color(0xFFD97706);
  static const Color buttonDisabled = Color(0xFFCBD5E1);

  // Input Colors - Enhanced Focus States
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBackgroundGlass = Color(0xCCFFFFFF);
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputFocus = Color(0xFF0EA5E9);
  static const Color inputFocusVibrant = Color(0xFF06B6D4);
  static const Color inputError = Color(0xFFEF4444);

  // Navigation Colors - Enhanced Selection
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navBackgroundGlass = Color(0xCCFFFFFF);
  static const Color navSelected = Color(0xFF0EA5E9);
  static const Color navSelectedVibrant = Color(0xFF06B6D4);
  static const Color navUnselected = Color(0xFF94A3B8);

  // 2025 Neumorphism Colors (Subtle)
  static const Color neumorphismLight = Color(0xFFFFFFFF);
  static const Color neumorphismDark = Color(0xFFE2E8F0);
  static const Color neumorphismShadowLight = Color(0x1A000000);
  static const Color neumorphismShadowDark = Color(0x1A000000);

  // 2025 CANDY Organic Shape Colors
  static const Color organicPrimary = Color(0xFF6B46C1); // Deep Purple
  static const Color organicSecondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color organicAccent = Color(0xFF8B5CF6); // Purple Accent

  // 2025 CANDY Micro-interaction Colors
  static const Color microInteractionSuccess = Color(0xFF10B981);
  static const Color microInteractionWarning = Color(
    0xFF8B5CF6,
  ); // Purple Warning
  static const Color microInteractionError = Color(0xFFEF4444);
  static const Color microInteractionInfo = Color(0xFF0EA5E9); // Blue Info

  // 2025 Accessibility Colors (High Contrast)
  static const Color accessibilityHighContrast = Color(0xFF000000);
  static const Color accessibilityLowContrast = Color(0xFF6B7280);
  static const Color accessibilityFocus = Color(0xFF06B6D4);

  // 2025 Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);

  // 2025 CANDY Animation Colors
  static const Color animationPrimary = Color(0xFF6B46C1); // Deep Purple
  static const Color animationSecondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color animationAccent = Color(0xFF8B5CF6); // Purple Accent
  static const Color animationSuccess = Color(0xFF10B981);
  static const Color animationError = Color(0xFFEF4444);
}
