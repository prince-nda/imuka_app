import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';

class MockViewingRepository implements ViewingRepository {
  MockViewingRepository({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;
  final List<ViewingRequest> _requests = [];

  @override
  Future<ViewingRequest> requestViewing(ViewingRequest request) async {
    await Future<void>.delayed(latency);
    final saved = request.copyWith(id: 'viewing-${_requests.length + 1}');
    _requests.add(saved);
    return saved;
  }

  @override
  Future<List<ViewingRequest>> fetchMyViewings() async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(_requests);
  }

  @override
  Future<void> cancelViewing(String id) async {
    await Future<void>.delayed(latency ~/ 2);
    final i = _requests.indexWhere((r) => r.id == id);
    if (i != -1) {
      _requests[i] = _requests[i].copyWith(status: ViewingStatus.cancelled);
    }
  }
}
