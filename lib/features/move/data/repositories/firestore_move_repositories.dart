import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/data/firestore_codec.dart';
import '../../../../core/data/firestore_paths.dart';
import '../../../../core/data/uid_provider.dart';
import '../../domain/entities/move_booking.dart';
import '../../domain/entities/move_item.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/move_task.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/tracking_update.dart';
import '../../domain/repositories/move_repositories.dart';
import '../../domain/services/tracking_simulator.dart';
import '../models/move_models.dart';

/// Shared access to the signed-in user's move document `moves/{uid}`.
abstract class _MoveDocument {
  _MoveDocument(this._uid, {FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final UidProvider _uid;
  final FirebaseFirestore _db;
  static const codec = FirestoreCodec();

  DocumentReference<Map<String, dynamic>> get moveDoc =>
      _db.doc(FirestorePaths.move(_uid()));

  /// Merges [data] into the move document, creating it if needed.
  Future<void> mergeMove(Map<String, Object?> data) => moveDoc.set({
    ...data,
    'userId': _uid(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

/// `moves/{uid}` — route, date and vehicle.
class FirestoreMovePlanRepository extends _MoveDocument
    implements MovePlanRepository {
  FirestoreMovePlanRepository(super.uid, {super.firestore});

  @override
  Future<({MovePlan plan, VehicleType vehicle})?> fetchPlan() async {
    final data = (await moveDoc.get()).data();
    return data == null
        ? null
        : MoveModel.planFromMap(data, _MoveDocument.codec);
  }

  @override
  Future<void> savePlan(MovePlan plan, VehicleType vehicle) =>
      mergeMove(MoveModel.planToMap(plan, vehicle, _MoveDocument.codec));
}

/// `moves/{uid}/items/{itemId}` — full CRUD on the items being moved.
class FirestoreMoveItemRepository extends _MoveDocument
    implements MoveItemRepository {
  FirestoreMoveItemRepository(super.uid, {super.firestore});

  CollectionReference<Map<String, dynamic>> get _items =>
      moveDoc.collection(FirestorePaths.items);

  @override
  Future<List<MoveItem>> fetchItems() async {
    final snapshot = await _items.orderBy('createdAt').get();
    return [
      for (final doc in snapshot.docs)
        MoveItemModel.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<MoveItem> addItem(String name, {int quantity = 1}) async {
    final (category, price) = ItemCatalog.lookup(name);
    final doc = _items.doc();
    final item = MoveItem(
      id: doc.id,
      name: name.trim(),
      category: category,
      unitPrice: price,
      quantity: quantity,
    );
    await doc.set({
      ...MoveItemModel.toMap(item),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return item;
  }

  @override
  Future<void> updateItem(MoveItem item) =>
      _items.doc(item.id).update({'quantity': item.quantity});

  @override
  Future<void> deleteItem(String id) => _items.doc(id).delete();

  /// Deletes every item in one atomic batch.
  @override
  Future<void> clearItems() async {
    final snapshot = await _items.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

/// `moves/{uid}/tasks/{taskId}` — full CRUD on the checklist.
class FirestoreMoveTaskRepository extends _MoveDocument
    implements MoveTaskRepository {
  FirestoreMoveTaskRepository(super.uid, {super.firestore});

  CollectionReference<Map<String, dynamic>> get _tasks =>
      moveDoc.collection(FirestorePaths.tasks);

  /// New users get the starter checklist once (tracked by `tasksSeeded`
  /// on the move document, so deleting every task doesn't bring it back).
  @override
  Future<List<MoveTask>> fetchTasks() async {
    final move = (await moveDoc.get()).data();
    if (move?['tasksSeeded'] != true) await _seedChecklist();
    final snapshot = await _tasks.orderBy('createdAt').get();
    return [
      for (final doc in snapshot.docs)
        MoveTaskModel.fromMap(doc.id, doc.data()),
    ];
  }

  Future<void> _seedChecklist() async {
    final batch = _db.batch();
    final start = DateTime.now();
    for (final (i, (title, phase)) in defaultMoveChecklist.indexed) {
      batch.set(_tasks.doc(), {
        ...MoveTaskModel.toMap(MoveTask(id: '', title: title, phase: phase)),
        // Distinct timestamps keep the starter order stable.
        'createdAt': Timestamp.fromDate(start.add(Duration(milliseconds: i))),
      });
    }
    batch.set(moveDoc, {
      'userId': _uid(),
      'tasksSeeded': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Future<MoveTask> addTask(String title, TaskPhase phase) async {
    final doc = _tasks.doc();
    final task = MoveTask(id: doc.id, title: title.trim(), phase: phase);
    await doc.set({
      ...MoveTaskModel.toMap(task),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return task;
  }

  @override
  Future<void> updateTask(MoveTask task) =>
      _tasks.doc(task.id).update({'title': task.title, 'done': task.done});

  @override
  Future<void> deleteTask(String id) => _tasks.doc(id).delete();
}

/// Reads `movers` and stores the booking, payment and rating on
/// `moves/{uid}` (with `moverId` as foreign key).
class FirestoreMoverRepository extends _MoveDocument
    implements MoverRepository {
  FirestoreMoverRepository(super.uid, {super.firestore});

  final _random = math.Random();

  CollectionReference<Map<String, dynamic>> get _movers =>
      _db.collection(FirestorePaths.movers);

  @override
  Future<List<Mover>> fetchMovers(VehicleType vehicle) async {
    final snapshot = await _movers
        .where('vehicleType', isEqualTo: vehicle.name)
        .get();
    return [
      for (final doc in snapshot.docs) MoverModel.fromMap(doc.id, doc.data()),
    ];
  }

  @override
  Future<MoveBooking?> fetchBooking() async {
    final data = (await moveDoc.get()).data();
    if (data == null) return null;
    final moverId = data['moverId'] as String?;
    Mover? mover;
    if (moverId != null) {
      final doc = await _movers.doc(moverId).get();
      if (doc.data() != null) mover = MoverModel.fromMap(doc.id, doc.data()!);
    }
    return MoveModel.bookingFromMap(data, mover, _MoveDocument.codec);
  }

  @override
  Future<void> bookMover({required Mover mover, required int quote}) =>
      mergeMove({
        'stage': MoveStage.moversBooked.name,
        'moverId': mover.id,
        'quote': quote,
        'rating': 0,
        // A new booking clears any previous payment.
        'receiptRef': FieldValue.delete(),
        'amountPaid': FieldValue.delete(),
        'paymentMethod': FieldValue.delete(),
        'paidAt': FieldValue.delete(),
      });

  @override
  Future<void> updateStage(MoveStage stage) => mergeMove({'stage': stage.name});

  /// GPS sharing by movers is future work; the truck is simulated.
  @override
  Stream<TrackingUpdate> trackMove({
    required Mover mover,
    required MovePlan plan,
  }) => simulateTracking(plan);

  /// Records the payment. A real payment provider (MoMo / card API) would
  /// confirm it server-side; see "Known limitations" in the README.
  @override
  Future<PaymentReceipt> pay({
    required Mover mover,
    required MovePlan plan,
    required int amount,
    required PaymentMethod method,
  }) async {
    final receipt = PaymentReceipt.forMover(
      reference: 'IMK-${1000 + _random.nextInt(9000)}',
      amount: amount,
      method: method,
      mover: mover,
      plan: plan,
      paidAt: DateTime.now(),
    );
    await mergeMove(MoveModel.paymentToMap(receipt, _MoveDocument.codec));
    return receipt;
  }

  @override
  Future<void> rateMover(String moverId, int stars) =>
      mergeMove({'rating': stars});
}
