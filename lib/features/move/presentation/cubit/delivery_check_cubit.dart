import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/move_item.dart';

class DeliveryCheckState extends Equatable {
  const DeliveryCheckState({
    required this.items,
    this.received = const {},
    this.issues = const {},
  });

  final List<MoveItem> items;

  /// Ids of items the user ticked as arrived.
  final Set<String> received;

  /// Reported problems keyed by item id.
  final Map<String, String> issues;

  int get receivedCount => received.length;
  double get progress => items.isEmpty ? 0 : receivedCount / items.length;

  /// Payment unlocks only when everything arrived and no issue is open.
  bool get canPay =>
      items.isNotEmpty && receivedCount == items.length && issues.isEmpty;

  bool isReceived(String id) => received.contains(id);

  @override
  List<Object?> get props => [items, received, issues];
}

/// The moving-day check: tick each item as it arrives before paying.
class DeliveryCheckCubit extends Cubit<DeliveryCheckState> {
  DeliveryCheckCubit(List<MoveItem> items)
    : super(DeliveryCheckState(items: items));

  void toggle(String itemId) {
    final received = Set.of(state.received);
    if (!received.remove(itemId)) received.add(itemId);
    emit(
      DeliveryCheckState(
        items: state.items,
        received: received,
        issues: state.issues,
      ),
    );
  }

  /// Flags an item as missing or damaged. It is un-ticked so the payment
  /// stays on hold until the issue is resolved.
  void reportIssue(String itemId, String description) {
    emit(
      DeliveryCheckState(
        items: state.items,
        received: Set.of(state.received)..remove(itemId),
        issues: {...state.issues, itemId: description.trim()},
      ),
    );
  }

  void resolveIssue(String itemId) {
    emit(
      DeliveryCheckState(
        items: state.items,
        received: state.received,
        issues: Map.of(state.issues)..remove(itemId),
      ),
    );
  }
}
