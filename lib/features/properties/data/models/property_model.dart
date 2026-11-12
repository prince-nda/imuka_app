import '../../../../core/data/value_codec.dart';
import '../../domain/entities/property.dart';

/// Firestore mapping for `properties/{propertyId}` and
/// `landlords/{landlordId}`.
///
/// A property stores only `landlordId` (foreign key); landlord details live
/// once in `landlords` and are joined when reading.
abstract final class PropertyModel {
  static Map<String, Object?> toMap(Property p, ValueCodec codec) => {
    'title': p.title,
    'type': p.type.name,
    'neighbourhood': p.neighbourhood,
    'district': p.district,
    'city': p.city,
    'street': p.street,
    'monthlyRent': p.monthlyRent,
    'rating': p.rating,
    'reviewCount': p.reviewCount,
    'bedrooms': p.bedrooms,
    'bathrooms': p.bathrooms,
    'sizeSqm': p.sizeSqm,
    'furnishing': p.furnishing,
    'floor': p.floor,
    'minLeaseMonths': p.minLeaseMonths,
    'depositMonths': p.depositMonths,
    'ownMeters': p.ownMeters,
    'availableFrom': codec.encodeDate(p.availableFrom),
    'facilities': [for (final f in p.facilities) f.name],
    'location': codec.encodeGeo(p.location),
    'transitNote': p.transitNote,
    'imageAsset': p.imageAsset,
    'landlordId': p.owner.id,
    'ownerIdentityVerified': p.checks.ownerIdentity,
    'ownershipDocumentVerified': p.checks.ownershipDocument,
    'onSiteVerified': p.checks.onSiteCheck,
    'lastCheckedAt': p.checks.lastCheckedOn == null
        ? null
        : codec.encodeDate(p.checks.lastCheckedOn!),
  };

  static Property fromMap(
    String id,
    Map<String, Object?> m,
    PropertyOwner owner,
    ValueCodec codec,
  ) => Property(
    id: id,
    title: m['title'] as String? ?? '',
    type: enumByName(PropertyType.values, m['type'], PropertyType.apartment),
    neighbourhood: m['neighbourhood'] as String? ?? '',
    district: m['district'] as String? ?? '',
    city: m['city'] as String? ?? '',
    street: m['street'] as String? ?? '',
    monthlyRent: readInt(m['monthlyRent']),
    rating: readDouble(m['rating']),
    reviewCount: readInt(m['reviewCount']),
    bedrooms: readInt(m['bedrooms']),
    bathrooms: readInt(m['bathrooms']),
    sizeSqm: readInt(m['sizeSqm']),
    furnishing: m['furnishing'] as String? ?? '',
    floor: m['floor'] as String? ?? '',
    minLeaseMonths: readInt(m['minLeaseMonths']),
    depositMonths: readDouble(m['depositMonths'], 1),
    ownMeters: m['ownMeters'] as bool? ?? false,
    availableFrom: codec.decodeDate(m['availableFrom']),
    facilities: [
      for (final name in (m['facilities'] as List?) ?? const [])
        ?Facility.values.asNameMap()[name],
    ],
    location: codec.decodeGeo(m['location']),
    transitNote: m['transitNote'] as String? ?? '',
    imageAsset: m['imageAsset'] as String? ?? '',
    owner: owner,
    checks: VerificationChecks(
      ownerIdentity: m['ownerIdentityVerified'] as bool? ?? false,
      ownershipDocument: m['ownershipDocumentVerified'] as bool? ?? false,
      onSiteCheck: m['onSiteVerified'] as bool? ?? false,
      lastCheckedOn: m['lastCheckedAt'] == null
          ? null
          : codec.decodeDate(m['lastCheckedAt']),
    ),
  );

  static Map<String, Object?> landlordToMap(PropertyOwner o) => {
    'name': o.name,
    'phone': o.phone,
    'typicalReplyMinutes': o.typicalReplyMinutes,
    'idVerified': o.idVerified,
  };

  static PropertyOwner landlordFromMap(String id, Map<String, Object?> m) =>
      PropertyOwner(
        id: id,
        name: m['name'] as String? ?? 'Owner',
        phone: m['phone'] as String? ?? '',
        typicalReplyMinutes: readInt(m['typicalReplyMinutes'], 30),
        idVerified: m['idVerified'] as bool? ?? false,
      );

  /// Placeholder when a landlord document is missing.
  static PropertyOwner unknownLandlord(String id) => PropertyOwner(
    id: id,
    name: 'Owner',
    phone: '',
    typicalReplyMinutes: 60,
    idVerified: false,
  );
}
