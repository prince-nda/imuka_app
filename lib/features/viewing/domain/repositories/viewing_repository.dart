import '../entities/viewing_request.dart';

abstract interface class ViewingRepository {
  /// Saves the request and returns it with its new id.
  Future<ViewingRequest> requestViewing(ViewingRequest request);

  /// The user's viewings, soonest first.
  Future<List<ViewingRequest>> fetchMyViewings();

  /// Marks a viewing as cancelled (kept for the owner's records).
  Future<void> cancelViewing(String id);
}
