import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imuka/core/utils/request_status.dart';
import 'package:imuka/features/shortlist/data/repositories/mock_shortlist_repository.dart';
import 'package:imuka/features/shortlist/presentation/cubit/shortlist_cubit.dart';

void main() {
  ShortlistCubit build() =>
      ShortlistCubit(MockShortlistRepository(latency: Duration.zero));

  blocTest<ShortlistCubit, ShortlistState>(
    'loads the saved homes',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const ShortlistState(status: RequestStatus.loading),
      const ShortlistState(
        ids: ['kacyiru-modern', 'kimironko-family', 'nyamirambo-room'],
        status: RequestStatus.success,
      ),
    ],
  );

  blocTest<ShortlistCubit, ShortlistState>(
    'toggle saves then removes a home',
    build: build,
    seed: () => const ShortlistState(status: RequestStatus.success),
    act: (cubit) async {
      expect(await cubit.toggle('remera-studio'), isTrue);
      expect(await cubit.toggle('remera-studio'), isFalse);
    },
    expect: () => [
      const ShortlistState(
        ids: ['remera-studio'],
        status: RequestStatus.success,
      ),
      const ShortlistState(status: RequestStatus.success),
    ],
  );

  blocTest<ShortlistCubit, ShortlistState>(
    'refuses a fifth home with a helpful message',
    build: build,
    seed: () => const ShortlistState(ids: ['a', 'b', 'c', 'd']),
    act: (cubit) => cubit.toggle('e'),
    verify: (cubit) {
      expect(cubit.state.ids, hasLength(ShortlistCubit.maxCompare));
      expect(cubit.state.errorMessage, contains('up to 4'));
    },
  );
}
