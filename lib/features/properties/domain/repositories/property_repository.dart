import '../entities/landmark.dart';
import '../entities/property.dart';

abstract interface class PropertyRepository {
  /// All published listings (verified and pending).
  Future<List<Property>> fetchProperties();

  Future<Property?> getProperty(String id);

  /// Workplaces and schools used for the "Near" field and distances.
  List<Landmark> get landmarks;

  /// Neighbourhood names offered as quick filters, most popular first.
  List<String> get popularNeighbourhoods;
}
