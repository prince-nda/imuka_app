import 'package:equatable/equatable.dart';

import '../../../../core/domain/rwanda_cities.dart';
import 'landmark.dart';
import 'property.dart';

/// Everything the user can set on the "Find your home" screen.
class PropertyFilter extends Equatable {
  const PropertyFilter({
    required this.landmark,
    this.from = RwandaCity.huye,
    this.to = RwandaCity.kigali,
    this.neighbourhood,
    this.type,
    this.minBudget = 100000,
    this.maxBudget = 400000,
    this.bedrooms,
    this.verifiedOnly = true,
  });

  static const budgetFloor = 0;

  /// Selecting the top of the slider means "no upper limit".
  static const budgetCeiling = 600000;
  static const budgetStep = 25000;

  /// Value of [bedrooms] that means "3 or more".
  static const bedroomsThreePlus = 3;

  final RwandaCity from;
  final RwandaCity to;
  final Landmark landmark;

  /// `null` means any neighbourhood.
  final String? neighbourhood;

  /// `null` means any property type.
  final PropertyType? type;
  final int minBudget;
  final int maxBudget;

  /// `null` means any; [bedroomsThreePlus] means 3 or more.
  final int? bedrooms;
  final bool verifiedOnly;

  bool get hasNoUpperBudget => maxBudget >= budgetCeiling;

  /// True when a listing satisfies every active criterion.
  bool matches(Property p) {
    if (p.city != to.label) return false;
    if (verifiedOnly && !p.isVerified) return false;
    if (neighbourhood != null && p.neighbourhood != neighbourhood) {
      return false;
    }
    if (type != null && p.type != type) return false;
    if (p.monthlyRent < minBudget) return false;
    if (!hasNoUpperBudget && p.monthlyRent > maxBudget) return false;
    if (bedrooms != null) {
      if (bedrooms == bedroomsThreePlus) {
        if (p.bedrooms < bedroomsThreePlus) return false;
      } else if (p.bedrooms != bedrooms) {
        return false;
      }
    }
    return true;
  }

  /// Filters [all] and sorts the matches by distance to the landmark, so the
  /// most convenient homes come first.
  List<Property> apply(Iterable<Property> all) {
    final results = all.where(matches).toList()
      ..sort((a, b) => distanceKm(a).compareTo(distanceKm(b)));
    return results;
  }

  double distanceKm(Property p) => p.location.distanceTo(landmark.location);

  /// Keeps route, landmark and verified preference but clears the
  /// narrowing filters ("show me everything in Kigali").
  PropertyFilter cleared() => PropertyFilter(
    landmark: landmark,
    from: from,
    to: to,
    minBudget: budgetFloor,
    maxBudget: budgetCeiling,
    verifiedOnly: verifiedOnly,
  );

  PropertyFilter copyWith({
    RwandaCity? from,
    RwandaCity? to,
    Landmark? landmark,
    String? Function()? neighbourhood,
    PropertyType? Function()? type,
    int? minBudget,
    int? maxBudget,
    int? Function()? bedrooms,
    bool? verifiedOnly,
  }) => PropertyFilter(
    from: from ?? this.from,
    to: to ?? this.to,
    landmark: landmark ?? this.landmark,
    neighbourhood: neighbourhood == null ? this.neighbourhood : neighbourhood(),
    type: type == null ? this.type : type(),
    minBudget: minBudget ?? this.minBudget,
    maxBudget: maxBudget ?? this.maxBudget,
    bedrooms: bedrooms == null ? this.bedrooms : bedrooms(),
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
  );

  @override
  List<Object?> get props => [
    from,
    to,
    landmark,
    neighbourhood,
    type,
    minBudget,
    maxBudget,
    bedrooms,
    verifiedOnly,
  ];
}
