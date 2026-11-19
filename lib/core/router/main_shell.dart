import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../features/shortlist/presentation/cubit/shortlist_cubit.dart';
import '../theme/app_palette.dart';

/// Scaffold for the four main tabs: Home, Search, My Move and Shortlist.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: LucideIcons.house, label: 'Home'),
    (icon: LucideIcons.search, label: 'Search'),
    (icon: LucideIcons.truck, label: 'My Move'),
    (icon: LucideIcons.bookmark, label: 'Shortlist'),
  ];

  void _onTap(int index) => navigationShell.goBranch(
    index,
    // Tapping the current tab again returns to its first screen.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shortlistCount = context.select(
      (ShortlistCubit c) => c.state.ids.length,
    );
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.canvas,
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].icon,
                      label: _tabs[i].label,
                      selected: i == navigationShell.currentIndex,
                      badge: i == 3 && shortlistCount > 0
                          ? '$shortlistCount'
                          : null,
                      onTap: () => _onTap(i),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.textPrimary : p.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: badge == null ? label : '$label, $badge saved',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge != null,
              label: Text(badge ?? ''),
              backgroundColor: p.success,
              textColor: p.onSuccess,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
