import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===== BASE DARK BACKGROUND =====
  static const Color bgPrimary = Color(0xFF050914); // #050914
  static const Color bgSecondary = Color(0xFF091225); // #091225
  static const Color bgTertiary = Color(0xFF11173C); // #11173c
  static const Color bgPurpleDark = Color(0xFF291450); // #291450
  static const Color bgDeep = Color(0xFF070D1C); // #070d1c
  static const Color bgDeep2 = Color(0xFF091224); // #091224

  // ===== SURFACE / CARD =====
  static const Color surfacePrimary = Color(0xFF0A122C); // rgba(10,18,44,...)
  static const Color surfaceSecondary = Color(0xFF0C1231); // rgba(12,18,49,...)
  static const Color surfaceGlass = Color(0xFF0A1127); // rgba(10,17,39,...)
  static const Color surfaceGlass2 = Color(0xFF0D142E); // rgba(13,20,46,...)
  static const Color surfaceCard = Color(0xFF070D1F); // rgba(7,13,31,...)
  static const Color surfaceCard2 = Color(0xFF0B132B); // rgba(11,19,43,...)
  static const Color surfaceGuide = Color(0xFF090F24); // rgba(9,15,36,...)
  static const Color surfaceGuide2 = Color(0xFF0D1530); // rgba(13,21,48,...)

  // ===== PRIMARY / ACCENT =====
  static const Color primaryBlue = Color(0xFF4E7BFF); // #4e7bff
  static const Color primaryBlue2 = Color(0xFF496CFF); // rgba(73,108,255,...)
  static const Color primaryIndigo = Color(0xFF6D5EFC); // #6d5efc
  static const Color primaryIndigo2 = Color(0xFF6C5CFF); // #6c5cff
  static const Color primaryPurple = Color(0xFF8A5CF7); // #8a5cf7
  static const Color primaryPurple2 = Color(0xFF8B5CF6); // #8b5cf6
  static const Color accentPurple = Color(0xFFA855F7); // #a855f7
  static const Color accentSoft = Color(0xFF7F8CFF); // #7f8cff
  static const Color accentSoft2 = Color(0xFF7B8FFF); // #7b8fff
  static const Color accentLight = Color(0xFF8EA2FF); // #8ea2ff
  static const Color accentLight2 = Color(0xFF9EB0FF); // #9eb0ff
  static const Color accentLink = Color(0xFFB8C7FF); // #b8c7ff
  static const Color accentGradientLight = Color(0xFF9DB2FF); // #9db2ff
  static const Color accentGradientPurple = Color(0xFFC088FF); // #c088ff

  // ===== TEXT =====
  static const Color textPrimary = Color(0xFFF8FBFF); // #f8fbff
  static const Color textWhite = Color(0xFFFFFFFF); // #ffffff
  static const Color textSoft = Color(0xFFE0E7FF); // dari rgba(224,231,255,...)
  static const Color textSoft2 = Color(
    0xFFE2E8FF,
  ); // dari rgba(226,232,255,...)
  static const Color textMuted = Color(0xFFCBD6FF); // #cbd6ff
  static const Color textMuted2 = Color(0xFFC9D6FF); // #c9d6ff
  static const Color textMuted3 = Color(
    0xFFD2DCFF,
  ); // dari rgba(210,220,255,...)
  static const Color textMuted4 = Color(0xFFDCE4FF); // #dce4ff
  static const Color textMuted5 = Color(0xFFEEF2FF); // #eef2ff
  static const Color textBody = Color(0xFFDCE4FF);

  // ===== BORDER =====
  static const Color borderSoft = Color(0x1F788CFF); // rgba(120,140,255,0.12)
  static const Color borderSoft2 = Color(
    0x148395FF,
  ); // rgba(131,145,255,0.08/0.12)
  static const Color borderLight = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color borderLight2 = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color borderAccent = Color(0x477A8FFF); // rgba(122,143,255,0.28)

  // ===== SHADOW / GLOW =====
  static const Color shadowDark = Color(0x85000000); // strong black shadow
  static const Color shadowSoft = Color(0x2E000000);
  static const Color glowBlue = Color(0x404E7BFF);
  static const Color glowPurple = Color(0x408A5CF7);

  // ===== STATUS / EXTRA =====
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);

  // ===== COMMON OPACITY COLORS =====
  static const Color white05 = Color(0x0DFFFFFF);
  static const Color white08 = Color(0x14FFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
}

class AppGradients {
  AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.bgPrimary,
      AppColors.bgSecondary,
      AppColors.bgTertiary,
      AppColors.bgPurpleDark,
    ],
  );

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primaryBlue,
      AppColors.primaryIndigo,
      AppColors.primaryPurple,
    ],
  );

  static const LinearGradient loginButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primaryBlue,
      AppColors.primaryIndigo2,
      AppColors.primaryPurple2,
    ],
  );

  static const LinearGradient cardSurface = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfacePrimary, AppColors.surfaceSecondary],
  );

  static const LinearGradient glassPanel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceGlass, AppColors.surfaceGlass2],
  );

  static const LinearGradient statCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceCard, AppColors.surfaceCard2],
  );

  static const LinearGradient guideCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surfaceGuide, AppColors.surfaceGuide2],
  );

  static const LinearGradient heroTextAccent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.textMuted4,
      AppColors.accentGradientLight,
      AppColors.accentSoft,
      AppColors.accentGradientPurple,
    ],
  );
}

class AppTheme {
  static const String fontFamily = 'Poppins';

  // ===== LIGHT PALETTE =====
  static const Color _lightBg = Colors.white;
  static const Color _lightSurface = Color.fromARGB(255, 240, 240, 240);
  static const Color _lightSurfaceSoft = Color(0xFFF1F4FB);
  static const Color _lightText = Color(0xFF111827);
  static const Color _lightTextMuted = Color(0xFF6B7280);
  static const Color _lightBorder = Color(0xFFE5E7EB);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primaryBlue,
            secondary: AppColors.primaryPurple,
            surface: AppColors.surfacePrimary,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimary,
            error: AppColors.danger,
            onError: Colors.white,
          )
        : const ColorScheme.light(
            primary: AppColors.primaryBlue,
            secondary: AppColors.primaryPurple,
            surface: _lightSurface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: _lightText,
            error: AppColors.danger,
            onError: Colors.white,
          );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.bgPrimary : _lightBg,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme, isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bgDeep : Colors.white,
        foregroundColor: isDark ? AppColors.textPrimary : _lightText,
        elevation: 5,
        centerTitle: false,
        titleTextStyle: _buildTextTheme(base.textTheme, isDark).titleLarge,
        shadowColor: isDark
            ? Colors.lightBlue.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.5),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceGlass : _lightSurface,
        elevation: 0,
        shadowColor: isDark
            ? AppColors.shadowDark
            : Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? AppColors.borderLight2 : _lightBorder,
          ),
        ),
      ),
      dividerColor: isDark ? AppColors.borderLight2 : _lightBorder,
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textPrimary : _lightText,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(isDark),
      elevatedButtonTheme: _buildElevatedButtonTheme(isDark),
      outlinedButtonTheme: _buildOutlinedButtonTheme(isDark),
      textButtonTheme: _buildTextButtonTheme(isDark),
      chipTheme: _buildChipTheme(isDark),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.surfaceGlass : _lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceCard : _lightText,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.textPrimary : Colors.white,
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, bool isDark) {
    final primary = isDark ? AppColors.textPrimary : _lightText;
    final soft = isDark ? AppColors.textSoft : _lightText.withOpacity(0.88);
    final muted = isDark ? AppColors.textMuted2 : _lightTextMuted;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: isDark ? AppColors.textMuted : _lightText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: soft),
      bodyMedium: base.bodyMedium?.copyWith(color: soft),
      bodySmall: base.bodySmall?.copyWith(color: muted),
      labelLarge: base.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.white05 : _lightSurfaceSoft,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textMuted2 : _lightTextMuted,
        fontFamily: fontFamily,
      ),
      labelStyle: TextStyle(
        color: isDark ? AppColors.textMuted : _lightTextMuted,
        fontFamily: fontFamily,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderLight2 : _lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryBlue : AppColors.primaryBlue,
          width: 1.3,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderLight2 : _lightBorder,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textMuted2 : _lightText,
        side: BorderSide(color: isDark ? AppColors.borderAccent : _lightBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.accentLight : AppColors.primaryBlue,
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? AppColors.white05 : _lightSurfaceSoft,
      selectedColor: isDark
          ? AppColors.primaryBlue.withOpacity(0.18)
          : AppColors.primaryBlue.withOpacity(0.12),
      disabledColor: isDark ? AppColors.white05 : _lightSurfaceSoft,
      labelStyle: TextStyle(
        color: isDark ? AppColors.textMuted : _lightText,
        fontFamily: fontFamily,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: fontFamily,
      ),
      side: BorderSide(color: isDark ? AppColors.borderLight2 : _lightBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
