import '../entities/move_booking.dart';
import '../entities/move_item.dart';
import '../entities/move_plan.dart';
import '../entities/move_task.dart';
import '../entities/mover.dart';
import '../entities/payment.dart';
import '../entities/tracking_update.dart';

/// Route, date and vehicle of the user's move.
abstract interface class MovePlanRepository {
  /// `null` when the user hasn't saved a plan yet.
  Future<({MovePlan plan, VehicleType vehicle})?> fetchPlan();

  Future<void> savePlan(MovePlan plan, VehicleType vehicle);
}

/// The user's inventory of things to move (full CRUD).
abstract interface class MoveItemRepository {
  Future<List<MoveItem>> fetchItems();

  /// Creates an item; category and price come from the catalog.
  Future<MoveItem> addItem(String name, {int quantity = 1});

  Future<void> updateItem(MoveItem item);

  Future<void> deleteItem(String id);

  Future<void> clearItems();
}

/// The relocation checklist (full CRUD).
abstract interface class MoveTaskRepository {
  Future<List<MoveTask>> fetchTasks();

  Future<MoveTask> addTask(String title, TaskPhase phase);

  Future<void> updateTask(MoveTask task);

  Future<void> deleteTask(String id);
}

/// Verified movers, booking, live tracking, payment and rating.
abstract interface class MoverRepository {
  Future<List<Mover>> fetchMovers(VehicleType vehicle);

  /// The saved booking, or `null` if nothing was booked yet.
  Future<MoveBooking?> fetchBooking();

  /// Saves the booked mover and locked-in quote.
  Future<void> bookMover({required Mover mover, required int quote});

  Future<void> updateStage(MoveStage stage);

  /// Position feed for the booked mover's truck.
  Stream<TrackingUpdate> trackMove({
    required Mover mover,
    required MovePlan plan,
  });

  /// Payment is only released to the mover after the user confirmed
  /// delivery.
  Future<PaymentReceipt> pay({
    required Mover mover,
    required MovePlan plan,
    required int amount,
    required PaymentMethod method,
  });

  Future<void> rateMover(String moverId, int stars);
}
