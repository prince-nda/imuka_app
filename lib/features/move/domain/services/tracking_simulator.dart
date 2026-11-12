import 'dart:math' as math;

import '../entities/move_plan.dart';
import '../entities/tracking_update.dart';

/// Simulated truck position used until movers share live GPS.
///
/// Starts part-way through the trip (as in the Figma: 42 km left) and moves
/// the truck a little on every tick until it arrives.
Stream<TrackingUpdate> simulateTracking(
  MovePlan plan, {
  Duration tick = const Duration(seconds: 1),
  double step = 0.015,
}) async* {
  const averageKmh = 66;
  final total = plan.distanceKm;
  var progress = total <= 42 ? 0.15 : 1 - 42 / total;

  TrackingUpdate update(double p) {
    final kmLeft = ((1 - p) * total).round();
    return TrackingUpdate(
      progress: p,
      kmLeft: kmLeft,
      etaMinutes: (kmLeft / averageKmh * 60).round(),
      stage: p >= 1 ? TrackingStage.arrived : TrackingStage.onTheRoad,
    );
  }

  yield update(progress);
  while (progress < 1) {
    await Future<void>.delayed(tick);
    progress = math.min(1, progress + step);
    yield update(progress);
  }
}
