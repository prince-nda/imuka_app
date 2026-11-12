import '../entities/cost_estimate.dart';
import '../entities/move_item.dart';
import '../entities/mover.dart';

/// Turns the item list and route into an itemised [CostEstimate].
///
/// Transport = vehicle base fee + per-km rate × road distance.
/// Loaders cost a flat [loaderFee] each. With the Figma items, a small truck
/// and Huye → Kigali (130 km) this gives RWF 220,000.
class MoveCostCalculator {
  const MoveCostCalculator({this.loaderFee = 10000, this.defaultLoaders = 2});

  final int loaderFee;
  final int defaultLoaders;

  CostEstimate estimate({
    required List<MoveItem> items,
    required int distanceKm,
    required VehicleType vehicle,
    int? loaders,
  }) {
    final crew = loaders ?? defaultLoaders;
    final lines = [
      for (final item in items)
        CostLine('${item.name} ×${item.quantity}', item.total),
    ];
    final itemsTotal = items.fold<int>(0, (sum, item) => sum + item.total);
    final transport = items.isEmpty
        ? 0
        : vehicle.baseFee + vehicle.perKm * distanceKm;
    return CostEstimate(
      itemLines: lines,
      itemsTotal: itemsTotal,
      itemCount: items.length,
      transportFee: transport,
      distanceKm: distanceKm,
      loaders: items.isEmpty ? 0 : crew,
      loadersFee: items.isEmpty ? 0 : crew * loaderFee,
    );
  }
}

/// Picks the "Best value" mover.
abstract final class MoverRanking {
  /// Each rating star is worth RWF 100,000 of value; the best value mover
  /// has the highest `rating × 100,000 − quote`. This rewards a much better
  /// rated mover even when it is slightly more expensive, but not a small
  /// rating gain at a big price jump.
  static Mover? bestValue(List<Mover> movers, CostEstimate estimate) {
    if (movers.isEmpty) return null;
    double score(Mover m) => m.rating * 100000 - estimate.quoteFor(m);
    return movers.reduce((a, b) => score(b) > score(a) ? b : a);
  }
}
