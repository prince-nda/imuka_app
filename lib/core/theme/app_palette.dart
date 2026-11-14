import 'package:flutter/material.dart';

/// Semantic colour tokens taken from the Imuka Figma file.
///
/// The design follows a 60-30-10 rule on a black-and-white base, and colour is
/// reserved for meaning: green = verified / completed, amber = pending,
/// yellow = ratings and highlights, red = problems.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.card,
    required this.muted,
    required this.border,
    required this.ink,
    required this.onInk,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.onSuccess,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.star,
    required this.highlight,
    required this.onHighlight,
    required this.danger,
    required this.disabled,
    required this.onDisabled,
    required this.headerTop,
    required this.headerBottom,
    required this.mapBlock,
    required this.mapRoad,
  });

  /// Scaffold background.
  final Color canvas;

  /// Background of white cards that sit on [canvas].
  final Color card;

  /// Warm sand background used for inputs and info panels.
  final Color muted;
  final Color border;

  /// Primary action colour (black in light mode, near-white in dark mode).
  final Color ink;
  final Color onInk;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color onSuccess;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color star;
  final Color highlight;
  final Color onHighlight;
  final Color danger;
  final Color disabled;
  final Color onDisabled;

  /// Gradient used by the dark hero card on the home screen.
  final Color headerTop;
  final Color headerBottom;
  final Color mapBlock;
  final Color mapRoad;

  static const light = AppPalette(
    canvas: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFFF6F4EF),
    border: Color(0xFFE6E3DC),
    ink: Color(0xFF0B0B0B),
    onInk: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF0B0B0B),
    textSecondary: Color(0xFF66645F),
    success: Color(0xFF13784A),
    onSuccess: Color(0xFFFFFFFF),
    successSoft: Color(0xFFE5F2EB),
    warning: Color(0xFF8F5400),
    warningSoft: Color(0xFFFFF1D6),
    star: Color(0xFFF5B301),
    highlight: Color(0xFFFFF0B8),
    onHighlight: Color(0xFF3D2E00),
    danger: Color(0xFFC8261A),
    disabled: Color(0xFFE4E4E2),
    onDisabled: Color(0xFF75736E),
    headerTop: Color(0xFF55585C),
    headerBottom: Color(0xFF1E2023),
    mapBlock: Color(0xFFE2E1DD),
    mapRoad: Color(0xFFF6F4EF),
  );

  static const dark = AppPalette(
    canvas: Color(0xFF0F0F0F),
    card: Color(0xFF181817),
    muted: Color(0xFF222220),
    border: Color(0xFF35342F),
    ink: Color(0xFFF4F2EE),
    onInk: Color(0xFF0B0B0B),
    textPrimary: Color(0xFFF4F2EE),
    textSecondary: Color(0xFFB3B0A8),
    success: Color(0xFF2E9E68),
    onSuccess: Color(0xFFFFFFFF),
    successSoft: Color(0xFF173226),
    warning: Color(0xFFFFC266),
    warningSoft: Color(0xFF3A2C12),
    star: Color(0xFFF5B301),
    highlight: Color(0xFF4A3B07),
    onHighlight: Color(0xFFFFE9A3),
    danger: Color(0xFFFF7B70),
    disabled: Color(0xFF2C2C2A),
    onDisabled: Color(0xFF9A978F),
    headerTop: Color(0xFF3A3C40),
    headerBottom: Color(0xFF161719),
    mapBlock: Color(0xFF2A2A28),
    mapRoad: Color(0xFF1C1C1B),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: mix(canvas, other.canvas),
      card: mix(card, other.card),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      ink: mix(ink, other.ink),
      onInk: mix(onInk, other.onInk),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      successSoft: mix(successSoft, other.successSoft),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      star: mix(star, other.star),
      highlight: mix(highlight, other.highlight),
      onHighlight: mix(onHighlight, other.onHighlight),
      danger: mix(danger, other.danger),
      disabled: mix(disabled, other.disabled),
      onDisabled: mix(onDisabled, other.onDisabled),
      headerTop: mix(headerTop, other.headerTop),
      headerBottom: mix(headerBottom, other.headerBottom),
      mapBlock: mix(mapBlock, other.mapBlock),
      mapRoad: mix(mapRoad, other.mapRoad),
    );
  }
}

extension AppPaletteX on BuildContext {
  /// Shortcut for `Theme.of(context).extension<AppPalette>()!`.
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;

  TextTheme get text => Theme.of(this).textTheme;
}

/// Fixed colours for surfaces that look the same in light and dark mode
/// (e.g. the white "Find homes" button on the dark hero card).
abstract final class AppPaletteColors {
  static const black = Color(0xFF0B0B0B);
}
