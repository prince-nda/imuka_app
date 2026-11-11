import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../domain/geo_point.dart';
import 'value_codec.dart';

/// [ValueCodec] using Firestore's native `Timestamp` and `GeoPoint`.
class FirestoreCodec implements ValueCodec {
  const FirestoreCodec();

  @override
  Object encodeDate(DateTime value) => fs.Timestamp.fromDate(value);

  @override
  DateTime decodeDate(Object? value) => switch (value) {
    fs.Timestamp t => t.toDate(),
    DateTime d => d,
    String s => DateTime.parse(s),
    // Server timestamps are null until the write is confirmed.
    _ => DateTime.now(),
  };

  @override
  Object encodeGeo(GeoPoint value) =>
      fs.GeoPoint(value.latitude, value.longitude);

  @override
  GeoPoint decodeGeo(Object? value) => switch (value) {
    fs.GeoPoint g => GeoPoint(g.latitude, g.longitude),
    _ => const GeoPoint(0, 0),
  };
}
