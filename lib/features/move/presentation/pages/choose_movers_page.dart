import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/request_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/selectors.dart';
import '../../domain/entities/mover.dart';
import '../../domain/services/move_cost_calculator.dart';
import '../cubit/move_booking_cubit.dart';
import '../cubit/move_plan_cubit.dart';
import '../cubit/move_tasks_cubit.dart';
import '../widgets/move_widgets.dart';

/// Compare verified movers and lock in a price.
class ChooseMoversPage extends StatefulWidget {
  const ChooseMoversPage({super.key});

  @override
  State<ChooseMoversPage> createState() => _ChooseMoversPageState();
}

/// Stateful only to trigger the first load; state lives in the Cubits.
class _ChooseMoversPageState extends State<ChooseMoversPage> {
  @override
  void initState() {
    super.initState();
    _loadMovers(context.read<MovePlanCubit>().state.vehicle);
  }

  void _loadMovers(VehicleType vehicle) {
    final estimate = context.read<MovePlanCubit>().state.estimate;
    context.read<MoveBookingCubit>().loadMovers(
      vehicle,
      preselect: (movers) => MoverRanking.bestValue(movers, estimate)?.id,
    );
  }

  void _selectVehicle(VehicleType vehicle) {
    context.read<MovePlanCubit>().setVehicle(vehicle);
    _loadMovers(vehicle);
  }

  Future<void> _book() async {
    final booking = context.read<MoveBookingCubit>();
    final planState = context.read<MovePlanCubit>().state;
    final mover = booking.state.selectedMover;
    if (mover == null) return;
    final booked = await booking.bookSelected(
      planState.estimate.quoteFor(mover),
    );
    if (!mounted) return;
    if (!booked) {
      showAppSnackBar(context, booking.state.errorMessage!, isError: true);
      return;
    }
    context.read<MoveTasksCubit>().completeMatching('Book movers');
    showAppSnackBar(
      context,
      '${mover.name} booked for '
      '${Formatters.shortDate(planState.plan.date)}. Price locked in.',
    );
    context.go(AppRoutes.tracking);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final planState = context.watch<MovePlanCubit>().state;
    final booking = context.watch<MoveBookingCubit>().state;
    final estimate = planState.estimate;
    final plan = planState.plan;
    final best = MoverRanking.bestValue(booking.movers, estimate);
    final selected = booking.selectedMover;

    return Scaffold(
      appBar: const ImukaAppBar(title: 'Choose movers'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: PageBody(
          children: [
            AppCard(
              color: p.muted,
              borderColor: Colors.transparent,
              radius: AppTheme.radiusMd,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.route, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${plan.routeLabel} · ${Formatters.shortDate(plan.date)}'
                      ' · ~${plan.distanceKm} km',
                      style: context.text.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PillRow(
              children: [
                for (final vehicle in VehicleType.values)
                  ChoicePill(
                    label: vehicle.label,
                    icon: LucideIcons.truck,
                    selected: planState.vehicle == vehicle,
                    onTap: () => _selectVehicle(vehicle),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (booking.moversStatus.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (booking.moversStatus == RequestStatus.failure)
              EmptyState(
                icon: LucideIcons.wifiOff,
                title: 'Couldn\'t load movers',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => _loadMovers(planState.vehicle),
              )
            else if (booking.movers.isEmpty)
              const EmptyState(
                icon: LucideIcons.truck,
                title: 'No movers for this size',
                message: 'Try another vehicle size.',
              )
            else
              for (final mover in booking.movers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MoverCard(
                    mover: mover,
                    price: estimate.quoteFor(mover),
                    itemCount: estimate.itemCount,
                    selected: mover.id == booking.selectedMoverId,
                    isBestValue: mover == best,
                    onTap: () =>
                        context.read<MoveBookingCubit>().selectMover(mover.id),
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, size: 16, color: p.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment is held until you confirm all '
                  '${estimate.itemCount} items at your new home.',
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: selected == null
                ? 'Choose a mover'
                : 'Book ${selected.name}',
            onPressed: selected == null ? null : _book,
          ),
        ],
      ),
    );
  }
}
