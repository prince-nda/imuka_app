import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/rwanda_cities.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/landmark.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_filter.dart';
import '../../domain/repositories/property_repository.dart';

class PropertySearchState extends Equatable {
  const PropertySearchState({
    required this.filter,
    required this.landmarks,
    required this.neighbourhoods,
    this.status = RequestStatus.initial,
    this.all = const [],
    this.results = const [],
  });

  final PropertyFilter filter;
  final List<Landmark> landmarks;
  final List<String> neighbourhoods;
  final RequestStatus status;

  /// Every listing loaded from the repository.
  final List<Property> all;

  /// Listings matching [filter], closest to the landmark first.
  final List<Property> results;

  /// Verified listings in the destination, for "Verified homes near you".
  List<Property> get verifiedNearby =>
      filter.cleared().copyWith(verifiedOnly: true).apply(all);

  Property? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  PropertySearchState copyWith({
    PropertyFilter? filter,
    RequestStatus? status,
    List<Property>? all,
  }) {
    final nextFilter = filter ?? this.filter;
    final nextAll = all ?? this.all;
    return PropertySearchState(
      filter: nextFilter,
      landmarks: landmarks,
      neighbourhoods: neighbourhoods,
      status: status ?? this.status,
      all: nextAll,
      results: nextFilter.apply(nextAll),
    );
  }

  @override
  List<Object?> get props => [
    filter,
    landmarks,
    neighbourhoods,
    status,
    all,
    results,
  ];
}

/// Owns the search filters shared by Home, Find your home and the results
/// list; results are recomputed instantly on every filter change.
class PropertySearchCubit extends Cubit<PropertySearchState> {
  PropertySearchCubit(this._repository, {bool verifiedOnly = true})
    : super(
        PropertySearchState(
          filter: PropertyFilter(
            landmark: _repository.landmarks.first,
            neighbourhood: 'Kacyiru',
            type: PropertyType.apartment,
            bedrooms: 2,
            verifiedOnly: verifiedOnly,
          ),
          landmarks: _repository.landmarks,
          neighbourhoods: _repository.popularNeighbourhoods,
        ),
      );

  final PropertyRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final properties = await _repository.fetchProperties();
      emit(state.copyWith(status: RequestStatus.success, all: properties));
    } catch (_) {
      emit(state.copyWith(status: RequestStatus.failure));
    }
  }

  void _filter(PropertyFilter Function(PropertyFilter f) update) =>
      emit(state.copyWith(filter: update(state.filter)));

  void setFrom(RwandaCity city) => _filter((f) => f.copyWith(from: city));

  void setTo(RwandaCity city) => _filter((f) => f.copyWith(to: city));

  void swapRoute() => _filter((f) => f.copyWith(from: f.to, to: f.from));

  void setLandmark(Landmark landmark) =>
      _filter((f) => f.copyWith(landmark: landmark));

  /// `null` selects "Any".
  void setNeighbourhood(String? name) =>
      _filter((f) => f.copyWith(neighbourhood: () => name));

  /// Tapping the selected type again clears it.
  void toggleType(PropertyType type) =>
      _filter((f) => f.copyWith(type: () => f.type == type ? null : type));

  void setBudget(int min, int max) =>
      _filter((f) => f.copyWith(minBudget: min, maxBudget: max));

  void setBedrooms(int? bedrooms) =>
      _filter((f) => f.copyWith(bedrooms: () => bedrooms));

  void setVerifiedOnly(bool value) =>
      _filter((f) => f.copyWith(verifiedOnly: value));

  /// Used by "Find homes" and "See all" on Home: everything in the
  /// destination city.
  void showAllInDestination() => _filter((f) => f.cleared());

  /// Quick filter from the "Popular in Kigali" chips.
  void showNeighbourhood(String name) =>
      _filter((f) => f.cleared().copyWith(neighbourhood: () => name));
}
