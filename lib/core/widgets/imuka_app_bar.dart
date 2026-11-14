import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'buttons.dart';

/// Screen header from the Figma file: round back button, centred title and an
/// optional round action on the right.
class ImukaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ImukaAppBar({
    super.key,
    this.title,
    this.action,
    this.onBack,
    this.showBack = true,
  });

  final String? title;
  final Widget? action;

  /// Overrides the default back behaviour (pop, or go home if nothing to pop).
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 68,
      automaticallyImplyLeading: false,
      leadingWidth: 72,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Center(
                child: CircleIconButton(
                  icon: LucideIcons.chevronLeft,
                  tooltip: 'Back',
                  onPressed: onBack ?? () => _defaultBack(context),
                ),
              ),
            )
          : null,
      title: title == null ? null : Text(title!),
      actions: [
        if (action != null)
          Padding(padding: const EdgeInsets.only(right: 20), child: action),
      ],
    );
  }

  static void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
