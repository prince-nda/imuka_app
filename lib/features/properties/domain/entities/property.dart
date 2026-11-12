import 'package:equatable/equatable.dart';

import '../../../../core/domain/geo_point.dart';

enum PropertyType {
  apartment('Apartment'),
  house('House'),
  studio('Studio'),
  room('Room');

  const PropertyType(this.label);
  final String label;
}

enum Facility {
  water('Water'),
  wifi('Wi-Fi'),
  security('Security'),
  parking('Parking'),
  backupPower('Backup power');

  const Facility(this.label);
  final String label;
}

/// The three checks Imuka runs before a listing goes live.
class VerificationChecks extends Equatable {
  const VerificationChecks({
    required this.ownerIdentity,
    required this.ownershipDocument,
    required this.onSiteCheck,
    this.lastCheckedOn,
  });

  final bool ownerIdentity;
  final bool ownershipDocument;
  final bool onSiteCheck;
  final DateTime? lastCheckedOn;

  /// A listing only shows the green "Verified" badge when all checks passed.
  bool get isVerified => ownerIdentity && ownershipDocument && onSiteCheck;

  @override
  List<Object?> get props => [
    ownerIdentity,
    ownershipDocument,
    onSiteCheck,
    lastCheckedOn,
  ];
}

class PropertyOwner extends Equatable {
  const PropertyOwner({
    required this.id,
    required this.name,
    required this.phone,
    required this.typicalReplyMinutes,
    required this.idVerified,
  });

  final String id;
  final String name;
  final String phone;
  final int typicalReplyMinutes;
  final bool idVerified;

  @override
  List<Object?> get props => [id, name, phone, typicalReplyMinutes, idVerified];
}

/// A rental listing.
class Property extends Equatable {
  const Property({
    required this.id,
    required this.title,
    required this.type,
    required this.neighbourhood,
    required this.district,
    required this.city,
    required this.street,
    required this.monthlyRent,
    required this.rating,
    required this.reviewCount,
    required this.bedrooms,
    required this.bathrooms,
    required this.sizeSqm,
    required this.furnishing,
    required this.floor,
    required this.minLeaseMonths,
    required this.depositMonths,
    required this.ownMeters,
    required this.availableFrom,
    required this.facilities,
    required this.location,
    required this.transitNote,
    required this.imageAsset,
    required this.owner,
    required this.checks,
  });

  final String id;
  final String title;
  final PropertyType type;
  final String neighbourhood;
  final String district;
  final String city;
  final String street;
  final int monthlyRent;
  final double rating;
  final int reviewCount;
  final int bedrooms;

  /// 0 means a shared bathroom.
  final int bathrooms;
  final int sizeSqm;
  final String furnishing;
  final String floor;
  final int minLeaseMonths;

  /// Deposit expressed in months of rent (0.5 = two weeks).
  final double depositMonths;

  /// Whether the unit has its own Cash Power and water meters.
  final bool ownMeters;
  final DateTime availableFrom;
  final List<Facility> facilities;
  final GeoPoint location;

  /// e.g. "~6 min by moto · bus stop 150 m away".
  final String transitNote;
  final String imageAsset;
  final PropertyOwner owner;
  final VerificationChecks checks;

  bool get isVerified => checks.isVerified;

  bool get sharedBathroom => bathrooms == 0;

  int get depositAmount => (monthlyRent * depositMonths).round();

  /// "Apartment · Kacyiru, Gasabo".
  String get subtitle => '${type.label} · $neighbourhood, $district';

  /// "KG 7 Ave, Kacyiru, Gasabo, Kigali".
  String get fullAddress => '$street, $neighbourhood, $district, $city';

  String get depositLabel {
    if (depositMonths == 0.5) return '2 weeks';
    if (depositMonths == 1) return '1 month';
    return '${depositMonths.toStringAsFixed(0)} months';
  }

  @override
  List<Object?> get props => [id, title, monthlyRent, checks];
}
