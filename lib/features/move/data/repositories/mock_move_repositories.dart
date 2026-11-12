import 'dart:math' as math;

import '../../domain/entities/move_booking.dart';

import '../../domain/entities/move_item.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/move_task.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/tracking_update.dart';
import '../../domain/repositories/move_repositories.dart';
import '../../domain/services/tracking_simulator.dart';

/// In-memory plan (route, date and vehicle).
class MockMovePlanRepository implements MovePlanRepository {
  ({MovePlan plan, VehicleType vehicle})? _saved;

  @override
  Future<({MovePlan plan, VehicleType vehicle})?> fetchPlan() async => _saved;

  @override
  Future<void> savePlan(MovePlan plan, VehicleType vehicle) async =>
      _saved = (plan: plan, vehicle: vehicle);
}

/// In-memory item list seeded with the six items from the Figma file.
class MockMoveItemRepository implements MoveItemRepository {
  MockMoveItemRepository({this.latency = const Duration(milliseconds: 300)}) {
    for (final (name, qty) in const [
      ('Sofa (3-seater)', 1),
      ('Bed and mattress', 1),
      ('Fridge', 1),
      ('Wardrobe', 1),
      ('Boxes (medium)', 12),
      ('TV', 1),
    ]) {
      _items.add(_create(name, qty));
    }
  }

  final Duration latency;
  final List<MoveItem> _items = [];
  int _nextId = 1;

  MoveItem _create(String name, int quantity) {
    final (category, price) = ItemCatalog.lookup(name);
    return MoveItem(
      id: 'item-${_nextId++}',
      name: name,
      category: category,
      unitPrice: price,
      quantity: quantity,
    );
  }

  @override
  Future<List<MoveItem>> fetchItems() async {
    await Future<void>.delayed(latency);
    return List.of(_items);
  }

  @override
  Future<MoveItem> addItem(String name, {int quantity = 1}) async {
    await Future<void>.delayed(latency);
    final item = _create(name.trim(), quantity);
    _items.add(item);
    return item;
  }

  @override
  Future<void> updateItem(MoveItem item) async {
    await Future<void>.delayed(latency ~/ 3);
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i != -1) _items[i] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    await Future<void>.delayed(latency ~/ 3);
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clearItems() async {
    await Future<void>.delayed(latency);
    _items.clear();
  }
}

class MockMoveTaskRepository implements MoveTaskRepository {
  MockMoveTaskRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  int _nextId = 100;

  final List<MoveTask> _tasks = [
    const MoveTask(
      id: 'task-1',
      title: 'Shortlist verified homes',
      phase: TaskPhase.beforeMove,
      done: true,
    ),
    const MoveTask(
      id: 'task-2',
      title: 'Request a viewing',
      phase: TaskPhase.beforeMove,
      done: true,
    ),
    const MoveTask(
      id: 'task-3',
      title: 'Sign lease and keep the deposit receipt',
      phase: TaskPhase.beforeMove,
    ),
    const MoveTask(
      id: 'task-4',
      title: 'Book movers',
      phase: TaskPhase.beforeMove,
    ),
    const MoveTask(
      id: 'task-5',
      title: 'Check every item before paying',
      phase: TaskPhase.movingDay,
    ),
    const MoveTask(
      id: 'task-6',
      title: 'Buy Cash Power tokens for the new meter',
      phase: TaskPhase.afterMove,
    ),
    const MoveTask(
      id: 'task-7',
      title: 'Register with the new Umudugudu leader',
      phase: TaskPhase.afterMove,
    ),
  ];

  @override
  Future<List<MoveTask>> fetchTasks() async {
    await Future<void>.delayed(latency);
    return List.of(_tasks);
  }

  @override
  Future<MoveTask> addTask(String title, TaskPhase phase) async {
    await Future<void>.delayed(latency);
    final task = MoveTask(id: 'task-${_nextId++}', title: title, phase: phase);
    _tasks.add(task);
    return task;
  }

  @override
  Future<void> updateTask(MoveTask task) async {
    await Future<void>.delayed(latency ~/ 3);
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i != -1) _tasks[i] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future<void>.delayed(latency ~/ 3);
    _tasks.removeWhere((t) => t.id == id);
  }
}

class MockMoverRepository implements MoverRepository {
  MockMoverRepository({
    this.latency = const Duration(milliseconds: 500),
    this.trackingTick = const Duration(seconds: 1),
  });

  final Duration latency;

  /// How often the simulated truck reports its position.
  final Duration trackingTick;
  final _random = math.Random();

  /// Verified movers; also used to seed Firestore (`tool/seed_firestore`).
  static const catalogue = [
    Mover(
      id: 'gutwara',
      name: 'Gutwara Movers',
      rating: 4.8,
      completedMoves: 112,
      loaders: 2,
      vehicleType: VehicleType.smallTruck,
      vehicleLabel: '3 t truck',
      insured: true,
      driverName: 'Eric Mugisha',
      plateNumber: 'RAB 421 C',
    ),
    Mover(
      id: 'urugendo',
      name: 'Urugendo Express',
      rating: 4.6,
      completedMoves: 87,
      loaders: 2,
      vehicleType: VehicleType.smallTruck,
      vehicleLabel: '3 t truck',
      priceAdjustment: -15000,
      driverName: 'Claudine Ingabire',
      plateNumber: 'RAD 118 B',
    ),
    Mover(
      id: 'inzu',
      name: 'Inzu Movers',
      rating: 4.9,
      completedMoves: 203,
      loaders: 3,
      vehicleType: VehicleType.smallTruck,
      vehicleLabel: '3.5 t truck',
      packingIncluded: true,
      priceAdjustment: 25000,
      driverName: 'Samuel Nkurunziza',
      plateNumber: 'RAC 907 A',
    ),
    Mover(
      id: 'moto-cargo',
      name: 'Imbaraga Pickups',
      rating: 4.5,
      completedMoves: 64,
      loaders: 1,
      vehicleType: VehicleType.pickup,
      vehicleLabel: '1 t pickup',
      priceAdjustment: -5000,
      driverName: 'Olivier Habineza',
      plateNumber: 'RAE 220 D',
    ),
    Mover(
      id: 'gutwara-pickup',
      name: 'Gutwara Movers',
      rating: 4.8,
      completedMoves: 41,
      loaders: 2,
      vehicleType: VehicleType.pickup,
      vehicleLabel: '1.5 t pickup',
      insured: true,
      driverName: 'Eric Mugisha',
      plateNumber: 'RAB 655 C',
    ),
    Mover(
      id: 'twimuke',
      name: 'Twimuke Logistics',
      rating: 4.7,
      completedMoves: 150,
      loaders: 4,
      vehicleType: VehicleType.largeTruck,
      vehicleLabel: '7 t truck',
      insured: true,
      driverName: 'Jean Bosco Twagira',
      plateNumber: 'RAF 301 A',
    ),
    Mover(
      id: 'inzu-large',
      name: 'Inzu Movers',
      rating: 4.9,
      completedMoves: 96,
      loaders: 4,
      vehicleType: VehicleType.largeTruck,
      vehicleLabel: '8 t truck',
      packingIncluded: true,
      priceAdjustment: 30000,
      driverName: 'Samuel Nkurunziza',
      plateNumber: 'RAC 112 E',
    ),
  ];

  @override
  Future<List<Mover>> fetchMovers(VehicleType vehicle) async {
    await Future<void>.delayed(latency);
    return catalogue.where((m) => m.vehicleType == vehicle).toList();
  }

  MoveBooking? _booking;

  @override
  Future<MoveBooking?> fetchBooking() async => _booking;

  @override
  Future<void> bookMover({required Mover mover, required int quote}) async {
    _booking = MoveBooking(
      stage: MoveStage.moversBooked,
      mover: mover,
      quote: quote,
    );
  }

  @override
  Future<void> updateStage(MoveStage stage) async {
    final b = _booking;
    _booking = MoveBooking(
      stage: stage,
      mover: b?.mover,
      quote: b?.quote,
      receipt: b?.receipt,
      rating: b?.rating ?? 0,
    );
  }

  @override
  Stream<TrackingUpdate> trackMove({
    required Mover mover,
    required MovePlan plan,
  }) => simulateTracking(plan, tick: trackingTick);

  @override
  Future<PaymentReceipt> pay({
    required Mover mover,
    required MovePlan plan,
    required int amount,
    required PaymentMethod method,
  }) async {
    await Future<void>.delayed(latency * 3);
    final receipt = PaymentReceipt.forMover(
      reference: 'IMK-${1000 + _random.nextInt(9000)}',
      amount: amount,
      method: method,
      mover: mover,
      plan: plan,
      paidAt: DateTime.now(),
    );
    _booking = MoveBooking(
      stage: MoveStage.completed,
      mover: mover,
      quote: amount,
      receipt: receipt,
    );
    return receipt;
  }

  @override
  Future<void> rateMover(String moverId, int stars) async {
    await Future<void>.delayed(latency ~/ 2);
    final b = _booking;
    if (b == null) return;
    _booking = MoveBooking(
      stage: b.stage,
      mover: b.mover,
      quote: b.quote,
      receipt: b.receipt,
      rating: stars,
    );
  }
}
