import '../entities/landmark.dart';
import '../entities/property.dart';

/// Picks the "Best match" in the compare table.
abstract final class CompareInsights {
  /// Among verified listings, the best match is the one closest to the
  /// user's workplace or school; rent breaks ties. Unverified listings are
  /// never recommended, which is the trust rule users asked for.
  static Property? bestMatch(List<Property> properties, Landmark landmark) {
    final verified = properties.where((p) => p.isVerified).toList();
    if (verified.isEmpty) return null;
    double distance(Property p) => p.location.distanceTo(landmark.location);
    verified.sort((a, b) {
      final byDistance = distance(a).compareTo(distance(b));
      return byDistance != 0
          ? byDistance
          : a.monthlyRent.compareTo(b.monthlyRent);
    });
    return verified.first;
  }
}
