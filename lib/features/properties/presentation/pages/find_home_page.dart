import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/pickers.dart';
import '../../../../core/widgets/selectors.dart';
import '../../domain/entities/landmark.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter.dart';
import '../cubit/property_search_cubit.dart';
import '../widgets/city_picker.dart';
import '../widgets/property_icons.dart';

/// Search tab: all filters, with a live count of matching homes.
class FindHomePage extends StatelessWidget {
  const FindHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ImukaAppBar(title: 'Find your home'),
      body: const SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            _RouteFields(),
            _NeighbourhoodFilter(),
            _TypeFilter(),
            _BudgetFilter(),
            _BedroomsFilter(),
            SizedBox(height: 20),
            _VerifiedToggle(),
          ],
        ),
      ),
      bottomNavigationBar:
          BlocBuilder<PropertySearchCubit, PropertySearchState>(
            buildWhen: (a, b) =>
                a.results.length != b.results.length ||
                a.filter.verifiedOnly != b.filter.verifiedOnly,
            builder: (context, state) {
              final count = state.results.length;
              final verified = state.filter.verifiedOnly ? 'verified ' : '';
              final noun = count == 1 ? 'home' : 'homes';
              return BottomActionBar(
                children: [
                  PrimaryButton(
                    label: count == 0
                        ? 'No homes match — try fewer filters'
                        : 'Show $count $verified$noun',
                    trailingIcon: count == 0 ? null : LucideIcons.arrowRight,
                    onPressed: count == 0
                        ? null
                        : () => context.push(AppRoutes.searchResults),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _RouteFields extends StatelessWidget {
  const _RouteFields();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PropertySearchCubit>().state;
    final cubit = context.read<PropertySearchCubit>();
    final filter = state.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Moving from'),
                  SelectField(
                    icon: LucideIcons.mapPin,
                    value: filter.from.label,
                    semanticLabel: 'Moving from',
                    onTap: () async {
                      final city = await pickCity(
                        context,
                        title: 'Moving from',
                        selected: filter.from,
                      );
                      if (city != null) cubit.setFrom(city);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FieldLabel('Moving to'),
                  SelectField(
                    icon: LucideIcons.mapPin,
                    value: filter.to.label,
                    semanticLabel: 'Moving to',
                    onTap: () async {
                      final city = await pickCity(
                        context,
                        title: 'Moving to',
                        selected: filter.to,
                      );
                      if (city != null) cubit.setTo(city);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const FieldLabel('Near (work or school)'),
        SelectField(
          icon: LucideIcons.building,
          value: filter.landmark.shortLabel,
          semanticLabel: 'Near work or school',
          onTap: () async {
            final landmark = await showOptionsSheet<Landmark>(
              context: context,
              title: 'Near (work or school)',
              options: state.landmarks,
              selected: filter.landmark,
              labelOf: (l) => l.name,
              subtitleOf: (l) => l.address,
            );
            if (landmark != null) cubit.setLandmark(landmark);
          },
        ),
      ],
    );
  }
}

class _NeighbourhoodFilter extends StatelessWidget {
  const _NeighbourhoodFilter();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PropertySearchCubit>();
    final (selected, options) = context.select(
      (PropertySearchCubit c) =>
          (c.state.filter.neighbourhood, c.state.neighbourhoods),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Neighbourhood'),
        PillRow(
          children: [
            ChoicePill(
              label: 'Any',
              selected: selected == null,
              onTap: () => cubit.setNeighbourhood(null),
            ),
            for (final name in options)
              ChoicePill(
                label: name,
                selected: selected == name,
                onTap: () => cubit.setNeighbourhood(name),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter();

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (PropertySearchCubit c) => c.state.filter.type,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Property type'),
        PillRow(
          children: [
            for (final type in PropertyType.values)
              ChoicePill(
                label: type.label,
                icon: type.icon,
                selected: selected == type,
                onTap: () =>
                    context.read<PropertySearchCubit>().toggleType(type),
              ),
          ],
        ),
      ],
    );
  }
}

class _BudgetFilter extends StatelessWidget {
  const _BudgetFilter();

  @override
  Widget build(BuildContext context) {
    final filter = context.select((PropertySearchCubit c) => c.state.filter);
    final maxLabel = filter.hasNoUpperBudget
        ? '${Formatters.rwf(PropertyFilter.budgetCeiling)}+'
        : Formatters.rwf(filter.maxBudget).replaceFirst('RWF ', '');
    final label = '${Formatters.rwf(filter.minBudget)} – $maxLabel';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Monthly budget',
          trailing: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
        RangeSlider(
          min: PropertyFilter.budgetFloor.toDouble(),
          max: PropertyFilter.budgetCeiling.toDouble(),
          divisions: PropertyFilter.budgetCeiling ~/ PropertyFilter.budgetStep,
          values: RangeValues(
            filter.minBudget.toDouble(),
            filter.maxBudget.toDouble(),
          ),
          semanticFormatterCallback: (v) => Formatters.rwf(v.round()),
          onChanged: (v) => context.read<PropertySearchCubit>().setBudget(
            v.start.round(),
            v.end.round(),
          ),
        ),
      ],
    );
  }
}

class _BedroomsFilter extends StatelessWidget {
  const _BedroomsFilter();

  @override
  Widget build(BuildContext context) {
    final selected = context.select(
      (PropertySearchCubit c) => c.state.filter.bedrooms,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Bedrooms', top: 8),
        SegmentedSelector<int?>(
          options: const [null, 1, 2, PropertyFilter.bedroomsThreePlus],
          selected: selected,
          labelOf: (v) => switch (v) {
            null => 'Any',
            PropertyFilter.bedroomsThreePlus => '3+',
            _ => '$v',
          },
          onChanged: context.read<PropertySearchCubit>().setBedrooms,
        ),
      ],
    );
  }
}

class _VerifiedToggle extends StatelessWidget {
  const _VerifiedToggle();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = context.select(
      (PropertySearchCubit c) => c.state.filter.verifiedOnly,
    );
    return MergeSemantics(
      child: Row(
        children: [
          Icon(LucideIcons.shieldCheck, color: p.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verified listings only', style: context.text.titleSmall),
                Text(
                  'Owner ID and property checked',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: context.read<PropertySearchCubit>().setVerifiedOnly,
          ),
        ],
      ),
    );
  }
}
