import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A latitude / longitude pair.
class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  static const _earthRadiusKm = 6371.0;

  /// Straight-line (great-circle) distance in kilometres, using the
  /// haversine formula.
  double distanceTo(GeoPoint other) {
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) *
            math.cos(rad(other.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }

  @override
  List<Object?> get props => [latitude, longitude];
}
