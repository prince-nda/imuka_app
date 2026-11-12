import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/request_status.dart';
import '../../domain/entities/move_task.dart';
import '../../domain/repositories/move_repositories.dart';

class MoveTasksState extends Equatable {
  const MoveTasksState({
    this.tasks = const [],
    this.status = RequestStatus.initial,
    this.errorMessage,
  });

  final List<MoveTask> tasks;
  final RequestStatus status;
  final String? errorMessage;

  int get doneCount => tasks.where((t) => t.done).length;
  double get progress => tasks.isEmpty ? 0 : doneCount / tasks.length;

  List<MoveTask> tasksIn(TaskPhase phase) =>
      tasks.where((t) => t.phase == phase).toList();

  MoveTasksState copyWith({
    List<MoveTask>? tasks,
    RequestStatus? status,
    String? errorMessage,
  }) => MoveTasksState(
    tasks: tasks ?? this.tasks,
    status: status ?? this.status,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [tasks, status, errorMessage];
}

/// The relocation checklist with optimistic create / update / delete.
class MoveTasksCubit extends Cubit<MoveTasksState> {
  MoveTasksCubit(this._repository) : super(const MoveTasksState());

  final MoveTaskRepository _repository;

  /// Clears the checklist when the user logs out.
  void reset() => emit(const MoveTasksState());

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final tasks = await _repository.fetchTasks();
      emit(state.copyWith(tasks: tasks, status: RequestStatus.success));
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          errorMessage: 'We couldn\'t load your tasks.',
        ),
      );
    }
  }

  Future<void> add(String title, TaskPhase phase) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    try {
      final task = await _repository.addTask(trimmed, phase);
      emit(state.copyWith(tasks: [...state.tasks, task]));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'We couldn\'t add that task.'));
    }
  }

  Future<void> toggle(String id) async {
    final index = state.tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final updated = state.tasks[index].copyWith(done: !state.tasks[index].done);
    final previous = state.tasks;
    emit(state.copyWith(tasks: List.of(previous)..[index] = updated));
    try {
      await _repository.updateTask(updated);
    } catch (_) {
      emit(
        state.copyWith(
          tasks: previous,
          errorMessage: 'We couldn\'t update that task.',
        ),
      );
    }
  }

  Future<void> rename(String id, String title) async {
    final index = state.tasks.indexWhere((t) => t.id == id);
    if (index == -1 || title.trim().isEmpty) return;
    final updated = state.tasks[index].copyWith(title: title.trim());
    final previous = state.tasks;
    emit(state.copyWith(tasks: List.of(previous)..[index] = updated));
    try {
      await _repository.updateTask(updated);
    } catch (_) {
      emit(
        state.copyWith(
          tasks: previous,
          errorMessage: 'We couldn\'t rename that task.',
        ),
      );
    }
  }

  Future<void> delete(String id) async {
    final previous = state.tasks;
    emit(state.copyWith(tasks: previous.where((t) => t.id != id).toList()));
    try {
      await _repository.deleteTask(id);
    } catch (_) {
      emit(
        state.copyWith(
          tasks: previous,
          errorMessage: 'We couldn\'t delete that task.',
        ),
      );
    }
  }

  /// Ticks the first open task whose title starts with [prefix], used to
  /// keep the checklist in sync with actions taken elsewhere in the app.
  Future<void> completeMatching(String prefix) async {
    for (final task in state.tasks) {
      if (!task.done &&
          task.title.toLowerCase().startsWith(prefix.toLowerCase())) {
        await toggle(task.id);
        return;
      }
    }
  }
}
