import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/badges.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/layout.dart';
import '../cubit/move_booking_cubit.dart';
import '../cubit/move_plan_cubit.dart';
import '../cubit/move_tasks_cubit.dart';

/// My Move tab: overview of the move and entry point to every step.
class MyMovePage extends StatelessWidget {
  const MyMovePage({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final cubit = context.read<MovePlanCubit>();
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: cubit.state.plan.date.isBefore(today)
          ? today
          : cubit.state.plan.date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Choose your moving day',
    );
    if (picked != null) cubit.setDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final plan = context.select((MovePlanCubit c) => c.state.plan);
    final estimate = context.select((MovePlanCubit c) => c.state.estimate);
    final booking = context.watch<MoveBookingCubit>().state;
    final tasks = context.watch<MoveTasksCubit>().state;
    final stage = booking.stage;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageBody(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            12,
            AppTheme.pagePadding,
            24,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'My move',
                          style: context.text.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _pickDate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${plan.routeLabel} · '
                                  '${Formatters.longDate(plan.date)} · '
                                  '~${plan.distanceKm} km',
                                  style: context.text.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.pencil,
                                size: 13,
                                color: p.textSecondary,
                                semanticLabel: 'Change moving date',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: LucideIcons.calendar,
                  tooltip: 'Change moving date',
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _TruckIllustration(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text('Your move', style: context.text.titleSmall),
                ),
                Text(
                  stage == MoveStage.completed
                      ? 'Complete'
                      : 'Step ${stage.step} of ${MoveStage.totalSteps}',
                  style: context.text.labelMedium?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressLine(value: stage.step / MoveStage.totalSteps),
            const SizedBox(height: 18),
            NavListTile(
              icon: LucideIcons.clipboardCheck,
              title: 'My items',
              subtitle: estimate.isEmpty
                  ? 'Add what you are moving to get a price'
                  : '${estimate.itemCount} items · est. '
                        '${Formatters.rwf(estimate.total)}',
              onTap: () => context.push(AppRoutes.moveItems),
            ),
            const SizedBox(height: 10),
            NavListTile(
              icon: LucideIcons.truck,
              title: 'Movers',
              subtitle: booking.bookedMover != null
                  ? 'Booked: ${booking.bookedMover!.name}'
                  : 'Compare verified movers for ${plan.routeLabel}',
              trailing: booking.bookedMover != null
                  ? const StatusBadge(
                      label: 'Booked',
                      tone: BadgeTone.success,
                      compact: true,
                    )
                  : null,
              onTap: () => context.push(
                estimate.isEmpty ? AppRoutes.moveItems : AppRoutes.movers,
              ),
            ),
            const SizedBox(height: 10),
            NavListTile(
              icon: LucideIcons.navigation,
              title: 'Track your move',
              subtitle: 'Live location of your movers',
              onTap: () {
                if (booking.bookedMover == null) {
                  showAppSnackBar(
                    context,
                    'Book a mover first to track your move.',
                    isError: true,
                    action: SnackBarAction(
                      label: 'Choose',
                      onPressed: () => context.push(AppRoutes.movers),
                    ),
                  );
                  return;
                }
                context.push(
                  stage == MoveStage.completed
                      ? AppRoutes.moveComplete
                      : AppRoutes.tracking,
                );
              },
            ),
            const SizedBox(height: 10),
            NavListTile(
              icon: LucideIcons.listChecks,
              title: 'Move tasks',
              subtitle:
                  '${tasks.doneCount} of ${tasks.tasks.length} tasks done',
              onTap: () => context.push(AppRoutes.moveTasks),
            ),
          ],
        ),
      ),
    );
  }
}

/// The truck illustration from the Figma file, sliding in on first build.
class _TruckIllustration extends StatelessWidget {
  const _TruckIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2EE),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -40, end: 0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, dx, child) =>
            Transform.translate(offset: Offset(dx, 0), child: child),
        child: Image.asset(
          'assets/images/move_truck.png',
          fit: BoxFit.contain,
          semanticLabel: 'Moving truck loaded with boxes',
        ),
      ),
    );
  }
}
