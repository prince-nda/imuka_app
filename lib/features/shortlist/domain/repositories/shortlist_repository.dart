/// The user's saved listings, stored as property ids.
abstract interface class ShortlistRepository {
  Future<List<String>> fetchIds();

  Future<void> add(String propertyId);

  Future<void> remove(String propertyId);
}
