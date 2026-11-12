import '../../../../core/data/value_codec.dart';
import '../../../../core/domain/rwanda_cities.dart';
import '../../domain/entities/move_booking.dart';
import '../../domain/entities/move_item.dart';
import '../../domain/entities/move_plan.dart';
import '../../domain/entities/move_task.dart';
import '../../domain/entities/mover.dart';
import '../../domain/entities/payment.dart';

/// Firestore mapping for `movers/{moverId}`.
abstract final class MoverModel {
  static Map<String, Object?> toMap(Mover m) => {
    'name': m.name,
    'rating': m.rating,
    'completedMoves': m.completedMoves,
    'loaders': m.loaders,
    'vehicleType': m.vehicleType.name,
    'vehicleLabel': m.vehicleLabel,
    'driverName': m.driverName,
    'plateNumber': m.plateNumber,
    'priceAdjustment': m.priceAdjustment,
    'insured': m.insured,
    'packingIncluded': m.packingIncluded,
    'verified': m.verified,
  };

  static Mover fromMap(String id, Map<String, Object?> m) => Mover(
    id: id,
    name: m['name'] as String? ?? '',
    rating: readDouble(m['rating']),
    completedMoves: readInt(m['completedMoves']),
    loaders: readInt(m['loaders'], 2),
    vehicleType: enumByName(
      VehicleType.values,
      m['vehicleType'],
      VehicleType.smallTruck,
    ),
    vehicleLabel: m['vehicleLabel'] as String? ?? '',
    driverName: m['driverName'] as String? ?? '',
    plateNumber: m['plateNumber'] as String? ?? '',
    priceAdjustment: readInt(m['priceAdjustment']),
    insured: m['insured'] as bool? ?? false,
    packingIncluded: m['packingIncluded'] as bool? ?? false,
    verified: m['verified'] as bool? ?? false,
  );
}

/// Firestore mapping for `moves/{uid}/items/{itemId}`.
abstract final class MoveItemModel {
  static Map<String, Object?> toMap(MoveItem i) => {
    'name': i.name,
    'category': i.category.name,
    'unitPrice': i.unitPrice,
    'quantity': i.quantity,
  };

  static MoveItem fromMap(String id, Map<String, Object?> m) => MoveItem(
    id: id,
    name: m['name'] as String? ?? '',
    category: enumByName(
      ItemCategory.values,
      m['category'],
      ItemCategory.other,
    ),
    unitPrice: readInt(m['unitPrice']),
    quantity: readInt(m['quantity'], 1),
  );
}

/// Firestore mapping for `moves/{uid}/tasks/{taskId}`.
abstract final class MoveTaskModel {
  static Map<String, Object?> toMap(MoveTask t) => {
    'title': t.title,
    'phase': t.phase.name,
    'done': t.done,
  };

  static MoveTask fromMap(String id, Map<String, Object?> m) => MoveTask(
    id: id,
    title: m['title'] as String? ?? '',
    phase: enumByName(TaskPhase.values, m['phase'], TaskPhase.beforeMove),
    done: m['done'] as bool? ?? false,
  );
}

/// Firestore mapping for the move document `moves/{uid}`, which holds the
/// plan, the booking (with `moverId` as foreign key) and the payment.
abstract final class MoveModel {
  static Map<String, Object?> planToMap(
    MovePlan plan,
    VehicleType vehicle,
    ValueCodec codec,
  ) => {
    'fromCity': plan.from.name,
    'toCity': plan.to.name,
    'moveDate': codec.encodeDate(plan.date),
    'vehicleType': vehicle.name,
  };

  static ({MovePlan plan, VehicleType vehicle})? planFromMap(
    Map<String, Object?> m,
    ValueCodec codec,
  ) {
    if (m['fromCity'] == null || m['moveDate'] == null) return null;
    return (
      plan: MovePlan(
        from: enumByName(RwandaCity.values, m['fromCity'], RwandaCity.huye),
        to: enumByName(RwandaCity.values, m['toCity'], RwandaCity.kigali),
        date: codec.decodeDate(m['moveDate']),
      ),
      vehicle: enumByName(
        VehicleType.values,
        m['vehicleType'],
        VehicleType.smallTruck,
      ),
    );
  }

  static Map<String, Object?> paymentToMap(
    PaymentReceipt r,
    ValueCodec codec,
  ) => {
    'stage': MoveStage.completed.name,
    'receiptRef': r.reference,
    'amountPaid': r.amount,
    'paymentMethod': r.method.name,
    'paidAt': codec.encodeDate(r.paidAt),
  };

  /// [mover] is the joined `movers/{moverId}` document, if any.
  static MoveBooking? bookingFromMap(
    Map<String, Object?> m,
    Mover? mover,
    ValueCodec codec,
  ) {
    if (m['stage'] == null) return null;
    final plan = planFromMap(m, codec)?.plan;
    final receiptRef = m['receiptRef'] as String?;
    return MoveBooking(
      stage: enumByName(MoveStage.values, m['stage'], MoveStage.planMove),
      mover: mover,
      quote: m['quote'] == null ? null : readInt(m['quote']),
      rating: readInt(m['rating']),
      receipt: receiptRef == null || mover == null || plan == null
          ? null
          : PaymentReceipt.forMover(
              reference: receiptRef,
              amount: readInt(m['amountPaid']),
              method: enumByName(
                PaymentMethod.values,
                m['paymentMethod'],
                PaymentMethod.mtnMomo,
              ),
              mover: mover,
              plan: plan,
              paidAt: codec.decodeDate(m['paidAt']),
            ),
    );
  }
}
