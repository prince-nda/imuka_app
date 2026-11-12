import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../cubit/move_plan_cubit.dart';

/// Itemised, upfront cost estimate.
class MovingCostsPage extends StatelessWidget {
  const MovingCostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = context.watch<MovePlanCubit>().state;
    final estimate = state.estimate;
    final plan = state.plan;
    final lines = [
      for (final line in estimate.itemLines) (line.label, line.amount),
      (
        'Truck and fuel (${estimate.distanceKm} km, ${state.vehicle.label.toLowerCase()})',
        estimate.transportFee,
      ),
      ('Loaders (${estimate.loaders})', estimate.loadersFee),
    ];

    return Scaffold(
      appBar: const ImukaAppBar(title: 'Moving costs'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: p.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated moving cost',
                    style: context.text.bodySmall?.copyWith(
                      color: p.onInk.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.rwf(estimate.total),
                      style: context.text.displaySmall?.copyWith(
                        color: p.onInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${estimate.itemCount} items · ${plan.routeLabel} · '
                    '~${plan.distanceKm} km',
                    style: context.text.bodySmall?.copyWith(
                      color: p.onInk.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Breakdown'),
            for (final (i, (label, amount)) in lines.indexed)
              KeyValueRow(
                label: label,
                value: Formatters.rwf(amount),
                showDivider: i < lines.length - 1,
              ),
            const SizedBox(height: 16),
            const InfoPanel(
              message:
                  'You pay only after you confirm every item at your '
                  'new home.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          PrimaryButton(
            label: 'Choose movers',
            onPressed: estimate.isEmpty
                ? null
                : () => context.push(AppRoutes.movers),
          ),
        ],
      ),
    );
  }
}
