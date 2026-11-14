import '../../domain/repositories/shortlist_repository.dart';

/// In-memory shortlist seeded with the three homes from the Figma compare
/// screen.
class MockShortlistRepository implements ShortlistRepository {
  MockShortlistRepository({this.latency = const Duration(milliseconds: 250)});

  final Duration latency;
  final List<String> _ids = [
    'kacyiru-modern',
    'kimironko-family',
    'nyamirambo-room',
  ];

  @override
  Future<List<String>> fetchIds() async {
    await Future<void>.delayed(latency);
    return List.of(_ids);
  }

  @override
  Future<void> add(String propertyId) async {
    await Future<void>.delayed(latency);
    if (!_ids.contains(propertyId)) _ids.add(propertyId);
  }

  @override
  Future<void> remove(String propertyId) async {
    await Future<void>.delayed(latency);
    _ids.remove(propertyId);
  }
}
