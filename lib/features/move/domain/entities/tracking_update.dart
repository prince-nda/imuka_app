import 'package:equatable/equatable.dart';

enum TrackingStage {
  loaded('Loaded'),
  onTheRoad('On the road'),
  arrived('Arrived');

  const TrackingStage(this.label);
  final String label;
}

/// A live position update for the truck.
class TrackingUpdate extends Equatable {
  const TrackingUpdate({
    required this.progress,
    required this.kmLeft,
    required this.etaMinutes,
    required this.stage,
  });

  /// 0 = at pickup, 1 = at the new home.
  final double progress;
  final int kmLeft;
  final int etaMinutes;
  final TrackingStage stage;

  @override
  List<Object?> get props => [progress, kmLeft, etaMinutes, stage];
}
