import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KumPay brand palette, derived from the web design system.
abstract final class KpColors {
  static const canvas = Color(0xFFF8F5EC);
  static const surface = Color(0xFFFFFDF7);
  static const soft = Color(0xFFF1ECDD);
  static const softGreen = Color(0xFFE8F0EA);

  static const primary = Color(0xFF1F4438);
  static const primaryDark = Color(0xFF123026);
  static const primaryLight = Color(0xFF2D5D4C);
  static const gold = Color(0xFFE9B63C);
  static const goldDeep = Color(0xFFC58D1F);
  static const goldSoft = Color(0xFFFBF0D2);

  static const ink = Color(0xFF142A23);
  static const ink2 = Color(0xFF3F5148);
  static const muted = Color(0xFF7D8B82);
  static const line = Color(0xFFE5E0D1);

  static const success = Color(0xFF2F8A65);
  static const successSoft = Color(0xFFE4F2EA);
  static const danger = Color(0xFFC74A3D);
  static const dangerSoft = Color(0xFFFBE9E6);
  static const warning = Color(0xFFB67A1E);
  static const warningSoft = Color(0xFFFBF0DB);
  static const info = Color(0xFF3C6E8F);
  static const infoSoft = Color(0xFFE8F1F7);

  static const gradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3C95A), Color(0xFFD79A25)],
  );

  static const gradientForest = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A5949), Color(0xFF17392D)],
  );
}

abstract final class KpRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class KpSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const xxl = 28.0;
  static const xxxl = 36.0;
}

abstract final class KpShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x0F142A23),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const card = [
    BoxShadow(
      color: Color(0x12142A23),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const balance = [
    BoxShadow(
      color: Color(0x33203F32),
      blurRadius: 28,
      offset: Offset(0, 16),
    ),
  ];
}

abstract final class KpTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final text = _textTheme(base.textTheme);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: KpColors.primary,
        onPrimary: Color(0xFFFDF9EE),
        secondary: KpColors.gold,
        onSecondary: KpColors.primaryDark,
        surface: KpColors.surface,
        onSurface: KpColors.ink,
        error: KpColors.danger,
        onError: Colors.white,
        outline: KpColors.line,
      ),
      textTheme: text,
      scaffoldBackgroundColor: KpColors.canvas,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: KpColors.ink,
      ),
      dividerTheme: const DividerThemeData(
        color: KpColors.line,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KpColors.surface,
        hintStyle: text.bodyMedium?.copyWith(color: KpColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KpRadius.md),
          borderSide: const BorderSide(color: KpColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KpRadius.md),
          borderSide: const BorderSide(color: KpColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KpRadius.md),
          borderSide: const BorderSide(color: KpColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KpRadius.md),
          borderSide: const BorderSide(color: KpColors.danger),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    final body = GoogleFonts.manropeTextTheme(base);
    final display = GoogleFonts.bricolageGrotesqueTextTheme(base);

    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -1.4,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -1,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -0.8,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -0.6,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -0.4,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: KpColors.ink,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
        letterSpacing: -0.2,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: KpColors.ink,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: KpColors.ink2,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: KpColors.ink2,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: KpColors.ink2,
        height: 1.5,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: KpColors.muted,
        height: 1.45,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: KpColors.ink2,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: KpColors.muted,
        letterSpacing: 0.3,
      ),
    );
  }
}
