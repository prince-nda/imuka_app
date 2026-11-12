import 'package:equatable/equatable.dart';

import '../../../../core/domain/rwanda_cities.dart';

/// Where and when the user is moving.
class MovePlan extends Equatable {
  const MovePlan({required this.from, required this.to, required this.date});

  final RwandaCity from;
  final RwandaCity to;
  final DateTime date;

  int get distanceKm => RwandaCity.roadDistanceKm(from, to);

  /// "Huye → Kigali".
  String get routeLabel => '${from.label} → ${to.label}';

  MovePlan copyWith({RwandaCity? from, RwandaCity? to, DateTime? date}) =>
      MovePlan(
        from: from ?? this.from,
        to: to ?? this.to,
        date: date ?? this.date,
      );

  @override
  List<Object?> get props => [from, to, date];
}
