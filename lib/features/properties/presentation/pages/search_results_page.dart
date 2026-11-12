import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../cubit/property_search_cubit.dart';
import '../widgets/property_card.dart';

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key});

  void _editFilters(BuildContext context) => context.go(AppRoutes.search);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ImukaAppBar(
        title: 'Search results',
        action: CircleIconButton(
          icon: LucideIcons.slidersHorizontal,
          tooltip: 'Edit filters',
          onPressed: () => _editFilters(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<PropertySearchCubit, PropertySearchState>(
          builder: (context, state) {
            final filter = state.filter;
            final noun = filter.verifiedOnly ? 'verified homes' : 'homes';
            return RefreshIndicator(
              color: context.palette.ink,
              onRefresh: context.read<PropertySearchCubit>().load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  4,
                  AppTheme.pagePadding,
                  24,
                ),
                children: [
                  ResponsiveCenter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          color: context.palette.muted,
                          borderColor: Colors.transparent,
                          radius: AppTheme.radiusMd,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.building, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Near ${filter.landmark.name}',
                                      style: context.text.titleSmall,
                                    ),
                                    Text(
                                      filter.landmark.address,
                                      style: context.text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${state.results.length} $noun in '
                                '${filter.to.label}',
                                style: context.text.bodyMedium?.copyWith(
                                  color: context.palette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _editFilters(context),
                              icon: const Icon(
                                LucideIcons.slidersHorizontal,
                                size: 16,
                              ),
                              label: const Text('Edit filters'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.palette.textPrimary,
                                minimumSize: const Size(48, 44),
                                side: BorderSide(color: context.palette.border),
                                textStyle: context.text.labelMedium,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._results(context, state),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context, PropertySearchState state) {
    if (state.status == RequestStatus.loading && state.all.isEmpty) {
      return [
        for (var i = 0; i < 3; i++) ...[
          const PropertyCardSkeleton(),
          const SizedBox(height: 12),
        ],
      ];
    }
    if (state.status == RequestStatus.failure) {
      return [
        EmptyState(
          icon: LucideIcons.wifiOff,
          title: 'Couldn\'t load homes',
          message: 'Check your connection and pull down to try again.',
          actionLabel: 'Retry',
          onAction: context.read<PropertySearchCubit>().load,
        ),
      ];
    }
    if (state.results.isEmpty) {
      return [
        EmptyState(
          icon: LucideIcons.searchX,
          title: 'No homes match',
          message:
              'Try another neighbourhood, a wider budget or fewer '
              'bedrooms.',
          actionLabel: 'Edit filters',
          onAction: () => _editFilters(context),
        ),
      ];
    }
    return [
      for (final property in state.results) ...[
        PropertyCard(property: property),
        const SizedBox(height: 12),
      ],
    ];
  }
}
