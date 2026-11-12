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
import '../../../../core/widgets/imuka_app_bar.dart';
import '../../../../core/widgets/map_canvas.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/tracking_update.dart';
import '../../domain/repositories/move_repositories.dart';
import '../cubit/move_booking_cubit.dart';
import '../cubit/move_plan_cubit.dart';
import '../cubit/tracking_cubit.dart';
import '../widgets/move_widgets.dart';

/// Live map of the truck with ETA, driver contact and delivery status.
class LiveTrackingPage extends StatelessWidget {
  const LiveTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mover = context.select((MoveBookingCubit c) => c.state.bookedMover);
    final plan = context.select((MovePlanCubit c) => c.state.plan);
    if (mover == null) {
      return Scaffold(
        appBar: const ImukaAppBar(title: 'Track your move'),
        body: EmptyState(
          icon: LucideIcons.truck,
          title: 'No mover booked yet',
          message: 'Book a verified mover to follow your truck live.',
          actionLabel: 'Choose movers',
          onAction: () => context.pushReplacement(AppRoutes.movers),
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          TrackingCubit(context.read<MoverRepository>())
            ..start(mover: mover, plan: plan),
      child: _TrackingView(mover: mover, plan: plan),
    );
  }
}

class _TrackingView extends StatelessWidget {
  const _TrackingView({required this.mover, required this.plan});

  final Mover mover;
  final MovePlan plan;

  @override
  Widget build(BuildContext context) {
    final update = context.watch<TrackingCubit>().state;
    final progress = update?.progress ?? 0;
    final map = _TrackingMap(progress: progress, plan: plan);
    final panel = _StatusPanel(mover: mover, update: update);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Landscape: map and panel side by side, both fully visible.
          if (constraints.maxWidth > constraints.maxHeight) {
            return Row(
              children: [
                Expanded(child: map),
                SizedBox(
                  width: (constraints.maxWidth * 0.45).clamp(320, 440),
                  child: SafeArea(left: false, child: panel),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: map),
              panel,
            ],
          );
        },
      ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.progress, required this.plan});

  final double progress;
  final MovePlan plan;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label:
          'Map: truck ${(progress * 100).round()}% of the way from '
          '${plan.from.label} to ${plan.to.label}',
      child: CityBlocksMap(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            Offset at(Offset f) =>
                Offset(f.dx * size.width, f.dy * size.height);
            return TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (context, animated, _) {
                final truck = RoutePainter.pointAt(size, animated);
                return Stack(
                  children: [
                    CustomPaint(
                      size: size,
                      painter: RoutePainter(
                        progress: animated,
                        travelled: p.success,
                        remaining: p.textSecondary,
                      ),
                    ),
                    ..._endpoint(
                      context,
                      size,
                      at(RoutePainter.start),
                      plan.from.label,
                    ),
                    ..._endpoint(
                      context,
                      size,
                      at(RoutePainter.end),
                      'New home, ${plan.to.label}',
                      isDestination: true,
                    ),
                    Positioned(
                      left: truck.dx - 36,
                      top: truck.dy - 36,
                      child: const _PulsingTruck(),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleIconButton(
                              icon: LucideIcons.chevronLeft,
                              tooltip: 'Back',
                              showBorder: false,
                              onPressed: () => context.canPop()
                                  ? context.pop()
                                  : context.go(AppRoutes.move),
                            ),
                            const Spacer(),
                            const _LivePill(),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Pickup (white dot) or destination (black dot) with its label: to the
  /// right of the pickup, and below-left of the destination so it stays on
  /// screen.
  List<Widget> _endpoint(
    BuildContext context,
    Size size,
    Offset at,
    String label, {
    bool isDestination = false,
  }) {
    final p = context.palette;
    final badge = StatusBadge(
      label: label,
      tone: BadgeTone.neutral,
      compact: true,
    );
    return [
      Positioned(
        left: at.dx - 11,
        top: at.dy - 11,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDestination ? p.ink : p.card,
            shape: BoxShape.circle,
            border: Border.all(color: isDestination ? p.card : p.ink, width: 4),
          ),
        ),
      ),
      if (isDestination)
        Positioned(right: size.width - at.dx + 4, top: at.dy + 14, child: badge)
      else
        Positioned(left: at.dx + 18, top: at.dy - 12, child: badge),
    ];
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: context.text.labelSmall?.copyWith(color: p.onInk),
          ),
        ],
      ),
    );
  }
}

/// Truck marker with a soft green halo that pulses continuously.
class _PulsingTruck extends StatefulWidget {
  const _PulsingTruck();

  @override
  State<_PulsingTruck> createState() => _PulsingTruckState();
}

/// Owns only the animation controller (no setState).
class _PulsingTruckState extends State<_PulsingTruck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 48 + 24 * _pulse.value,
              height: 48 + 24 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.success.withValues(alpha: 0.28 * (1 - _pulse.value)),
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.ink,
              shape: BoxShape.circle,
              border: Border.all(color: p.card, width: 3),
            ),
            child: Icon(LucideIcons.truck, color: p.onInk, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.mover, required this.update});

  final Mover mover;
  final TrackingUpdate? update;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final itemCount = context.select((MovePlanCubit c) => c.state.items.length);
    final arrived = update?.stage == TrackingStage.arrived;
    final title = update == null
        ? 'Connecting to truck…'
        : arrived
        ? 'Your movers have arrived'
        : 'Arriving in ${update!.etaMinutes} min';

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            22,
            AppTheme.pagePadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(title, style: context.text.headlineSmall),
                        ),
                        if (update != null)
                          Text(
                            arrived
                                ? '${mover.name} · at your new home'
                                : '${update!.kmLeft} km left · ${mover.name}',
                            style: context.text.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: '$itemCount items',
                    icon: LucideIcons.package,
                    tone: BadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DeliveryStepper(stage: update?.stage ?? TrackingStage.loaded),
              const SizedBox(height: 18),
              _DriverCard(mover: mover),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.shieldCheck, size: 16, color: p.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your items are on board. Payment is released only '
                      'after you confirm them.',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Movers arrived — check my items',
                onPressed: () {
                  context.read<MoveBookingCubit>().startMovingDay();
                  context.push(AppRoutes.checkItems);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.mover});

  final Mover mover;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: p.ink,
            child: Text(
              Formatters.initials(mover.driverName),
              style: context.text.titleSmall?.copyWith(color: p.onInk),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mover.driverName, style: context.text.titleSmall),
                Text(
                  '${mover.vehicleLabel} · ${mover.plateNumber}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: LucideIcons.phone,
            tooltip: 'Call ${mover.driverName}',
            onPressed: () =>
                showAppSnackBar(context, 'Calling ${mover.driverName}…'),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: LucideIcons.messageSquare,
            tooltip: 'Message ${mover.driverName}',
            onPressed: () => showAppSnackBar(
              context,
              'Chat with ${mover.driverName} opens here.',
            ),
          ),
        ],
      ),
    );
  }
}
