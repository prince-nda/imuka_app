import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// The black, full-width call-to-action used at the bottom of most screens.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = LucideIcons.arrowRight,
    this.isLoading = false,
    this.height = 56,
  });

  final String label;

  /// `null` renders the disabled (grey) state.
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !isLoading;
    final fg = enabled ? p.onInk : p.onDisabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: p.ink,
            foregroundColor: p.onInk,
            disabledBackgroundColor: isLoading ? p.ink : p.disabled,
            disabledForegroundColor: p.onDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            textStyle: context.text.labelLarge,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: p.onInk,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: fg),
                        ),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 10),
                        Icon(trailingIcon, size: 18, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// White button with a dark outline ("Compare", "Continue with Google").
class OutlineAppButton extends StatelessWidget {
  const OutlineAppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.leading,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  /// Custom leading widget (e.g. the Google "G"); wins over [leadingIcon].
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.card,
          side: BorderSide(color: p.ink, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: context.text.labelLarge,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            if (leading == null && leadingIcon != null) ...[
              Icon(leadingIcon, size: 18),
              const SizedBox(width: 8),
            ],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Plain text button such as "I already have an account" / "Back to home".
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.text.titleSmall?.copyWith(color: color);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
  }
}

/// Round, outlined icon button (back arrow, bell, bookmark, filters).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 48,
    this.filled = false,
    this.iconColor,
    this.backgroundColor,
    this.showBorder = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final bool filled;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = backgroundColor ?? (filled ? p.ink : p.card);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: CircleBorder(
          side: showBorder ? BorderSide(color: p.border) : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? (filled ? p.onInk : p.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
