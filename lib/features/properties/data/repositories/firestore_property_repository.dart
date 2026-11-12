import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_codec.dart';
import '../../../../core/data/firestore_paths.dart';
import '../../domain/entities/landmark.dart';
import '../../domain/entities/property.dart';
import '../../domain/repositories/property_repository.dart';
import '../models/property_model.dart';
import 'mock_property_repository.dart';

/// Reads listings from `properties` and joins their `landlords`.
///
/// Listings and landlords are read-only for app users (see
/// `firestore.rules`); they are published with `tool/seed_firestore.mjs`.
class FirestorePropertyRepository implements PropertyRepository {
  FirestorePropertyRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const _codec = FirestoreCodec();

  @override
  Future<List<Property>> fetchProperties() async {
    final (landlords, properties) = await (
      _db.collection(FirestorePaths.landlords).get(),
      _db.collection(FirestorePaths.properties).get(),
    ).wait;
    final owners = {
      for (final doc in landlords.docs)
        doc.id: PropertyModel.landlordFromMap(doc.id, doc.data()),
    };
    return [
      for (final doc in properties.docs)
        _toProperty(doc.id, doc.data(), owners),
    ];
  }

  @override
  Future<Property?> getProperty(String id) async {
    final doc = await _db.doc('${FirestorePaths.properties}/$id').get();
    final data = doc.data();
    if (data == null) return null;
    final landlordId = data['landlordId'] as String? ?? '';
    final landlord = landlordId.isEmpty
        ? null
        : await _db.doc('${FirestorePaths.landlords}/$landlordId').get();
    final owner = landlord?.data() == null
        ? PropertyModel.unknownLandlord(landlordId)
        : PropertyModel.landlordFromMap(landlordId, landlord!.data()!);
    return PropertyModel.fromMap(doc.id, data, owner, _codec);
  }

  Property _toProperty(
    String id,
    Map<String, dynamic> data,
    Map<String, PropertyOwner> owners,
  ) {
    final landlordId = data['landlordId'] as String? ?? '';
    return PropertyModel.fromMap(
      id,
      data,
      owners[landlordId] ?? PropertyModel.unknownLandlord(landlordId),
      _codec,
    );
  }

  /// Landmarks and neighbourhoods are app reference data, not user data.
  @override
  List<Landmark> get landmarks => MockPropertyRepository.landmarkCatalogue;

  @override
  List<String> get popularNeighbourhoods =>
      MockPropertyRepository.neighbourhoodCatalogue;
}
