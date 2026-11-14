import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Box that looks like a dropdown ("📍 Huye ⌄") and opens a picker on tap.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$semanticLabel: $value',
      excludeSemantics: true,
      child: Material(
        color: p.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: p.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: p.textPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 18, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing [options]; resolves with the tapped option.
Future<T?> showOptionsSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required String Function(T) labelOf,
  required T? selected,
  String Function(T)? subtitleOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final p = context.palette;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(title, style: context.text.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        minTileHeight: 56,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        title: Text(
                          labelOf(option),
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: option == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: subtitleOf == null
                            ? null
                            : Text(
                                subtitleOf(option),
                                style: context.text.bodySmall,
                              ),
                        trailing: option == selected
                            ? Icon(LucideIcons.check, color: p.success)
                            : null,
                        onTap: () => Navigator.of(context).pop(option),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Asks the user to confirm a destructive action.
Future<bool> confirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final p = context.palette;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
