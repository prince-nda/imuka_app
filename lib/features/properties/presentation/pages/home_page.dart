import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/domain/rwanda_cities.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/selectors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../move/presentation/cubit/move_plan_cubit.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/property_search_cubit.dart';
import '../widgets/city_picker.dart';
import '../widgets/property_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.palette.ink,
          onRefresh: context.read<PropertySearchCubit>().load,
          child: const SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              8,
              AppTheme.pagePadding,
              24,
            ),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(),
                  _PopularNeighbourhoods(),
                  _VerifiedNearby(),
                  SizedBox(height: 16),
                  _PlanMoveCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = context.select(
      (AuthCubit c) => c.state.user?.firstName ?? 'there',
    );
    final filter = context.select((PropertySearchCubit c) => c.state.filter);
    final search = context.read<PropertySearchCubit>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.headerTop, p.headerBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Profile and settings',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => context.push(AppRoutes.settings),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    child: const Icon(LucideIcons.user, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Muraho, $name',
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${filter.to.label} is waiting for you',
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: LucideIcons.bell,
                tooltip: 'Notifications',
                backgroundColor: Colors.white,
                iconColor: AppPaletteColors.black,
                showBorder: false,
                onPressed: () => _showNotifications(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              'Where are you moving?',
              style: context.text.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          _RouteCard(
            from: filter.from,
            to: filter.to,
            onPickFrom: () async {
              final city = await pickCity(
                context,
                title: 'Moving from',
                selected: filter.from,
              );
              if (city != null) search.setFrom(city);
            },
            onPickTo: () async {
              final city = await pickCity(
                context,
                title: 'Moving to',
                selected: filter.to,
              );
              if (city != null) search.setTo(city);
            },
            onSwap: search.swapRoute,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppPaletteColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: () {
                search.showAllInDestination();
                context.push(AppRoutes.searchResults);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Find homes in ${filter.to.label}',
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelLarge?.copyWith(
                        color: AppPaletteColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final settings = context.read<SettingsCubit>().state;
    final plan = context.read<MovePlanCubit>().state.plan;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _NotificationsSheet(settings: settings, moveDate: plan.date),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.settings, required this.moveDate});

  final AppSettings settings;
  final DateTime moveDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Notifications', style: context.text.titleLarge),
        const SizedBox(height: 12),
        if (settings.moveReminders)
          InfoPanel(
            icon: LucideIcons.calendar,
            title: 'Moving day: ${Formatters.longDate(moveDate)}',
            message:
                'Book your movers at least a week before to lock in '
                'the price.',
          )
        else
          const InfoPanel(
            icon: LucideIcons.bellOff,
            message:
                'Move reminders are off. You can turn them on in '
                'Settings.',
          ),
      ],
    );
  }
}

/// White card with FROM / TO rows and a swap button.
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
  });

  final RwandaCity from;
  final RwandaCity to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _RouteRow(
                  icon: LucideIcons.circleDot,
                  label: 'FROM',
                  value: from.longLabel,
                  onTap: onPickFrom,
                ),
                Divider(indent: 16, endIndent: 0, color: p.border),
                _RouteRow(
                  icon: LucideIcons.mapPin,
                  label: 'TO',
                  value: to.longLabel,
                  onTap: onPickTo,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleIconButton(
              icon: LucideIcons.arrowUpDown,
              tooltip: 'Swap from and to',
              backgroundColor: p.muted,
              showBorder: false,
              onPressed: onSwap,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${label == 'FROM' ? 'Moving from' : 'Moving to'} $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.labelSmall?.copyWith(
                        color: context.palette.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularNeighbourhoods extends StatelessWidget {
  const _PopularNeighbourhoods();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PropertySearchCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('Popular in ${state.filter.to.label}'),
        PillRow(
          children: [
            for (final (i, name) in state.neighbourhoods.indexed)
              ChoicePill(
                label: name,
                selected: i == 0,
                onTap: () {
                  context.read<PropertySearchCubit>().showNeighbourhood(name);
                  context.push(AppRoutes.searchResults);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _VerifiedNearby extends StatelessWidget {
  const _VerifiedNearby();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PropertySearchCubit>().state;
    final nearby = state.verifiedNearby;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Verified homes near you',
          trailing: TextButton(
            onPressed: () {
              context.read<PropertySearchCubit>().showAllInDestination();
              context.push(AppRoutes.searchResults);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: context.text.labelMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: context.palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (state.status) {
            RequestStatus.initial ||
            RequestStatus.loading => const PropertyCardSkeleton(),
            RequestStatus.failure => EmptyState(
              icon: LucideIcons.wifiOff,
              title: 'Couldn\'t load homes',
              message: 'Check your connection and try again.',
              actionLabel: 'Retry',
              onAction: context.read<PropertySearchCubit>().load,
            ),
            RequestStatus.success when nearby.isEmpty => EmptyState(
              icon: LucideIcons.house,
              title: 'No verified homes yet',
              message:
                  'We don\'t have verified listings in '
                  '${state.filter.to.label} yet. Try Kigali.',
            ),
            RequestStatus.success => PropertyCard(property: nearby.first),
          },
        ),
      ],
    );
  }
}

class _PlanMoveCard extends StatelessWidget {
  const _PlanMoveCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      color: p.muted,
      borderColor: Colors.transparent,
      radius: AppTheme.radiusMd,
      onTap: () => context.go(AppRoutes.move),
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.truck, dark: true, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan your move', style: context.text.titleMedium),
                Text(
                  'List items, book movers, track live',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: p.textSecondary),
        ],
      ),
    );
  }
}
