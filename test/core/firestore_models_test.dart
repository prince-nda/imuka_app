import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/data/value_codec.dart';
import 'package:imuka/core/domain/geo_point.dart';
import 'package:imuka/core/domain/rwanda_cities.dart';
import 'package:imuka/features/move/data/models/move_models.dart';
import 'package:imuka/features/move/data/repositories/mock_move_repositories.dart';
import 'package:imuka/features/move/domain/entities/move_booking.dart';
import 'package:imuka/features/move/domain/entities/move_item.dart';
import 'package:imuka/features/move/domain/entities/move_plan.dart';
import 'package:imuka/features/move/domain/entities/move_task.dart';
import 'package:imuka/features/move/domain/entities/mover.dart';
import 'package:imuka/features/move/domain/entities/payment.dart';
import 'package:imuka/features/properties/data/models/property_model.dart';
import 'package:imuka/features/properties/data/repositories/mock_property_repository.dart';

/// Stores values as-is, so a round trip shows the field mapping is
/// symmetric (what the app writes is exactly what it reads back).
class _IdentityCodec implements ValueCodec {
  const _IdentityCodec();
  @override
  Object encodeDate(DateTime value) => value;
  @override
  DateTime decodeDate(Object? value) => value! as DateTime;
  @override
  Object encodeGeo(GeoPoint value) => value;
  @override
  GeoPoint decodeGeo(Object? value) => value! as GeoPoint;
}

void main() {
  const codec = _IdentityCodec();

  test('every property survives a round trip, joined to its landlord', () {
    for (final p in MockPropertyRepository.catalogue) {
      final map = PropertyModel.toMap(p, codec);
      expect(map['landlordId'], p.owner.id, reason: 'stores only the FK');
      expect(map.containsKey('owner'), isFalse, reason: 'no duplicated data');

      final owner = PropertyModel.landlordFromMap(
        p.owner.id,
        PropertyModel.landlordToMap(p.owner),
      );
      final back = PropertyModel.fromMap(p.id, map, owner, codec);
      expect(back.title, p.title);
      expect(back.type, p.type);
      expect(back.monthlyRent, p.monthlyRent);
      expect(back.facilities, p.facilities);
      expect(back.location, p.location);
      expect(back.checks, p.checks);
      expect(back.owner, p.owner);
    }
  });

  test('movers, items and tasks round-trip', () {
    for (final m in MockMoverRepository.catalogue) {
      expect(MoverModel.fromMap(m.id, MoverModel.toMap(m)), m);
    }
    const item = MoveItem(
      id: 'i1',
      name: 'Fridge',
      category: ItemCategory.appliance,
      unitPrice: 20000,
      quantity: 2,
    );
    expect(MoveItemModel.fromMap('i1', MoveItemModel.toMap(item)), item);
    const task = MoveTask(
      id: 't1',
      title: 'Book movers',
      phase: TaskPhase.beforeMove,
      done: true,
    );
    expect(MoveTaskModel.fromMap('t1', MoveTaskModel.toMap(task)), task);
  });

  test('the move document stores plan, booking and payment', () {
    final plan = MovePlan(
      from: RwandaCity.huye,
      to: RwandaCity.kigali,
      date: DateTime(2026, 11, 17),
    );
    final mover = MockMoverRepository.catalogue.first;
    final receipt = PaymentReceipt.forMover(
      reference: 'IMK-4821',
      amount: 220000,
      method: PaymentMethod.airtelMoney,
      mover: mover,
      plan: plan,
      paidAt: DateTime(2026, 11, 17, 15),
    );
    final doc = {
      ...MoveModel.planToMap(plan, VehicleType.smallTruck, codec),
      'moverId': mover.id,
      'quote': 220000,
      'rating': 4,
      ...MoveModel.paymentToMap(receipt, codec),
    };

    final saved = MoveModel.planFromMap(doc, codec)!;
    expect(saved.plan, plan);
    expect(saved.vehicle, VehicleType.smallTruck);

    final booking = MoveModel.bookingFromMap(doc, mover, codec)!;
    expect(booking.stage, MoveStage.completed);
    expect(booking.quote, 220000);
    expect(booking.rating, 4);
    expect(booking.receipt, receipt);
  });

  test('unknown or missing values fall back safely', () {
    final mover = MoverModel.fromMap('x', {'vehicleType': 'helicopter'});
    expect(mover.vehicleType, VehicleType.smallTruck);
    expect(MoveModel.planFromMap(const {}, codec), isNull);
    expect(MoveModel.bookingFromMap(const {}, null, codec), isNull);
  });
}
