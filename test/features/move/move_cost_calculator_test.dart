import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/features/move/domain/entities/move_item.dart';
import 'package:imuka/features/move/domain/entities/mover.dart';
import 'package:imuka/features/move/domain/services/move_cost_calculator.dart';

MoveItem _item(String name, int quantity) {
  final (category, price) = ItemCatalog.lookup(name);
  return MoveItem(
    id: name,
    name: name,
    category: category,
    unitPrice: price,
    quantity: quantity,
  );
}

Mover _mover(String id, double rating, int adjustment) => Mover(
  id: id,
  name: id,
  rating: rating,
  completedMoves: 10,
  loaders: 2,
  vehicleType: VehicleType.smallTruck,
  vehicleLabel: '3 t truck',
  driverName: 'Driver',
  plateNumber: 'RAA 000 A',
  priceAdjustment: adjustment,
);

void main() {
  const calculator = MoveCostCalculator();

  final figmaItems = [
    _item('Sofa (3-seater)', 1),
    _item('Bed and mattress', 1),
    _item('Fridge', 1),
    _item('Wardrobe', 1),
    _item('Boxes (medium)', 12),
    _item('TV', 1),
  ];

  test('reproduces the RWF 220,000 estimate from the Figma prototype', () {
    final estimate = calculator.estimate(
      items: figmaItems,
      distanceKm: 130,
      vehicle: VehicleType.smallTruck,
    );

    expect(estimate.itemsTotal, 140000);
    expect(estimate.transportFee, 60000);
    expect(estimate.loadersFee, 20000);
    expect(estimate.total, 220000);
    expect(estimate.itemCount, 6);
    expect(estimate.itemLines.first.label, 'Sofa (3-seater) ×1');
  });

  test('an empty list costs nothing (no transport or loaders)', () {
    final estimate = calculator.estimate(
      items: const [],
      distanceKm: 130,
      vehicle: VehicleType.largeTruck,
    );
    expect(estimate.total, 0);
    expect(estimate.isEmpty, isTrue);
  });

  test('bigger vehicles and longer routes cost more', () {
    int total(VehicleType v, int km) => calculator
        .estimate(items: figmaItems, distanceKm: km, vehicle: v)
        .total;

    expect(
      total(VehicleType.pickup, 130),
      lessThan(total(VehicleType.smallTruck, 130)),
    );
    expect(
      total(VehicleType.largeTruck, 130),
      greaterThan(total(VehicleType.smallTruck, 130)),
    );
    expect(
      total(VehicleType.smallTruck, 50),
      lessThan(total(VehicleType.smallTruck, 130)),
    );
  });

  test('ItemCatalog matches keywords and falls back to Other', () {
    expect(ItemCatalog.lookup('Bed and mattress'), (
      ItemCategory.furniture,
      30000,
    ));
    expect(ItemCatalog.lookup('Boxes (medium)').$1, ItemCategory.boxes);
    expect(ItemCatalog.lookup('Guitar'), (ItemCategory.other, 8000));
  });

  test('best value balances rating against price (Figma: Gutwara)', () {
    final estimate = calculator.estimate(
      items: figmaItems,
      distanceKm: 130,
      vehicle: VehicleType.smallTruck,
    );
    final gutwara = _mover('Gutwara', 4.8, 0); // RWF 220,000
    final urugendo = _mover('Urugendo', 4.6, -15000); // RWF 205,000
    final inzu = _mover('Inzu', 4.9, 25000); // RWF 245,000

    expect(estimate.quoteFor(urugendo), 205000);
    expect(
      MoverRanking.bestValue([urugendo, gutwara, inzu], estimate),
      gutwara,
    );
    expect(MoverRanking.bestValue([], estimate), isNull);
  });
}
