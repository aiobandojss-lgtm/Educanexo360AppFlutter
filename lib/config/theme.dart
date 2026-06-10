// lib/config/theme.dart

import 'package:flutter/material.dart';

/// Colores de EducaNexo360
/// Traducidos desde src/constants/theme/colors.ts
class AppColors {
  // Colores principales
  static const Color primary = Color(0xFF059669); // #059669 Emerald-600
  static const Color secondary = Color(0xFF0D9488); // #0d9488 Teal-600
  static const Color success = Color(0xFF10B981); // #10b981
  static const Color warning = Color(0xFFF59E0B); // #f59e0b
  static const Color error = Color(0xFFEF4444); // #ef4444
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Superficies
  static const Color surfaceMain = Color(0xFFF0FDF4); // #f0fdf4 Green-50
  static const Color surfaceSecondary = Color(0xFFDCFCE7); // #dcfce7 Green-100
  static const Color onSurface = Color(0xFF1E293B); // #1e293b
  static const Color onSurfaceVariant = Color(0xFF64748B); // #64748b

  // Gradientes
  static const Color emerald700 = Color(0xFF047857); // #047857 Emerald-700
  static const Color teal500 = Color(0xFF14B8A6); // #14b8a6 Teal-500

  // Grises
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);

  // Niveles (para gradientes/sombras)
  static const Color level1 = Color(0xFFF9FAFB);
  static const Color level2 = Color(0xFFF3F4F6);
  static const Color level3 = Color(0xFFE5E7EB);
  static const Color level4 = Color(0xFFD1D5DB);
  static const Color level5 = Color(0xFF9CA3AF);

  // Colores por rol (para avatares/badges)
  static const Map<String, Color> roleColors = {
    'RECTOR': Color(0xFFDC2626), // #dc2626
    'ADMIN': Color(0xFFDC2626),
    'ADMINISTRATIVO': Color(0xFF0891B2), // Cyan-600
    'DOCENTE': Color(0xFF059669), // #059669
    'ESTUDIANTE': Color(0xFF2563EB), // #2563eb
    'ACUDIENTE': Color(0xFFD97706), // #d97706
  };

  /// Obtener color por rol
  static Color getRoleColor(String role) {
    return roleColors[role] ?? primary;
  }
}

/// TipografÃ­a de EducaNexo360
/// Traducida desde src/constants/theme/typography.ts
class AppTypography {
  // Headers principales
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.25, // lineHeight: 40 / fontSize: 32
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.29, // 36/28
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33, // 32/24
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4, // 28/20
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44, // 26/18
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5, // 24/16
  );

  // Body text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24/16
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43, // 20/14
  );

  // Utilidades
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33, // 16/12
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5, // 24/16
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.6, // 16/10
    letterSpacing: 1.5,
  );

  // EspecÃ­ficos de EducaNexo360
  static const TextStyle welcomeText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle userName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle userRole = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // Mensajes
  static const TextStyle messageSender = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle messagePreview = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38, // 18/13
  );

  static const TextStyle messageTime = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // Formularios
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  // Cards
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // Login
  static const TextStyle appName = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle tagline = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}

/// Tema principal de la aplicaciÃ³n
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Colores
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.onSurface,
        onError: AppColors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.surfaceMain,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.h5.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.button,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.level3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.level3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.inputLabel,
        hintStyle: AppTypography.inputText.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // Texto por defecto
      textTheme: const TextTheme(
        displayLarge: AppTypography.h1,
        displayMedium: AppTypography.h2,
        displaySmall: AppTypography.h3,
        headlineMedium: AppTypography.h4,
        headlineSmall: AppTypography.h5,
        titleLarge: AppTypography.h6,
        bodyLarge: AppTypography.body1,
        bodyMedium: AppTypography.body2,
        bodySmall: AppTypography.caption,
        labelLarge: AppTypography.button,
      ),
    );
  }
}
