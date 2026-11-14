import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';

enum BadgeTone { success, warning, highlight, neutral, successOutline }

/// Pill-shaped status badge ("Verified", "Pending", "Best value").
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = BadgeTone.success,
    this.compact = false,
  });

  /// Green "Verified" badge shown on listings and movers.
  const StatusBadge.verified({super.key, this.label = 'Verified'})
    : icon = LucideIcons.shieldCheck,
      tone = BadgeTone.success,
      compact = false;

  /// Amber badge for listings whose documents are still in review.
  const StatusBadge.pending({super.key, this.label = 'Pending'})
    : icon = LucideIcons.clock,
      tone = BadgeTone.warning,
      compact = false;

  final String label;
  final IconData? icon;
  final BadgeTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border) = switch (tone) {
      BadgeTone.success => (p.success, p.onSuccess, null),
      BadgeTone.warning => (p.warningSoft, p.warning, null),
      BadgeTone.highlight => (p.highlight, p.onHighlight, null),
      BadgeTone.neutral => (p.muted, p.textPrimary, null),
      BadgeTone.successOutline => (p.card, p.success, p.success),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: fg,
              fontSize: compact ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Star + rating (+ optional review count), e.g. "★ 4.8 (26)".
class RatingLabel extends StatelessWidget {
  const RatingLabel({
    super.key,
    required this.rating,
    this.reviews,
    this.large = false,
  });

  final double rating;
  final int? reviews;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = (large ? context.text.titleMedium : context.text.labelMedium)
        ?.copyWith(fontWeight: FontWeight.w700);
    return Semantics(
      label:
          'Rated ${rating.toStringAsFixed(1)} out of 5'
          '${reviews == null ? '' : ' from $reviews reviews'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: large ? 20 : 17, color: p.star),
          const SizedBox(width: 3),
          Text(rating.toStringAsFixed(1), style: style),
          if (reviews != null)
            Text(
              ' ($reviews)',
              style: style?.copyWith(
                color: p.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Large green circle with a white tick (success screens).
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({
    super.key,
    this.size = 88,
    this.icon = LucideIcons.check,
  });

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
        child: Icon(icon, color: p.onSuccess, size: size * 0.45),
      ),
    );
  }
}

/// Small filled tick circle used in checklists.
class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.checked, this.size = 26});

  final bool checked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? p.success : Colors.transparent,
        border: Border.all(
          color: checked ? p.success : p.border,
          width: checked ? 0 : 2,
        ),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: size * 0.6, color: p.onSuccess)
          : null,
    );
  }
}

/// Thin progress bar with green fill, as on "Your move" and "Check items".
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (context, v, _) =>
            LinearProgressIndicator(value: v, minHeight: height),
      ),
    );
  }
}
