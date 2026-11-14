import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/safe_emit.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/viewing_request.dart';
import '../../domain/repositories/viewing_repository.dart';

class MyViewingsState extends Equatable {
  const MyViewingsState({
    this.viewings = const [],
    this.status = RequestStatus.initial,
    this.errorMessage,
  });

  final List<ViewingRequest> viewings;
  final RequestStatus status;
  final String? errorMessage;

  MyViewingsState copyWith({
    List<ViewingRequest>? viewings,
    RequestStatus? status,
    String? errorMessage,
  }) => MyViewingsState(
    viewings: viewings ?? this.viewings,
    status: status ?? this.status,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [viewings, status, errorMessage];
}

/// The user's viewing requests, with cancellation.
class MyViewingsCubit extends Cubit<MyViewingsState>
    with SafeEmit<MyViewingsState> {
  MyViewingsCubit(this._repository) : super(const MyViewingsState());

  final ViewingRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final viewings = await _repository.fetchMyViewings();
      emit(state.copyWith(viewings: viewings, status: RequestStatus.success));
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          errorMessage: 'We couldn\'t load your viewings.',
        ),
      );
    }
  }

  /// Optimistically marks the viewing cancelled; rolls back on failure.
  Future<void> cancel(String id) async {
    final previous = state.viewings;
    emit(
      state.copyWith(
        viewings: [
          for (final v in previous)
            v.id == id ? v.copyWith(status: ViewingStatus.cancelled) : v,
        ],
      ),
    );
    try {
      await _repository.cancelViewing(id);
    } catch (_) {
      emit(
        state.copyWith(
          viewings: previous,
          errorMessage: 'We couldn\'t cancel that viewing. Try again.',
        ),
      );
    }
  }
}
