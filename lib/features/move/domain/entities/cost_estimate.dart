import 'package:equatable/equatable.dart';

import 'mover.dart';

class CostLine extends Equatable {
  const CostLine(this.label, this.amount);

  final String label;
  final int amount;

  @override
  List<Object?> get props => [label, amount];
}

/// Itemised, upfront moving cost: one line per item, then transport and
/// loaders. Nothing is added later — that's the "no hidden fees" promise.
class CostEstimate extends Equatable {
  const CostEstimate({
    required this.itemLines,
    required this.itemsTotal,
    required this.itemCount,
    required this.transportFee,
    required this.distanceKm,
    required this.loaders,
    required this.loadersFee,
  });

  final List<CostLine> itemLines;
  final int itemsTotal;

  /// Number of item lines (12 boxes count as one line, as in the Figma).
  final int itemCount;
  final int transportFee;
  final int distanceKm;
  final int loaders;
  final int loadersFee;

  int get total => itemsTotal + transportFee + loadersFee;

  /// A mover's locked-in quote for this move.
  int quoteFor(Mover mover) => total + mover.priceAdjustment;

  bool get isEmpty => itemCount == 0;

  @override
  List<Object?> get props => [
    itemLines,
    itemsTotal,
    itemCount,
    transportFee,
    distanceKm,
    loaders,
    loadersFee,
  ];
}
