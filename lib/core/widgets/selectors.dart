import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Rounded chip that is black when selected ("Kacyiru", "Apartment").
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onInk : p.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.ink : p.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? p.ink : p.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: context.text.labelMedium?.copyWith(
                    color: fg,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of [ChoicePill]s that bleeds to the screen edge.
class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Sand segmented control with a sliding black selection ("Any 1 2 3+").
class SegmentedSelector<T> extends StatelessWidget {
  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                selected: option == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == selected ? p.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      labelOf(option),
                      style: context.text.titleSmall?.copyWith(
                        color: option == selected ? p.onInk : p.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
