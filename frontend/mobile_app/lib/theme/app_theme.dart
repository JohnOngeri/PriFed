import 'package:flutter/material.dart';

class AppTheme {
  // Futuristic Cyber Defense Color Palette - Based on Reference Images
  // Primary Glowing Colors - Electric Blue/Cyan
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color primaryCyan = Color(0xFF00D9FF);
  static const Color cyberCyan = Color(0xFF00E5FF); // Bright glowing cyan from images
  static const Color electricBlue = Color(0xFF2196F3);
  static const Color glowingBlue = Color(0xFF00B8FF); // Bright wireframe blue
  
  // Accent Colors - Vibrant & Energetic
  static const Color neonPink = Color(0xFFFF006E);
  static const Color neonMagenta = Color(0xFFFF00FF); // Bright magenta from network image
  static const Color privacyPurple = Color(0xFF8B5CF6);
  static const Color plasmaOrange = Color(0xFFFF6B35);
  static const Color neuralGreen = Color(0xFF00F5A0);
  static const Color dangerRed = Color(0xFFFF3B5C);
  static const Color particleGold = Color(0xFFFFD93D);
  static const Color warningAmber = Color(0xFFFFB800);
  
  // Background Colors - Deep Navy/Black (from images)
  static const Color deepNavy = Color(0xFF0A0F1E); // Deep navy from images
  static const Color darkerNavy = Color(0xFF050810); // Even darker for depth
  static const Color spaceBlack = Color(0xFF000000);
  static const Color glowWhite = Color(0xFFFFFFFF);
  
  // Surface Colors - Dark with blue tints
  static const Color surfaceDark = Color(0xFF0F1525); // Darker with blue tint
  static const Color surfaceMedium = Color(0xFF1A1F2E);
  static const Color surfaceLight = Color(0xFF252A3A);
  
  // Wireframe/Glow Colors
  static const Color wireframeBlue = Color(0xFF00E5FF); // Bright wireframe color
  static const Color wireframeCyan = Color(0xFF00D9FF);
  static const Color particleGlowColor = Color(0xFF00B8FF);
  
  // Legacy colors for compatibility
  static const Color primaryPurple = privacyPurple;
  static const Color accentGreen = neuralGreen;
  static const Color accentGold = particleGold;
  
  // Futuristic Gradients - Glowing & Cyber
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyberCyan, electricBlue, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient cyberGradient = LinearGradient(
    colors: [cyberCyan, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient holographicGradient = LinearGradient(
    colors: [cyberCyan, privacyPurple, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient energyFlowGradient = LinearGradient(
    colors: [cyberCyan, electricBlue, neonMagenta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Particle Trail Gradient (from images)
  static const LinearGradient particleTrailGradient = LinearGradient(
    colors: [cyberCyan, wireframeBlue, Colors.transparent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Network Connection Gradient
  static const LinearGradient networkGradient = LinearGradient(
    colors: [cyberCyan, neonMagenta, cyberCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [neuralGreen, Color(0xFF00D4AA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [dangerRed, plasmaOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glowing Radial Gradients
  static const RadialGradient particleGradient = RadialGradient(
    colors: [glowWhite, cyberCyan, Colors.transparent],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const RadialGradient wireframeGlow = RadialGradient(
    colors: [cyberCyan, wireframeBlue, Colors.transparent],
    stops: [0.0, 0.4, 1.0],
  );
  
  static const LinearGradient shieldGradient = LinearGradient(
    colors: [electricBlue, privacyPurple],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [particleGold, plasmaOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Glassmorphism Gradients with Blue Tint
  static LinearGradient glassGradient = LinearGradient(
    colors: [
      cyberCyan.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark Background Gradient (from images)
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [darkerNavy, deepNavy, surfaceDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Modern Dark Theme - 2024 Design System
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryCyan,
      secondary: privacyPurple,
      tertiary: neonPink,
      surface: surfaceDark,
      background: deepNavy,
      error: dangerRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      surfaceVariant: surfaceMedium,
      onSurfaceVariant: Colors.white70,
    ),
    scaffoldBackgroundColor: deepNavy,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: surfaceDark.withOpacity(0.6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryCyan,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryCyan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.22,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.33,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white60,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white60,
        letterSpacing: 0.5,
        height: 1.27,
      ),
    ),
  );

  // Light Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryPurple,
      surface: Colors.white,
      background: Color(0xFFF8FAFC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1E293B),
      onBackground: Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Color(0xFF1E293B),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  // Accessibility - High Contrast Theme
  static ThemeData get highContrastTheme => darkTheme.copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FFFF), // Bright cyan
      secondary: Color(0xFFFF00FF), // Bright magenta
      surface: Colors.black,
      background: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    cardTheme: CardTheme(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
    ),
  );

  // Animation Durations
  static const Duration microAnimation = Duration(milliseconds: 150);
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration cinematicAnimation = Duration(milliseconds: 800);
  static const Duration globeRotation = Duration(seconds: 60);
  static const Duration particleDrift = Duration(seconds: 3);
  static const Duration energyPulse = Duration(milliseconds: 2000);

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Modern Shadows - Depth & Glow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: cyberCyan.withOpacity(0.6),
      blurRadius: 30,
      spreadRadius: 6,
    ),
    BoxShadow(
      color: cyberCyan.withOpacity(0.4),
      blurRadius: 20,
      spreadRadius: 3,
    ),
    BoxShadow(
      color: cyberCyan.withOpacity(0.2),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];
  
  static List<BoxShadow> get softGlow => [
    BoxShadow(
      color: cyberCyan.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 3,
    ),
  ];
  
  // Wireframe Glow (from padlock image)
  static List<BoxShadow> get wireframeGlowShadows => [
    BoxShadow(
      color: wireframeBlue.withOpacity(0.8),
      blurRadius: 24,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: wireframeBlue.withOpacity(0.5),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
  
  // Particle Glow
  static List<BoxShadow> get particleGlowShadows => [
    BoxShadow(
      color: particleGlowColor.withOpacity(0.9),
      blurRadius: 12,
      spreadRadius: 3,
    ),
  ];
  
  static List<BoxShadow> get innerGlow => [
    BoxShadow(
      color: Colors.white.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];
  
  // High Contrast Colors
  static const Color highContrastCyan = Color(0xFF00FFFF);
  static const Color highContrastMagenta = Color(0xFFFF00FF);
  static const Color highContrastGreen = Color(0xFF00FF00);
  static const Color highContrastRed = Color(0xFFFF0000);
  static const Color highContrastYellow = Color(0xFFFFFF00);
  
  // Accessibility
  static const double minTouchTarget = 44.0;
  static const double focusOutlineWidth = 2.0;
  static const Color focusOutlineColor = primaryCyan;
  
  // Visual Effect Specifications
  static const double particleSize = 4.0;
  static const double glowRadius = 20.0;
  static const double energyTrailWidth = 2.0;
  static const double hologramOpacity = 0.8;
  
  // Performance Settings
  static const int maxParticles = 100;
  static const double targetFPS = 60.0;
  static const bool enableGPUAcceleration = true;
  
  // Animation Curves
  static const Curve elasticEase = Curves.elasticOut;
  static const Curve smoothEase = Curves.easeOutCubic;
  static const Curve energyEase = Curves.easeInOutSine;
  
  // Helper method to get color based on contrast mode
  static Color getAdaptiveColor(Color normalColor, bool isHighContrast) {
    if (!isHighContrast) return normalColor;
    
    if (normalColor == cyberCyan) return const Color(0xFF00FFFF);
    if (normalColor == privacyPurple) return const Color(0xFFFF00FF);
    if (normalColor == neuralGreen) return const Color(0xFF00FF00);
    if (normalColor == dangerRed) return const Color(0xFFFF0000);
    if (normalColor == plasmaOrange) return const Color(0xFFFFFF00);
    
    return normalColor;
  }
}