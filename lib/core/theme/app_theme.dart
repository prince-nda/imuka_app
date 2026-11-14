import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Builds the light and dark [ThemeData] for Imuka.
abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  /// Shared corner radii, matching the Figma components.
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;

  /// Horizontal page padding used on every screen.
  static const pagePadding = 20.0;

  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(seedColor: p.ink, brightness: brightness).copyWith(
          primary: p.ink,
          onPrimary: p.onInk,
          secondary: p.success,
          onSecondary: p.onSuccess,
          surface: p.canvas,
          onSurface: p.textPrimary,
          error: p.danger,
          outline: p.border,
          outlineVariant: p.border,
        );

    final textTheme = _textTheme(p);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: p.canvas,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: p.textSecondary),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.ink, 1.5),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.5),
        errorStyle: textTheme.bodySmall?.copyWith(color: p.danger),
        errorMaxLines: 2,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.ink,
        inactiveTrackColor: p.border,
        thumbColor: p.card,
        overlayColor: p.ink.withValues(alpha: 0.08),
        trackHeight: 3,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 0,
          pressedElevation: 2,
        ),
        showValueIndicator: ShowValueIndicator.never,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.success : p.onDisabled,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: p.textSecondary, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.ink
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(p.onInk),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.ink : p.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.onInk),
        actionTextColor: p.star,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.ink,
        headerForegroundColor: p.onInk,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.success,
        linearTrackColor: p.muted,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.textPrimary,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppPalette p) {
    TextStyle style(double size, FontWeight weight, {double? height}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: p.textPrimary,
          letterSpacing: size >= 22 ? -0.4 : 0,
        );

    return TextTheme(
      displaySmall: style(30, FontWeight.w800, height: 1.15),
      headlineMedium: style(27, FontWeight.w800, height: 1.2),
      headlineSmall: style(24, FontWeight.w800, height: 1.2),
      titleLarge: style(18, FontWeight.w700),
      titleMedium: style(16, FontWeight.w700),
      titleSmall: style(14, FontWeight.w700),
      bodyLarge: style(16, FontWeight.w500),
      bodyMedium: style(14, FontWeight.w500, height: 1.4),
      bodySmall: style(
        12.5,
        FontWeight.w500,
        height: 1.4,
      ).copyWith(color: p.textSecondary),
      labelLarge: style(16, FontWeight.w700),
      labelMedium: style(13, FontWeight.w600),
      labelSmall: style(11.5, FontWeight.w600),
    );
  }
}
