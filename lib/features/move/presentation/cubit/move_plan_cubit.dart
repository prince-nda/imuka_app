import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/rwanda_cities.dart';
import '../../../../core/utils/request_status.dart';
import '../../domain/entities/cost_estimate.dart';
import '../../domain/entities/move_item.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/mover.dart';
import '../../domain/repositories/move_repositories.dart';
import '../../domain/services/move_cost_calculator.dart';

class MovePlanState extends Equatable {
  const MovePlanState({
    required this.plan,
    this.vehicle = VehicleType.smallTruck,
    this.items = const [],
    this.status = RequestStatus.initial,
    this.errorMessage,
  });

  final MovePlan plan;
  final VehicleType vehicle;
  final List<MoveItem> items;
  final RequestStatus status;

  /// Set when a create / update / delete failed, for a snackbar.
  final String? errorMessage;

  static const _calculator = MoveCostCalculator();

  /// Recomputed from the current items, route and vehicle, so every screen
  /// that shows a price always agrees.
  CostEstimate get estimate => _calculator.estimate(
    items: items,
    distanceKm: plan.distanceKm,
    vehicle: vehicle,
  );

  MovePlanState copyWith({
    MovePlan? plan,
    VehicleType? vehicle,
    List<MoveItem>? items,
    RequestStatus? status,
    String? errorMessage,
  }) => MovePlanState(
    plan: plan ?? this.plan,
    vehicle: vehicle ?? this.vehicle,
    items: items ?? this.items,
    status: status ?? this.status,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [plan, vehicle, items, status, errorMessage];
}

/// The route, date, vehicle and item inventory of the user's move.
///
/// Item changes are applied to the UI immediately (optimistic update) and
/// rolled back with an error message if saving fails.
class MovePlanCubit extends Cubit<MovePlanState> {
  MovePlanCubit(
    this._repository, {
    MovePlanRepository? planRepository,
    DateTime? today,
  }) : _planRepository = planRepository, // ignore: prefer_initializing_formals
       _today = today,
       super(
         MovePlanState(
           plan: MovePlan(
             from: RwandaCity.huye,
             to: RwandaCity.kigali,
             date: _defaultMoveDate(today ?? DateTime.now()),
           ),
         ),
       );

  final MoveItemRepository _repository;

  /// Persists route, date and vehicle (optional so tests can omit it).
  final MovePlanRepository? _planRepository;
  final DateTime? _today;

  /// Two weeks from today gives time to sign a lease and book movers.
  static DateTime _defaultMoveDate(DateTime today) =>
      DateTime(today.year, today.month, today.day + 14);

  /// Loads the saved plan and items for the signed-in user.
  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final (saved, items) = await (
        _planRepository?.fetchPlan() ?? Future.value(),
        _repository.fetchItems(),
      ).wait;
      emit(
        state.copyWith(
          plan: saved?.plan,
          vehicle: saved?.vehicle,
          items: items,
          status: RequestStatus.success,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          errorMessage: 'We couldn\'t load your move. Check your connection.',
        ),
      );
    }
  }

  /// Clears everything when the user logs out.
  void reset() => emit(
    MovePlanState(
      plan: MovePlan(
        from: RwandaCity.huye,
        to: RwandaCity.kigali,
        date: _defaultMoveDate(_today ?? DateTime.now()),
      ),
    ),
  );

  Future<void> _savePlan() async {
    try {
      await _planRepository?.savePlan(state.plan, state.vehicle);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'We couldn\'t save your move plan.'));
    }
  }

  Future<void> setRoute(RwandaCity from, RwandaCity to) {
    emit(
      state.copyWith(
        plan: state.plan.copyWith(from: from, to: to),
      ),
    );
    return _savePlan();
  }

  Future<void> setDate(DateTime date) {
    emit(state.copyWith(plan: state.plan.copyWith(date: date)));
    return _savePlan();
  }

  Future<void> setVehicle(VehicleType vehicle) {
    emit(state.copyWith(vehicle: vehicle));
    return _savePlan();
  }

  /// Adding an item that is already listed increases its quantity instead.
  Future<void> addItem(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    for (final item in state.items) {
      if (item.name.toLowerCase() == trimmed.toLowerCase()) {
        return increment(item.id);
      }
    }
    try {
      final created = await _repository.addItem(trimmed);
      emit(state.copyWith(items: [...state.items, created]));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'We couldn\'t add "$trimmed".'));
    }
  }

  Future<void> increment(String id) => _changeQuantity(id, 1);

  /// Quantity never drops below 1; use [removeItem] to delete.
  Future<void> decrement(String id) => _changeQuantity(id, -1);

  Future<void> _changeQuantity(String id, int delta) async {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = state.items[index];
    final quantity = item.quantity + delta;
    if (quantity < 1 || quantity > 99) return;
    final updated = item.copyWith(quantity: quantity);
    final previous = state.items;
    emit(state.copyWith(items: List.of(previous)..[index] = updated));
    try {
      await _repository.updateItem(updated);
    } catch (_) {
      emit(
        state.copyWith(
          items: previous,
          errorMessage: 'We couldn\'t update ${item.name}.',
        ),
      );
    }
  }

  Future<void> removeItem(String id) async {
    final previous = state.items;
    emit(state.copyWith(items: previous.where((i) => i.id != id).toList()));
    try {
      await _repository.deleteItem(id);
    } catch (_) {
      emit(
        state.copyWith(
          items: previous,
          errorMessage: 'We couldn\'t remove that item.',
        ),
      );
    }
  }

  /// Re-creates an item removed by mistake ("Undo").
  Future<void> restoreItem(MoveItem item) async {
    try {
      final created = await _repository.addItem(
        item.name,
        quantity: item.quantity,
      );
      emit(state.copyWith(items: [...state.items, created]));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'We couldn\'t restore ${item.name}.'));
    }
  }

  Future<void> clearAll() async {
    final previous = state.items;
    emit(state.copyWith(items: const []));
    try {
      await _repository.clearItems();
    } catch (_) {
      emit(
        state.copyWith(
          items: previous,
          errorMessage: 'We couldn\'t clear your items.',
        ),
      );
    }
  }
}
