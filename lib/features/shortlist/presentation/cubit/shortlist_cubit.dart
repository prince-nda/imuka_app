import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/request_status.dart';
import '../../domain/repositories/shortlist_repository.dart';

class ShortlistState extends Equatable {
  const ShortlistState({
    this.ids = const [],
    this.status = RequestStatus.initial,
    this.errorMessage,
  });

  /// Saved property ids, in the order they were added.
  final List<String> ids;
  final RequestStatus status;
  final String? errorMessage;

  bool contains(String id) => ids.contains(id);

  @override
  List<Object?> get props => [ids, status, errorMessage];
}

/// Saved homes. Changes are applied optimistically so the bookmark icon and
/// the Shortlist tab update instantly, and rolled back if saving fails.
class ShortlistCubit extends Cubit<ShortlistState> {
  ShortlistCubit(this._repository) : super(const ShortlistState());

  /// The compare table has room for this many homes.
  static const maxCompare = 4;

  final ShortlistRepository _repository;

  /// Clears saved homes when the user logs out.
  void reset() => emit(const ShortlistState());

  Future<void> load() async {
    emit(ShortlistState(ids: state.ids, status: RequestStatus.loading));
    try {
      final ids = await _repository.fetchIds();
      emit(ShortlistState(ids: ids, status: RequestStatus.success));
    } catch (_) {
      emit(
        ShortlistState(
          ids: state.ids,
          status: RequestStatus.failure,
          errorMessage: 'We couldn\'t load your shortlist.',
        ),
      );
    }
  }

  /// Returns `true` when the home is now saved.
  Future<bool> toggle(String propertyId) async {
    final saved = state.contains(propertyId);
    if (!saved && state.ids.length >= maxCompare) {
      emit(
        ShortlistState(
          ids: state.ids,
          status: RequestStatus.failure,
          errorMessage:
              'You can compare up to $maxCompare homes. '
              'Remove one from your shortlist first.',
        ),
      );
      return false;
    }
    final previous = state.ids;
    final next = saved
        ? (List.of(previous)..remove(propertyId))
        : [...previous, propertyId];
    emit(ShortlistState(ids: next, status: RequestStatus.success));
    try {
      saved
          ? await _repository.remove(propertyId)
          : await _repository.add(propertyId);
      return !saved;
    } catch (_) {
      emit(
        ShortlistState(
          ids: previous,
          status: RequestStatus.failure,
          errorMessage: 'We couldn\'t update your shortlist. Try again.',
        ),
      );
      return saved;
    }
  }

  Future<void> add(String propertyId) async {
    if (!state.contains(propertyId)) await toggle(propertyId);
  }
}
