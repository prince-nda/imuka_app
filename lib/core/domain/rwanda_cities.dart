import 'geo_point.dart';

/// Towns users can move between, with their province label for display.
enum RwandaCity {
  kigali('Kigali', 'Kigali City', GeoPoint(-1.9441, 30.0619)),
  huye('Huye', 'Southern Province', GeoPoint(-2.5967, 29.7394)),
  musanze('Musanze', 'Northern Province', GeoPoint(-1.4996, 29.6344)),
  rubavu('Rubavu', 'Western Province', GeoPoint(-1.6797, 29.2606)),
  muhanga('Muhanga', 'Southern Province', GeoPoint(-2.0845, 29.7564)),
  rwamagana('Rwamagana', 'Eastern Province', GeoPoint(-1.9487, 30.4347)),
  nyagatare('Nyagatare', 'Eastern Province', GeoPoint(-1.2990, 30.3270)),
  rusizi('Rusizi', 'Western Province', GeoPoint(-2.4846, 28.9075));

  const RwandaCity(this.label, this.province, this.location);

  final String label;
  final String province;
  final GeoPoint location;

  /// "Huye, Southern Province" / "Kigali City".
  String get longLabel => this == kigali ? province : '$label, $province';

  /// Approximate road distance in km between two towns.
  ///
  /// Known routes to Kigali use measured road distances; anything else falls
  /// back to the straight-line distance multiplied by a winding-road factor.
  static int roadDistanceKm(RwandaCity from, RwandaCity to) {
    if (from == to) return 15; // a move within the same town
    final other = from == kigali ? to : (to == kigali ? from : null);
    if (other != null && _roadKmToKigali.containsKey(other)) {
      return _roadKmToKigali[other]!;
    }
    return (from.location.distanceTo(to.location) * _windingFactor).round();
  }

  static const _windingFactor = 1.5;

  static const _roadKmToKigali = {
    huye: 130,
    musanze: 95,
    rubavu: 155,
    muhanga: 50,
    rwamagana: 55,
    nyagatare: 165,
    rusizi: 270,
  };
}
