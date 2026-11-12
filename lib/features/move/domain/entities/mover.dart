import 'package:equatable/equatable.dart';

/// Vehicle sizes offered by movers, with the transport pricing used by the
/// cost calculator: `baseFee + perKm × distance`.
enum VehicleType {
  pickup('Pickup', 15000, 200),
  smallTruck('Small truck', 21000, 300),
  largeTruck('Large truck', 35000, 450);

  const VehicleType(this.label, this.baseFee, this.perKm);
  final String label;
  final int baseFee;
  final int perKm;
}

/// A verified moving company.
class Mover extends Equatable {
  const Mover({
    required this.id,
    required this.name,
    required this.rating,
    required this.completedMoves,
    required this.loaders,
    required this.vehicleType,
    required this.vehicleLabel,
    required this.driverName,
    required this.plateNumber,
    this.priceAdjustment = 0,
    this.insured = false,
    this.packingIncluded = false,
    this.verified = true,
  });

  final String id;
  final String name;
  final double rating;
  final int completedMoves;
  final int loaders;
  final VehicleType vehicleType;

  /// e.g. "3 t truck".
  final String vehicleLabel;
  final String driverName;
  final String plateNumber;

  /// Difference between this mover's locked-in quote and Imuka's standard
  /// estimate (negative = cheaper). Shown as its own line, never hidden.
  final int priceAdjustment;
  final bool insured;
  final bool packingIncluded;
  final bool verified;

  /// "112 moves · 2 loaders · insured · 3 t truck".
  String get summary => [
    '$completedMoves moves',
    '$loaders loaders',
    if (insured) 'insured',
    if (packingIncluded) 'packing included' else vehicleLabel,
  ].join(' · ');

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    completedMoves,
    loaders,
    vehicleType,
    vehicleLabel,
    driverName,
    plateNumber,
    priceAdjustment,
    insured,
    packingIncluded,
    verified,
  ];
}
