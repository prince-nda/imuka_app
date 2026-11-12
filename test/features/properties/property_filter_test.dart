import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/domain/rwanda_cities.dart';
import 'package:imuka/features/properties/data/repositories/mock_property_repository.dart';
import 'package:imuka/features/properties/domain/entities/property.dart';
import 'package:imuka/features/properties/domain/entities/property_filter.dart';
import 'package:imuka/features/properties/domain/services/compare_insights.dart';

void main() {
  late List<Property> all;
  final repository = MockPropertyRepository(latency: Duration.zero);
  final kigaliHeights = repository.landmarks.first;

  setUpAll(() async => all = await repository.fetchProperties());

  Property byId(String id) => all.firstWhere((p) => p.id == id);

  test('verified-only hides listings with pending checks', () {
    final filter = PropertyFilter(landmark: kigaliHeights).cleared();
    final results = filter.apply(all);
    expect(results, isNotEmpty);
    expect(results.every((p) => p.isVerified), isTrue);
    expect(results, isNot(contains(byId('nyamirambo-room'))));

    final everything = filter.copyWith(verifiedOnly: false).apply(all);
    expect(everything, contains(byId('nyamirambo-room')));
  });

  test('combines neighbourhood, type, budget and bedrooms', () {
    final filter = PropertyFilter(
      landmark: kigaliHeights,
      neighbourhood: 'Kacyiru',
      type: PropertyType.apartment,
      bedrooms: 2,
    );
    final results = filter.apply(all);
    expect(results.map((p) => p.id), ['kacyiru-hillside', 'kacyiru-garden']);
    // RWF 450,000 is above the 400,000 budget.
    expect(results, isNot(contains(byId('kacyiru-modern'))));
  });

  test('the top of the budget slider means no upper limit', () {
    final filter = PropertyFilter(
      landmark: kigaliHeights,
      maxBudget: PropertyFilter.budgetCeiling,
    );
    expect(filter.matches(byId('kimihurura-townhouse')), isTrue);
  });

  test('"3+" bedrooms matches 3 and more', () {
    final filter = PropertyFilter(
      landmark: kigaliHeights,
      minBudget: 0,
      maxBudget: PropertyFilter.budgetCeiling,
      bedrooms: PropertyFilter.bedroomsThreePlus,
    );
    final results = filter.apply(all);
    expect(results.every((p) => p.bedrooms >= 3), isTrue);
    expect(results, contains(byId('kimihurura-townhouse')));
  });

  test('results only include the destination city', () {
    final filter = PropertyFilter(
      landmark: kigaliHeights,
      to: RwandaCity.musanze,
    ).cleared();
    expect(filter.apply(all), isEmpty);
  });

  test('results are sorted by distance to the landmark', () {
    final results = PropertyFilter(landmark: kigaliHeights)
        .cleared()
        .apply(all);
    final distances = results
        .map((p) => p.location.distanceTo(kigaliHeights.location))
        .toList();
    expect(distances, orderedEquals([...distances]..sort()));
    expect(results.first.id, 'kacyiru-modern');
  });

  test('best match is the closest verified home (Figma: Kacyiru)', () {
    final shortlist = [
      byId('kacyiru-modern'),
      byId('kimironko-family'),
      byId('nyamirambo-room'),
    ];
    expect(
      CompareInsights.bestMatch(shortlist, kigaliHeights),
      shortlist.first,
    );
    expect(
      CompareInsights.bestMatch([byId('nyamirambo-room')], kigaliHeights),
      isNull,
    );
  });

  test('road distance matches the Figma route Huye → Kigali', () {
    expect(RwandaCity.roadDistanceKm(RwandaCity.huye, RwandaCity.kigali), 130);
    expect(RwandaCity.roadDistanceKm(RwandaCity.kigali, RwandaCity.huye), 130);
  });
}
