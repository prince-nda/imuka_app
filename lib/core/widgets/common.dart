import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'layout.dart';

/// Rounded asset image with an accessible description.
class RoundedImage extends StatelessWidget {
  const RoundedImage({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.width,
    this.height,
    this.radius = AppTheme.radiusMd,
  });

  final String asset;
  final String semanticLabel;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, _) => Container(
          width: width,
          height: height,
          color: context.palette.muted,
          child: Icon(LucideIcons.image, color: context.palette.textSecondary),
        ),
      ),
    );
  }
}

/// The Imuka mark: a location pin under a roof, on a black rounded square.
class ImukaLogo extends StatelessWidget {
  const ImukaLogo({super.key, this.size = 36, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.08,
            child: Icon(
              LucideIcons.chevronUp,
              size: size * 0.5,
              color: p.onInk,
            ),
          ),
          Positioned(
            bottom: size * 0.14,
            child: Icon(LucideIcons.mapPin, size: size * 0.48, color: p.onInk),
          ),
        ],
      ),
    );
    if (!showWordmark) return Semantics(label: 'Imuka', child: mark);
    return Semantics(
      label: 'Imuka',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: 10),
          Text(
            'imuka',
            style: context.text.headlineSmall?.copyWith(fontSize: size * 0.72),
          ),
        ],
      ),
    );
  }
}

/// Sand panel with an icon and a message ("You pay only after...").
class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.message,
    this.title,
    this.icon = LucideIcons.shieldCheck,
    this.outlined = false,
  });

  final String message;
  final String? title;
  final IconData icon;

  /// Outlined white variant used for warnings such as "Stay safe".
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: outlined ? p.card : p.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: outlined ? Border.all(color: p.ink, width: 1.2) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: outlined ? p.textPrimary : p.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                ],
                Text(message, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Label on the left, bold value on the right ("Deposit ... 1 month").
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.emphasize = false,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  final String label;
  final String value;
  final bool showDivider;
  final bool emphasize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: p.border))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? context.text.titleMedium
                  : context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasize
                  ? context.text.headlineSmall?.copyWith(fontSize: 22)
                  : context.text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered tappable row with an icon tile, title, subtitle and chevron.
class NavListTile extends StatelessWidget {
  const NavListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: AppTheme.radiusMd,
      child: Row(
        children: [
          IconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing ??
              Icon(LucideIcons.chevronRight, color: p.textSecondary, size: 20),
        ],
      ),
    );
  }
}

/// Friendly empty / error state with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: p.muted, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: p.textPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: p.textPrimary,
                side: BorderSide(color: p.ink),
                shape: const StadiumBorder(),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows a floating snackbar; error messages get a red accent icon.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
}) {
  final p = context.palette;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        action: action,
        content: Row(
          children: [
            Icon(
              isError ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              color: isError ? p.danger : p.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
