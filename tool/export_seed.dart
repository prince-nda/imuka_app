// Exports the catalogue (properties, landlords, movers) to
// tool/seed/seed_data.json using the same models the app reads with.
//
//   dart run tool/export_seed.dart
//   node tool/seed_firestore.mjs
import 'dart:convert';
import 'dart:io';

import 'package:imuka/core/data/value_codec.dart';
import 'package:imuka/core/domain/geo_point.dart';
import 'package:imuka/features/move/data/models/move_models.dart';
import 'package:imuka/features/move/data/repositories/mock_move_repositories.dart';
import 'package:imuka/features/properties/data/models/property_model.dart';
import 'package:imuka/features/properties/data/repositories/mock_property_repository.dart';

/// Tags dates and coordinates so the uploader can send native Firestore
/// types (`timestampValue`, `geoPointValue`).
class _JsonCodec implements ValueCodec {
  const _JsonCodec();

  @override
  Object encodeDate(DateTime value) => {
    '__timestamp': value.toUtc().toIso8601String(),
  };

  @override
  DateTime decodeDate(Object? value) => throw UnimplementedError();

  @override
  Object encodeGeo(GeoPoint value) => {
    '__geo': [value.latitude, value.longitude],
  };

  @override
  GeoPoint decodeGeo(Object? value) => throw UnimplementedError();
}

/// JSON loses the int/double distinction (4.0 → 4); tag doubles.
Object? _tagDoubles(Object? value) => switch (value) {
  double d => {'__double': d},
  Map<String, Object?> m => {
    for (final e in m.entries)
      e.key: e.key.startsWith('__') ? e.value : _tagDoubles(e.value),
  },
  List<Object?> l => [for (final v in l) _tagDoubles(v)],
  _ => value,
};

void main() {
  const codec = _JsonCodec();
  final properties = MockPropertyRepository.catalogue;
  final landlords = {for (final p in properties) p.owner.id: p.owner};

  final seed = {
    'landlords': {
      for (final o in landlords.values)
        o.id: _tagDoubles(PropertyModel.landlordToMap(o)),
    },
    'properties': {
      for (final p in properties)
        p.id: _tagDoubles(PropertyModel.toMap(p, codec)),
    },
    'movers': {
      for (final m in MockMoverRepository.catalogue)
        m.id: _tagDoubles(MoverModel.toMap(m)),
    },
  };

  final file = File('tool/seed/seed_data.json')..createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(seed));
  stdout.writeln(
    'Wrote ${landlords.length} landlords, ${properties.length} properties, '
    '${MockMoverRepository.catalogue.length} movers to ${file.path}',
  );
}
