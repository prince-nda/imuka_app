import 'package:equatable/equatable.dart';

enum TaskPhase {
  beforeMove('Before the move'),
  movingDay('Moving day'),
  afterMove('After the move');

  const TaskPhase(this.label);
  final String label;
}

/// A checklist entry on the "Move tasks" screen.
class MoveTask extends Equatable {
  const MoveTask({
    required this.id,
    required this.title,
    required this.phase,
    this.done = false,
  });

  final String id;
  final String title;
  final TaskPhase phase;
  final bool done;

  MoveTask copyWith({bool? done, String? title}) => MoveTask(
    id: id,
    title: title ?? this.title,
    phase: phase,
    done: done ?? this.done,
  );

  @override
  List<Object?> get props => [id, title, phase, done];
}

/// Starter checklist given to every new move.
const defaultMoveChecklist = <(String, TaskPhase)>[
  ('Shortlist verified homes', TaskPhase.beforeMove),
  ('Request a viewing', TaskPhase.beforeMove),
  ('Sign lease and keep the deposit receipt', TaskPhase.beforeMove),
  ('Book movers', TaskPhase.beforeMove),
  ('Check every item before paying', TaskPhase.movingDay),
  ('Buy Cash Power tokens for the new meter', TaskPhase.afterMove),
  ('Register with the new Umudugudu leader', TaskPhase.afterMove),
];
