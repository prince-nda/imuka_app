import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/utils/request_status.dart';
import 'package:imuka/features/move/data/repositories/mock_move_repositories.dart';
import 'package:imuka/features/move/domain/entities/move_item.dart';
import 'package:imuka/features/move/domain/repositories/move_repositories.dart';
import 'package:imuka/features/move/presentation/cubit/move_plan_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _FailingItemRepository extends Mock implements MoveItemRepository {}

void main() {
  final today = DateTime(2026, 11, 3);
  MovePlanCubit build() => MovePlanCubit(
    MockMoveItemRepository(latency: Duration.zero),
    today: today,
  );

  test('defaults to Huye → Kigali two weeks from today', () {
    final cubit = build();
    expect(cubit.state.plan.routeLabel, 'Huye → Kigali');
    expect(cubit.state.plan.date, DateTime(2026, 11, 17));
  });

  blocTest<MovePlanCubit, MovePlanState>(
    'load reads the six Figma items and prices them at RWF 220,000',
    build: build,
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, RequestStatus.success);
      expect(cubit.state.items, hasLength(6));
      expect(cubit.state.estimate.total, 220000);
    },
  );

  blocTest<MovePlanCubit, MovePlanState>(
    'create, update and delete keep the estimate in sync',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.addItem('Bicycle'); // create: +8,000
      final bike = cubit.state.items.last;
      await cubit.increment(bike.id); // update: +8,000
      await cubit.removeItem(cubit.state.items.first.id); // delete sofa
    },
    verify: (cubit) {
      final bike = cubit.state.items.last;
      expect(bike.name, 'Bicycle');
      expect(bike.quantity, 2);
      expect(cubit.state.items.any((i) => i.name.startsWith('Sofa')), isFalse);
      expect(cubit.state.estimate.total, 220000 + 16000 - 25000);
    },
  );

  blocTest<MovePlanCubit, MovePlanState>(
    'adding an existing item increases its quantity instead of duplicating',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.addItem('tv');
    },
    verify: (cubit) {
      expect(cubit.state.items, hasLength(6));
      expect(cubit.state.items.last.quantity, 2);
    },
  );

  blocTest<MovePlanCubit, MovePlanState>(
    'quantity never drops below one',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.decrement(cubit.state.items.first.id);
    },
    verify: (cubit) => expect(cubit.state.items.first.quantity, 1),
  );

  group('when saving fails', () {
    late _FailingItemRepository repository;
    const sofa = MoveItem(
      id: 'sofa',
      name: 'Sofa',
      category: ItemCategory.furniture,
      unitPrice: 25000,
    );

    setUp(() {
      repository = _FailingItemRepository();
      registerFallbackValue(sofa);
      when(repository.fetchItems).thenAnswer((_) async => [sofa]);
      when(() => repository.updateItem(any())).thenThrow(Exception('offline'));
    });

    blocTest<MovePlanCubit, MovePlanState>(
      'rolls back the optimistic update and reports an error',
      build: () => MovePlanCubit(repository, today: today),
      act: (cubit) async {
        await cubit.load();
        await cubit.increment('sofa');
      },
      verify: (cubit) {
        expect(cubit.state.items.single.quantity, 1);
        expect(cubit.state.errorMessage, contains('Sofa'));
      },
    );
  });
}
