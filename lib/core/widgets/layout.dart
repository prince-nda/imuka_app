import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

/// Keeps content at a comfortable phone width on tablets and in landscape,
/// so layouts designed at 390pt never stretch awkwardly.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // heightFactor: 1 keeps the height of the child, so this is safe inside
    // bottom bars and other unbounded or loosely constrained parents.
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Standard scrollable page body with Figma's 20pt side padding.
///
/// Everything scrolls, so no screen overflows in landscape or with large
/// accessibility text sizes.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(
      AppTheme.pagePadding,
      4,
      AppTheme.pagePadding,
      24,
    ),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ),
    );
  }
}

/// Pinned bottom area holding the main call-to-action of a screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.children,
    this.showDivider = false,
  });

  final List<Widget> children;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.canvas,
        border: showDivider
            ? Border(top: BorderSide(color: context.palette.border))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            12,
            AppTheme.pagePadding,
            16,
          ),
          child: ResponsiveCenter(
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// Bold section heading ("Neighbourhood", "Property information").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing, this.top = 20});

  final String title;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.text.titleMedium),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small grey label that sits above an input ("Phone number").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: context.text.bodySmall),
    );
  }
}

/// Rounded container used for cards with an optional outline.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppTheme.radiusLg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? p.border, width: borderWidth),
    );
    return Material(
      color: color ?? p.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Sand-coloured square holding an icon, used at the start of list rows.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.dark = false,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final bool dark;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? p.ink : p.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, size: iconSize, color: dark ? p.onInk : p.textPrimary),
    );
  }
}

/// Scrollable page whose [footer] sits at the bottom of the screen when
/// there is room, and simply follows the content when there isn't
/// (landscape, small phones, large text).
class ScrollWithFooter extends StatelessWidget {
  const ScrollWithFooter({
    super.key,
    required this.children,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
  });

  final List<Widget> children;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
        if (footer != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: padding.copyWith(top: 24, bottom: 16),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ResponsiveCenter(child: footer!),
              ),
            ),
          ),
      ],
    );
  }
}
