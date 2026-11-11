import '../domain/geo_point.dart';

/// Converts dates and coordinates to and from a storage format.
///
/// The app uses Firestore's `Timestamp` / `GeoPoint` ([FirestoreCodec]);
/// the seeding tool uses a JSON form. Models depend only on this interface
/// so both share exactly the same field names.
abstract interface class ValueCodec {
  Object encodeDate(DateTime value);
  DateTime decodeDate(Object? value);
  Object encodeGeo(GeoPoint value);
  GeoPoint decodeGeo(Object? value);
}

/// Reads an enum by name, falling back when the stored value is unknown.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Firestore returns numbers as `int` or `double`; normalise them.
int readInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

double readDouble(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : fallback;
