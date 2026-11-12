import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';

/// A workplace or school users want to live close to.
class Landmark extends Equatable {
  const Landmark({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
  });

  final String id;
  final String name;

  /// e.g. "KG 7 Ave, Kacyiru · Kigali".
  final String address;
  final GeoPoint location;

  /// "Kigali Heights, KG 7 Ave".
  String get shortLabel => '$name, ${address.split(',').first}';

  @override
  List<Object?> get props => [id, name, address, location];
}
